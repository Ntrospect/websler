#!/usr/bin/env python3
"""
Convert Andrew's Test Plan (Markdown) to branded PDF
"""

import re
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Image, Table, TableStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.pdfgen import canvas

# Jumoki brand colors
JUMOKI_PURPLE = HexColor('#7c3aed')
JUMOKI_BLUE = HexColor('#2E68DA')
DARK_GRAY = HexColor('#333333')
LIGHT_GRAY = HexColor('#666666')

def add_header_footer(canvas_obj, doc):
    """Add Jumoki branding to header and footer"""
    canvas_obj.saveState()

    # Header - Jumoki Logo (if available)
    try:
        logo_path = 'jumoki_coloured_transparent_bg.png'
        canvas_obj.drawImage(logo_path, 0.5*inch, doc.height + 1.5*inch,
                           width=1.1*inch, height=None, preserveAspectRatio=True)
    except:
        # Fallback: Text header if logo not found
        canvas_obj.setFont('Helvetica-Bold', 10)
        canvas_obj.setFillColor(JUMOKI_PURPLE)
        canvas_obj.drawString(0.5*inch, doc.height + 1.5*inch, "JUMOKI")

    # Footer - Page number and date
    canvas_obj.setFont('Helvetica', 8)
    canvas_obj.setFillColor(LIGHT_GRAY)
    page_num = canvas_obj.getPageNumber()
    footer_text = f"Websler Pro Testing Guide | Page {page_num} | Generated {datetime.now().strftime('%B %d, %Y')}"
    canvas_obj.drawCentredString(doc.width/2 + 1*inch, 0.5*inch, footer_text)

    canvas_obj.restoreState()

def parse_markdown_to_pdf(md_file_path, output_pdf_path):
    """Convert markdown test plan to branded PDF"""

    # Read markdown file
    with open(md_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Create PDF
    doc = SimpleDocTemplate(
        output_pdf_path,
        pagesize=letter,
        rightMargin=0.75*inch,
        leftMargin=0.75*inch,
        topMargin=1*inch,
        bottomMargin=0.75*inch
    )

    # Styles
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=JUMOKI_PURPLE,
        spaceAfter=12,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )

    heading1_style = ParagraphStyle(
        'CustomHeading1',
        parent=styles['Heading1'],
        fontSize=16,
        textColor=JUMOKI_BLUE,
        spaceAfter=8,
        spaceBefore=16,
        fontName='Helvetica-Bold'
    )

    heading2_style = ParagraphStyle(
        'CustomHeading2',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=JUMOKI_PURPLE,
        spaceAfter=6,
        spaceBefore=12,
        fontName='Helvetica-Bold'
    )

    heading3_style = ParagraphStyle(
        'CustomHeading3',
        parent=styles['Heading3'],
        fontSize=12,
        textColor=DARK_GRAY,
        spaceAfter=4,
        spaceBefore=8,
        fontName='Helvetica-Bold'
    )

    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['BodyText'],
        fontSize=10,
        textColor=DARK_GRAY,
        spaceAfter=6,
        leading=14
    )

    bullet_style = ParagraphStyle(
        'CustomBullet',
        parent=styles['BodyText'],
        fontSize=10,
        textColor=DARK_GRAY,
        leftIndent=20,
        spaceAfter=4,
        leading=13
    )

    code_style = ParagraphStyle(
        'CustomCode',
        parent=styles['Code'],
        fontSize=9,
        textColor=HexColor('#0066cc'),
        fontName='Courier',
        leftIndent=20,
        spaceAfter=4
    )

    # Build PDF content
    story = []

    # Parse markdown line by line
    lines = content.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        # Skip empty lines
        if not line:
            i += 1
            continue

        # Title (# )
        if line.startswith('# '):
            text = line[2:].strip()
            story.append(Paragraph(text, title_style))
            story.append(Spacer(1, 0.2*inch))

        # Heading 1 (## )
        elif line.startswith('## '):
            text = line[3:].strip()
            # Add page break before major sections (except first few)
            if len(story) > 10 and text.startswith('Test Section'):
                story.append(PageBreak())
            story.append(Paragraph(text, heading1_style))

        # Heading 2 (### )
        elif line.startswith('### '):
            text = line[4:].strip()
            story.append(Paragraph(text, heading2_style))

        # Heading 3 (#### )
        elif line.startswith('#### '):
            text = line[5:].strip()
            story.append(Paragraph(text, heading3_style))

        # Horizontal rule (---)
        elif line.startswith('---'):
            story.append(Spacer(1, 0.1*inch))

        # Checkbox list item (- [ ])
        elif line.startswith('- [ ]') or line.startswith('- [x]') or line.startswith('- [X]'):
            checked = '[x]' in line.lower()
            text = re.sub(r'- \[[xX ]?\] ', '', line)
            checkbox = '☑' if checked else '☐'
            story.append(Paragraph(f"{checkbox} {text}", bullet_style))

        # Bullet list (- )
        elif line.startswith('- '):
            text = line[2:].strip()
            story.append(Paragraph(f"• {text}", bullet_style))

        # Numbered list (1. )
        elif re.match(r'^\d+\.\s', line):
            text = re.sub(r'^\d+\.\s', '', line)
            number = re.match(r'^(\d+)\.', line).group(1)
            story.append(Paragraph(f"{number}. {text}", bullet_style))

        # Bold text (**text**)
        elif '**' in line:
            text = line
            text = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
            text = re.sub(r'\*(.*?)\*', r'<i>\1</i>', text)
            # Check if it looks like a field/label
            if text.startswith('<b>') and ':' in text:
                story.append(Paragraph(text, heading3_style))
            else:
                story.append(Paragraph(text, body_style))

        # Code block (```)
        elif line.startswith('```'):
            # Skip opening ```
            i += 1
            code_lines = []
            while i < len(lines) and not lines[i].strip().startswith('```'):
                code_lines.append(lines[i])
                i += 1
            # Add code block
            code_text = '<br/>'.join(code_lines)
            story.append(Paragraph(f"<font name='Courier' size='8'>{code_text}</font>", code_style))

        # URLs
        elif line.startswith('http://') or line.startswith('https://'):
            story.append(Paragraph(f"<font color='blue'><u>{line}</u></font>", body_style))

        # Regular paragraph
        else:
            # Convert markdown bold/italic
            text = line
            text = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
            text = re.sub(r'\*(.*?)\*', r'<i>\1</i>', text)
            text = re.sub(r'`(.*?)`', r'<font name="Courier" color="#0066cc">\1</font>', text)
            story.append(Paragraph(text, body_style))

        i += 1

    # Build PDF
    doc.build(story, onFirstPage=add_header_footer, onLaterPages=add_header_footer)
    print(f"[SUCCESS] PDF created successfully: {output_pdf_path}")

if __name__ == '__main__':
    input_md = 'webaudit_pro_app/ANDREW_TEST_PLAN_IOS_MAC.md'
    output_pdf = 'Andrew_Test_Plan_iOS_Mac.pdf'

    print(f"Converting {input_md} to {output_pdf}...")
    parse_markdown_to_pdf(input_md, output_pdf)
    print("Done!")
