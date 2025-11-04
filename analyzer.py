#!/usr/bin/env python3
"""
Website analyzer - Fetches a website and extracts content to provide an intelligent summary.
Uses Claude API to generate meaningful summaries of website purpose and content.
"""

import argparse
import base64
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional
from urllib.parse import urlparse

import requests
from anthropic import Anthropic
from bs4 import BeautifulSoup
from io import BytesIO
from jinja2 import Environment, FileSystemLoader, select_autoescape

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, PageTemplate, Frame
from reportlab.lib import colors

try:
    from playwright.async_api import async_playwright
    PLAYWRIGHT_AVAILABLE = True
except ImportError:
    PLAYWRIGHT_AVAILABLE = False


class WebsiteAnalyzer:
    """Analyzes websites to extract content and generate intelligent summaries."""

    def __init__(self, timeout: int = 10, api_key: Optional[str] = None):
        """
        Initialize the analyzer.

        Args:
            timeout: Request timeout in seconds
            api_key: Anthropic API key (defaults to ANTHROPIC_API_KEY env var)
        """
        self.timeout = timeout
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }

        # Get API key from parameter or environment
        self.api_key = api_key or os.getenv('ANTHROPIC_API_KEY')
        if not self.api_key:
            raise ValueError(
                "Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable "
                "or pass api_key parameter."
            )

        self.client = Anthropic(api_key=self.api_key)

        # Setup Jinja2 template environment
        templates_dir = Path(__file__).parent / 'templates'
        if templates_dir.exists():
            self.jinja_env = Environment(
                loader=FileSystemLoader(str(templates_dir)),
                autoescape=select_autoescape(['html', 'xml'])
            )
        else:
            self.jinja_env = None

    def analyze(self, url: str) -> Dict:
        """
        Analyze a website and generate an intelligent summary.

        Args:
            url: The website URL to analyze

        Returns:
            Dictionary containing title, meta_description, extracted_content, and summary
        """
        # Ensure URL has a scheme
        if not url.startswith(('http://', 'https://')):
            url = 'https://' + url

        try:
            response = requests.get(url, headers=self.headers, timeout=self.timeout)
            response.raise_for_status()
        except requests.RequestException as e:
            return {
                'url': url,
                'title': None,
                'meta_description': None,
                'extracted_content': None,
                'summary': f'Error fetching website: {str(e)}',
                'success': False
            }

        soup = BeautifulSoup(response.content, 'html.parser')

        # Extract metadata
        title = self._extract_title(soup)
        meta_description = self._extract_meta_description(soup)

        # Extract full page content
        content = self._extract_full_content(soup)

        # Generate intelligent summary using Claude
        summary = self._generate_summary_with_claude(title, meta_description, content)

        return {
            'url': url,
            'title': title,
            'meta_description': meta_description,
            'extracted_content': content[:500] if content else None,  # First 500 chars for reference
            'summary': summary,
            'success': True
        }

    def _extract_title(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract the page title."""
        # Try <title> tag first
        if soup.title and soup.title.string:
            return soup.title.string.strip()

        # Try og:title meta tag
        og_title = soup.find('meta', property='og:title')
        if og_title and og_title.get('content'):
            return og_title.get('content').strip()

        # Try H1 as fallback
        h1 = soup.find('h1')
        if h1 and h1.get_text():
            return h1.get_text().strip()

        return None

    def _extract_meta_description(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract the meta description."""
        # Try meta name="description"
        meta_desc = soup.find('meta', attrs={'name': 'description'})
        if meta_desc and meta_desc.get('content'):
            return meta_desc.get('content').strip()

        # Try og:description
        og_desc = soup.find('meta', property='og:description')
        if og_desc and og_desc.get('content'):
            return og_desc.get('content').strip()

        return None

    def _extract_full_content(self, soup: BeautifulSoup) -> str:
        """
        Extract meaningful content from the page.
        Removes scripts, styles, and navigation elements.
        """
        # Remove script and style elements
        for script in soup(["script", "style"]):
            script.decompose()

        # Remove common non-content elements
        for nav in soup(["nav", "footer", "aside"]):
            nav.decompose()

        # Get text from main content areas
        main_content = soup.find('main') or soup.find('article') or soup.find('div', class_=['content', 'main', 'body'])

        if main_content:
            text = main_content.get_text(separator=' ', strip=True)
        else:
            text = soup.get_text(separator=' ', strip=True)

        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)

        return text[:5000]  # Limit to 5000 chars for API

    def _generate_summary_with_claude(
        self,
        title: Optional[str],
        description: Optional[str],
        content: str
    ) -> str:
        """
        Generate an intelligent summary using Claude API.
        Takes the extracted content and produces a meaningful summary.
        """
        # Build context for Claude
        context_parts = []
        if title:
            context_parts.append(f"Page Title: {title}")
        if description:
            context_parts.append(f"Meta Description: {description}")
        if content:
            context_parts.append(f"Page Content:\n{content}")

        if not context_parts:
            return "Unable to extract content from website."

        context = "\n\n".join(context_parts)

        # Call Claude to generate summary
        try:
            message = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=500,
                messages=[
                    {
                        "role": "user",
                        "content": f"""Based on the following website content, provide a concise summary of what this website is about.
Focus on the main purpose, key features, and target audience. Keep it to 2-3 sentences.

{context}

Summary:"""
                    }
                ]
            )
            return message.content[0].text.strip()
        except Exception as e:
            return f"Error generating summary: {str(e)}"

    def generate_pdf(
        self,
        result: Dict,
        output_path: Optional[str] = None,
        logo_path: Optional[str] = None,
        company_name: Optional[str] = None,
        company_details: Optional[str] = None
    ) -> str:
        """
        Generate a formatted PDF from the analysis result with optional branding.

        Args:
            result: Dictionary returned from analyze()
            output_path: Optional custom output path. If not provided, generates from URL
            logo_path: Optional path to logo image file or URL
            company_name: Optional company name for header
            company_details: Optional company contact details for footer

        Returns:
            Path to the generated PDF file
        """
        # Generate filename from URL if not provided
        if not output_path:
            url = result['url']
            # Extract domain from URL
            domain = urlparse(url).netloc or 'website'
            # Clean up domain for filename
            domain = re.sub(r'[^a-z0-9-]', '-', domain.lower())
            domain = re.sub(r'-+', '-', domain).strip('-')
            output_path = f"{domain}-analysis.pdf"

        # Create PDF document
        doc = SimpleDocTemplate(
            output_path,
            pagesize=letter,
            rightMargin=0.75 * inch,
            leftMargin=0.75 * inch,
            topMargin=1.0 * inch,
            bottomMargin=0.75 * inch
        )

        # Create styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor='#1f1f1f',
            spaceAfter=6,
            alignment=0
        )
        company_style = ParagraphStyle(
            'CompanyName',
            parent=styles['Normal'],
            fontSize=14,
            textColor='#7c3aed',
            spaceAfter=12,
            alignment=0,
            fontName='Helvetica-Bold'
        )
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=12,
            textColor='#333333',
            spaceAfter=6,
            spaceBefore=10
        )
        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=11,
            leading=14,
            textColor='#444444'
        )
        footer_style = ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=9,
            textColor='#666666',
            alignment=0,
            leading=11
        )

        # Build PDF content
        story = []

        # Header with both logos - websler on left, jumoki on right
        header_data = []
        websler_logo = None
        jumoki_logo = None

        # Try to load websler logo - preserve proper aspect ratio (approx 2:1)
        try:
            websler_path = Path(__file__).parent / 'weblser_logo.png'
            if websler_path.exists():
                websler_logo = Image(str(websler_path), width=1.0 * inch, height=0.5 * inch, kind='proportional')
            elif logo_path:
                if logo_path.startswith(('http://', 'https://')):
                    response = requests.get(logo_path, timeout=self.timeout)
                    websler_logo = Image(BytesIO(response.content), width=1.0 * inch, height=0.5 * inch, kind='proportional')
                else:
                    websler_logo = Image(logo_path, width=1.0 * inch, height=0.5 * inch, kind='proportional')
        except Exception:
            websler_logo = None

        # Try to load jumoki logo - preserve proper aspect ratio (approx 2:1)
        try:
            jumoki_path = Path(__file__).parent / 'jumoki_coloured_transparent_bg.png'
            if jumoki_path.exists():
                jumoki_logo = Image(str(jumoki_path), width=1.1 * inch, height=0.5 * inch, kind='proportional')
        except Exception:
            jumoki_logo = None

        # Build header with both logos centered on the page with 15px spacing between them
        if websler_logo or jumoki_logo or company_name:
            header_data = [["", "", websler_logo or "", jumoki_logo or ""]]
            header_table = Table(
                header_data,
                colWidths=[1.8 * inch, 0.15 * inch, 1.5 * inch, 1.75 * inch]
            )
            header_table.setStyle(TableStyle([
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('ALIGN', (0, 0), (1, -1), 'LEFT'),
                ('ALIGN', (2, 0), (2, -1), 'CENTER'),
                ('ALIGN', (3, 0), (3, -1), 'CENTER'),
                ('LEFTPADDING', (0, 0), (-1, -1), 0),
                ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                ('TOPPADDING', (0, 0), (-1, -1), 0),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
            ]))
            story.append(header_table)
            story.append(Spacer(1, 0.3 * inch))

        # Divider line
        story.append(Paragraph('<hr/>', normal_style))
        story.append(Spacer(1, 0.15 * inch))

        # Title
        story.append(Paragraph("Website Analysis Report", title_style))
        story.append(Spacer(1, 0.2 * inch))

        # URL
        if result['url']:
            story.append(Paragraph("<b>URL:</b>", heading_style))
            story.append(Paragraph(result['url'], normal_style))
            story.append(Spacer(1, 0.15 * inch))

        # Title
        if result['title']:
            story.append(Paragraph("<b>Page Title:</b>", heading_style))
            story.append(Paragraph(result['title'], normal_style))
            story.append(Spacer(1, 0.15 * inch))

        # Meta Description
        if result['meta_description']:
            story.append(Paragraph("<b>Meta Description:</b>", heading_style))
            story.append(Paragraph(result['meta_description'], normal_style))
            story.append(Spacer(1, 0.15 * inch))

        # Summary
        if result.get('summary'):
            story.append(Paragraph("<b>Summary:</b>", heading_style))
            story.append(Paragraph(result['summary'], normal_style))
            story.append(Spacer(1, 0.3 * inch))

        # Footer with company details
        if company_details:
            story.append(Paragraph('<hr/>', normal_style))
            story.append(Spacer(1, 0.1 * inch))
            story.append(Paragraph(company_details, footer_style))

        # Build PDF
        try:
            doc.build(story)
            return output_path
        except Exception as e:
            raise Exception(f"Failed to generate PDF: {str(e)}")

    def _encode_image_to_base64(self, image_path: str) -> Optional[str]:
        """
        Encode image file to base64 for embedding in HTML.
        Handles both PNG/JPG (binary) and SVG (text) files.

        Args:
            image_path: Path to the image file

        Returns:
            Base64 encoded image string or None if file not found
        """
        try:
            path = Path(image_path)
            if not path.exists():
                return None

            # Check if it's an SVG file
            if path.suffix.lower() == '.svg':
                # Read SVG as text and base64 encode (works better with Playwright)
                with open(path, 'r', encoding='utf-8') as f:
                    svg_content = f.read()
                    # Base64 encode the SVG for reliable PDF rendering
                    return base64.b64encode(svg_content.encode('utf-8')).decode('utf-8')
            else:
                # Binary image file (PNG, JPG, etc.)
                with open(path, 'rb') as f:
                    image_data = f.read()
                    return base64.b64encode(image_data).decode('utf-8')
        except Exception as e:
            print(f"Error encoding image {image_path}: {str(e)}")
            return None

    async def generate_pdf_playwright(
        self,
        result: Dict,
        is_audit: bool = False,
        output_path: Optional[str] = None,
        logo_path: Optional[str] = None,
        company_name: Optional[str] = None,
        company_details: Optional[str] = None,
        use_dark_theme: bool = False,
        audit_data: Optional[Dict] = None,
        template: str = 'default'
    ) -> str:
        """
        Generate a professional HTML/CSS PDF using Playwright for pixel-perfect rendering.

        Args:
            result: Dictionary returned from analyze()
            is_audit: True for audit report, False for summary
            output_path: Optional custom output path
            logo_path: Optional path to logo image file or URL
            company_name: Optional company name for header
            company_details: Optional company contact details for footer
            use_dark_theme: Whether to use dark theme styling
            audit_data: Optional dictionary with audit-specific data (categories, recommendations, strengths)
            template: Template set to use ('default' or 'jumoki')

        Returns:
            Path to the generated PDF file
        """
        if not PLAYWRIGHT_AVAILABLE:
            raise Exception("Playwright not installed. Install with: pip install playwright")

        if self.jinja_env is None:
            raise Exception("Template directory not found. Cannot generate HTML-based PDF.")

        # Generate filename from URL if not provided
        if not output_path:
            url = result['url']
            domain = urlparse(url).netloc or 'website'
            domain = re.sub(r'[^a-z0-9-]', '-', domain.lower())
            domain = re.sub(r'-+', '-', domain).strip('-')

            if is_audit:
                output_path = f"{domain}-webaudit-report.pdf"
            else:
                output_path = f"{domain}-summary-report.pdf"

        # Select template based on type, theme, and template set
        template_prefix = 'jumoki_' if template == 'jumoki' else ''
        if is_audit:
            template_name = f'{template_prefix}audit_report_dark.html' if use_dark_theme else f'{template_prefix}audit_report_light.html'
        else:
            template_name = f'{template_prefix}summary_report_dark.html' if use_dark_theme else f'{template_prefix}summary_report_light.html'

        try:
            template = self.jinja_env.get_template(template_name)
        except Exception as e:
            raise Exception(f"Template not found: {template_name}. Error: {str(e)}")

        # Prepare context data for template
        context = {
            'url': result['url'],
            'title': result.get('title', 'Website Analysis'),
            'page_title': result.get('title'),
            'meta_description': result.get('meta_description'),
            'summary': result.get('summary'),
            'report_date': datetime.now().strftime('%B %d, %Y'),
            'timestamp': datetime.now().strftime('%B %d, %Y at %I:%M %p'),
            'company_name': company_name,
            'company_details': company_details,
        }

        # Add logos as base64 encoded data
        websler_logo_path = Path(__file__).parent / 'websler_pro.svg'
        jumoki_logo_path = Path(__file__).parent / 'jumoki_logov3.svg'

        if websler_logo_path.exists():
            context['websler_logo'] = self._encode_image_to_base64(str(websler_logo_path))
        if jumoki_logo_path.exists():
            context['jumoki_logo'] = self._encode_image_to_base64(str(jumoki_logo_path))

        # Add audit-specific data if provided
        if is_audit and audit_data:
            context.update({
                'overall_score': audit_data.get('overall_score', 0),
                'categories': audit_data.get('categories', []),
                'recommendations': audit_data.get('recommendations', []),
                'strengths': audit_data.get('strengths', []),
                'weaknesses': audit_data.get('weaknesses', []),
            })

        # Render HTML template
        html_content = template.render(context)

        # Generate PDF using Playwright
        try:
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page(
                    viewport={'width': 1024, 'height': 1280}
                )

                # Set the HTML content
                await page.set_content(html_content)

                # Wait for any images to load
                await page.wait_for_load_state('networkidle')

                # Generate PDF
                await page.pdf(
                    path=output_path,
                    format='A4',
                    margin={
                        'top': '0.5in',
                        'right': '0.5in',
                        'bottom': '0.5in',
                        'left': '0.5in'
                    },
                    print_background=True
                )

                await browser.close()

            return output_path

        except Exception as e:
            raise Exception(f"Failed to generate PDF with Playwright: {str(e)}")


def main():
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(
        description='Analyze a website to determine its purpose using Claude AI'
    )
    parser.add_argument('url', help='Website URL to analyze')
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output results as JSON'
    )
    parser.add_argument(
        '--timeout',
        type=int,
        default=10,
        help='Request timeout in seconds (default: 10)'
    )
    parser.add_argument(
        '--api-key',
        help='Anthropic API key (defaults to ANTHROPIC_API_KEY env var)'
    )
    parser.add_argument(
        '--pdf',
        action='store_true',
        help='Generate a formatted PDF report'
    )
    parser.add_argument(
        '--output',
        help='Custom output filename for PDF (defaults to domain-based name)'
    )
    parser.add_argument(
        '--logo',
        help='Path or URL to company logo image for PDF header'
    )
    parser.add_argument(
        '--company-name',
        help='Company name to display in PDF header'
    )
    parser.add_argument(
        '--company-details',
        help='Company contact details for PDF footer (address, phone, email, etc.)'
    )
    parser.add_argument(
        '--use-playwright',
        action='store_true',
        help='Use Playwright for professional HTML/CSS PDF rendering instead of ReportLab'
    )
    parser.add_argument(
        '--audit',
        action='store_true',
        help='Generate audit report instead of summary report'
    )
    parser.add_argument(
        '--template',
        choices=['default', 'jumoki'],
        default='jumoki',
        help='Template set to use: default (standard templates) or jumoki (Jumoki-branded templates) (default: jumoki)'
    )

    args = parser.parse_args()

    try:
        analyzer = WebsiteAnalyzer(timeout=args.timeout, api_key=args.api_key)
    except ValueError as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        print("\nTo use this tool, you need an Anthropic API key.", file=sys.stderr)
        print("Get one at: https://console.anthropic.com/account/keys", file=sys.stderr)
        sys.exit(1)

    result = analyzer.analyze(args.url)

    if args.json:
        print(json.dumps(result, indent=2))
    elif args.pdf:
        if result['success']:
            try:
                # Use Playwright for HTML/CSS PDF if requested
                if args.use_playwright:
                    pdf_path = analyzer.generate_pdf_playwright(
                        result,
                        is_audit=args.audit,
                        output_path=args.output,
                        logo_path=args.logo,
                        company_name=args.company_name,
                        company_details=args.company_details,
                        use_dark_theme=False,
                        template=args.template
                    )
                    print(f"Professional PDF report generated (Playwright): {pdf_path}")
                else:
                    # Fall back to ReportLab for classic PDF
                    pdf_path = analyzer.generate_pdf(
                        result,
                        output_path=args.output,
                        logo_path=args.logo,
                        company_name=args.company_name,
                        company_details=args.company_details
                    )
                    print(f"PDF report generated (ReportLab): {pdf_path}")
            except Exception as e:
                print(f"Error generating PDF: {str(e)}", file=sys.stderr)
                sys.exit(1)
        else:
            print(f"Error: {result['summary']}", file=sys.stderr)
            sys.exit(1)
    else:
        if result['success']:
            print(result['summary'])
        else:
            print(f"Error: {result['summary']}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()
