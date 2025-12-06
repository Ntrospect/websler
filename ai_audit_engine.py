#!/usr/bin/env python3
"""
AI Discoverability Audit Engine
Evaluates website visibility to AI-powered search tools (ChatGPT, Claude, Perplexity, etc.)
Based on 7-Criteria weighted scoring framework.
"""

import os
import re
import json
import requests
from typing import Optional, Dict, List, Tuple, Any
from dataclasses import dataclass, asdict, field
from datetime import datetime
from bs4 import BeautifulSoup
from urllib.parse import urlparse
import anthropic


# =============================================================================
# DATA MODELS
# =============================================================================

@dataclass
class AICriterionScore:
    """Individual AI criterion evaluation."""
    name: str
    score: float  # 0-10
    weight: float  # 0-1 (e.g., 0.20 for 20%)
    observation: str  # Summary observation
    findings: List[str]  # Specific findings (strengths/weaknesses)
    recommendations: List[str]  # How to improve


@dataclass
class AIRecommendation:
    """Structured recommendation with ROI analysis."""
    title: str
    criterion: str  # Which criterion this affects
    description: str  # Detailed implementation description
    cost_of_implementation: str  # Low/Medium/High
    expected_improvement: str  # e.g., "Content Clarity: 5 → 7"
    roi_assessment: str  # High/Medium/Low with reasoning
    timeline: str  # Immediate/Short-term/Medium-term/Long-term
    priority: int  # 1-5 (1 = highest priority)


@dataclass
class RoadmapPhase:
    """Implementation roadmap phase."""
    name: str  # e.g., "Quick Wins", "Strategic Improvements"
    timeframe: str  # e.g., "0-4 weeks"
    tasks: List[str]
    expected_score_improvement: str  # e.g., "4.5 → 5.8"
    total_effort: str  # e.g., "8-12 hours"


@dataclass
class ImplementationRoadmap:
    """Phased implementation plan."""
    phases: List[RoadmapPhase]
    total_improvement: str  # e.g., "+2.3 points (38% increase)"


@dataclass
class LiveTestResult:
    """Result from live LLM visibility test."""
    llm_name: str  # e.g., "ChatGPT", "Claude", "Perplexity"
    query: str  # The test query
    found: bool  # Was the site mentioned?
    accuracy: str  # "Accurate", "Partially Accurate", "Inaccurate", "Not Found"
    snippet: Optional[str]  # What the LLM said (if found)


@dataclass
class LiveTestResults:
    """Collection of live LLM test results."""
    tests: List[LiveTestResult]
    overall_visibility_score: int  # 0-100 percentage


@dataclass
class AIAuditResult:
    """Complete AI Discoverability audit result."""
    id: str
    url: str
    website_name: str
    audit_timestamp: str
    overall_score: float  # 0-100 (weighted average * 10)
    llm_confidence_score: int  # 0-100% (how confident AI understands this site)
    primary_identity: str  # One-sentence AI summary of what site does
    scores: Dict[str, AICriterionScore]  # 7 criteria with details
    key_strengths: List[str]  # Top 3-5 strengths
    critical_blockers: List[str]  # Red flags (robots.txt blocks, etc.)
    recommendations: List[AIRecommendation]  # Prioritized recommendations
    implementation_roadmap: ImplementationRoadmap  # Phased plan
    predicted_prompts: List[str]  # Questions site can answer
    live_test_results: Optional[LiveTestResults] = None  # If run_live_tests=True


# =============================================================================
# MAIN AUDITOR CLASS
# =============================================================================

class AIDiscoverabilityAuditor:
    """
    AI Discoverability Auditor - evaluates websites for LLM visibility.

    7 Criteria (Weighted):
    1. Content Clarity & Parsability (20%)
    2. Answer-Oriented Content (18%)
    3. Technical Accessibility (15%)
    4. Structured Data & Markup (12%)
    5. Information Architecture (10%)
    6. Citation-Worthiness (15%)
    7. Comparative & Specification Content (10%)
    """

    CRITERIA = {
        "Content Clarity & Parsability": {
            "weight": 0.20,
            "description": "How easily can an LLM extract key information about what the company/product does?",
            "checks": [
                "Value propositions stated directly vs. buried in marketing language",
                "Proper semantic HTML (H1-H6, lists, tables)",
                "Key facts can be quoted without interpretation"
            ]
        },
        "Answer-Oriented Content": {
            "weight": 0.18,
            "description": "Does content directly answer common user questions?",
            "checks": [
                "Dedicated FAQ pages or problem-solution content",
                "Information comprehensive enough to be citeable",
                "Addresses 'how to', 'what is', 'why', comparison queries"
            ]
        },
        "Technical Accessibility": {
            "weight": 0.15,
            "description": "Can LLM crawlers access the content?",
            "checks": [
                "Content accessible without JavaScript execution",
                "Critical details not behind forms/logins/paywalls",
                "robots.txt properly configured (not blocking GPTBot, ClaudeBot)"
            ]
        },
        "Structured Data & Markup": {
            "weight": 0.12,
            "description": "Is structured data properly implemented?",
            "checks": [
                "Schema.org markup (Product, Article, FAQ, Organization)",
                "Proper meta descriptions and title tags",
                "Open Graph and Twitter Card tags"
            ]
        },
        "Information Architecture": {
            "weight": 0.10,
            "description": "Is information logically organized and easy to navigate?",
            "checks": [
                "Related information grouped coherently",
                "No unnecessary fragmentation across pages",
                "Descriptive and hierarchical URLs"
            ]
        },
        "Citation-Worthiness": {
            "weight": 0.15,
            "description": "Would LLMs want to cite this content as authoritative?",
            "checks": [
                "Original research, data, or insights published",
                "Clear authorship and expertise demonstrated",
                "Claims supported with evidence, content dated"
            ]
        },
        "Comparative & Specification Content": {
            "weight": 0.10,
            "description": "Are specifications and comparisons explicitly available?",
            "checks": [
                "Product specifications clearly listed",
                "Comparison pages/tables exist",
                "Features, pricing, capabilities explicitly stated"
            ]
        }
    }

    def __init__(self, timeout: int = 15, api_key: Optional[str] = None):
        """Initialize auditor with timeout and API key."""
        self.timeout = timeout
        self.api_key = api_key or os.getenv('ANTHROPIC_API_KEY')
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY environment variable not set")
        self.client = anthropic.Anthropic(api_key=self.api_key)

    def audit(self, url: str, run_live_tests: bool = False) -> AIAuditResult:
        """
        Perform comprehensive AI Discoverability audit of a website.

        Args:
            url: Website URL to audit
            run_live_tests: Whether to query actual LLMs for visibility tests

        Returns:
            AIAuditResult with scores, observations, recommendations, and roadmap
        """
        import uuid

        # Normalize URL
        url = self._normalize_url(url)
        print(f"[*] Starting AI Discoverability Audit for: {url}")

        # Fetch and parse website
        html_content, page_metadata = self._fetch_website(url)
        print(f"[+] Fetched website: {page_metadata.get('title', 'Unknown')}")

        # Extract detailed analysis data
        analysis_data = self._analyze_for_ai_discoverability(html_content, url)
        print(f"[*] Analyzed content: {analysis_data.get('word_count', 0)} words")

        # Get robots.txt analysis
        robots_analysis = self._analyze_robots_txt(url)
        print(f"[*] Robots.txt: {'Blocking AI' if robots_analysis.get('blocks_ai') else 'AI-friendly'}")

        # Evaluate each criterion using Claude
        scores = {}
        all_recommendations = []

        for criterion_name, criterion_info in self.CRITERIA.items():
            print(f"[*] Evaluating: {criterion_name}...")
            score_data = self._evaluate_criterion(
                criterion_name,
                criterion_info,
                url,
                html_content,
                page_metadata,
                analysis_data,
                robots_analysis
            )
            scores[criterion_name] = score_data

            # Collect recommendations from each criterion
            for rec in score_data.recommendations:
                all_recommendations.append({
                    "criterion": criterion_name,
                    "recommendation": rec,
                    "score": score_data.score
                })

        # Calculate weighted overall score (0-10, displayed as 0-100)
        overall_score = self._calculate_weighted_score(scores)
        print(f"[*] Overall Score: {overall_score:.1f}/100")

        # Generate primary identity (one-sentence summary)
        primary_identity = self._generate_primary_identity(url, page_metadata, html_content)

        # Calculate LLM confidence score
        llm_confidence = self._calculate_llm_confidence(scores, analysis_data, robots_analysis)

        # Extract key strengths and critical blockers
        key_strengths = self._extract_strengths(scores)
        critical_blockers = self._extract_blockers(scores, robots_analysis, analysis_data)

        # Generate prioritized recommendations with ROI
        recommendations = self._generate_recommendations(all_recommendations, scores)

        # Generate implementation roadmap
        roadmap = self._generate_roadmap(recommendations, overall_score)

        # Generate predicted prompts
        predicted_prompts = self._generate_predicted_prompts(
            url, page_metadata, analysis_data, scores
        )

        # Run live LLM tests if requested
        live_test_results = None
        if run_live_tests:
            print("[*] Running live LLM visibility tests...")
            live_test_results = self._run_live_llm_tests(
                page_metadata.get('title', ''),
                url
            )

        # Generate unique ID
        audit_id = str(uuid.uuid4())

        return AIAuditResult(
            id=audit_id,
            url=url,
            website_name=self._extract_website_name(url, page_metadata),
            audit_timestamp=datetime.utcnow().isoformat(),
            overall_score=overall_score,
            llm_confidence_score=llm_confidence,
            primary_identity=primary_identity,
            scores=scores,
            key_strengths=key_strengths,
            critical_blockers=critical_blockers,
            recommendations=recommendations,
            implementation_roadmap=roadmap,
            predicted_prompts=predicted_prompts,
            live_test_results=live_test_results
        )

    # =========================================================================
    # URL & FETCH HELPERS
    # =========================================================================

    def _normalize_url(self, url: str) -> str:
        """Add https:// if no scheme provided."""
        if not url.startswith(('http://', 'https://')):
            url = 'https://' + url
        return url

    def _fetch_website(self, url: str) -> Tuple[str, Dict]:
        """Fetch website HTML and extract metadata."""
        try:
            response = requests.get(
                url,
                timeout=self.timeout,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
            )
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract metadata
            metadata = {
                'title': soup.find('title').text.strip() if soup.find('title') else '',
                'meta_description': self._get_meta_content(soup, 'description'),
                'og_title': self._get_meta_content(soup, 'og:title'),
                'og_description': self._get_meta_content(soup, 'og:description'),
                'og_type': self._get_meta_content(soup, 'og:type'),
                'twitter_card': self._get_meta_content(soup, 'twitter:card'),
                'author': self._get_meta_content(soup, 'author'),
                'viewport': self._get_meta_content(soup, 'viewport'),
                'charset': soup.find('meta', {'charset': True}) is not None,
                'https': response.url.startswith('https'),
                'status_code': response.status_code,
                'content_type': response.headers.get('Content-Type', ''),
            }

            return response.text, metadata
        except requests.RequestException as e:
            raise Exception(f"Failed to fetch website: {str(e)}")

    def _get_meta_content(self, soup: BeautifulSoup, name: str) -> str:
        """Extract meta tag content."""
        meta = soup.find('meta', {'name': name}) or soup.find('meta', {'property': name})
        return meta.get('content', '').strip() if meta else ''

    def _extract_website_name(self, url: str, metadata: Dict) -> str:
        """Extract website name from URL or title."""
        if metadata.get('title'):
            # Clean up title (remove common suffixes)
            title = metadata['title']
            for sep in ['|', '-', '–', '—', ':']:
                if sep in title:
                    title = title.split(sep)[0].strip()
            return title
        parsed = urlparse(url)
        return parsed.netloc.replace('www.', '')

    # =========================================================================
    # ANALYSIS HELPERS
    # =========================================================================

    def _analyze_for_ai_discoverability(self, html: str, url: str) -> Dict:
        """Analyze website structure and content for AI discoverability."""
        soup = BeautifulSoup(html, 'html.parser')

        # Semantic structure analysis
        h1_tags = soup.find_all('h1')
        h2_tags = soup.find_all('h2')
        h3_tags = soup.find_all('h3')

        # FAQ detection
        faq_indicators = self._detect_faq_content(soup)

        # Schema.org detection
        schema_data = self._detect_schema_markup(soup)

        # Content quality indicators
        lists = soup.find_all(['ul', 'ol'])
        tables = soup.find_all('table')

        # Question patterns in content
        text_content = soup.get_text()
        question_patterns = len(re.findall(r'\?', text_content))
        how_to_patterns = len(re.findall(r'\b(how to|what is|why|when|where|which)\b', text_content.lower()))

        return {
            'has_h1': bool(h1_tags),
            'h1_count': len(h1_tags),
            'h1_text': h1_tags[0].get_text().strip() if h1_tags else '',
            'h2_count': len(h2_tags),
            'h3_count': len(h3_tags),
            'heading_hierarchy_valid': self._check_heading_hierarchy(soup),
            'has_nav': bool(soup.find('nav')),
            'has_footer': bool(soup.find('footer')),
            'has_main': bool(soup.find('main')),
            'has_article': bool(soup.find('article')),
            'has_section': bool(soup.find_all('section')),
            'img_count': len(soup.find_all('img')),
            'img_with_alt': len([img for img in soup.find_all('img') if img.get('alt')]),
            'list_count': len(lists),
            'table_count': len(tables),
            'form_count': len(soup.find_all('form')),
            'link_count': len(soup.find_all('a')),
            'word_count': len(text_content.split()),
            'question_patterns': question_patterns,
            'how_to_patterns': how_to_patterns,
            'has_faq': faq_indicators['has_faq'],
            'faq_question_count': faq_indicators['question_count'],
            'schema_types': schema_data['types'],
            'has_schema': schema_data['has_schema'],
            'has_faq_schema': 'FAQPage' in schema_data['types'],
            'has_organization_schema': 'Organization' in schema_data['types'],
            'has_product_schema': 'Product' in schema_data['types'],
            'noscript_content': bool(soup.find('noscript')),
            'script_count': len(soup.find_all('script')),
            'inline_script_heavy': len([s for s in soup.find_all('script') if not s.get('src')]) > 10,
        }

    def _detect_faq_content(self, soup: BeautifulSoup) -> Dict:
        """Detect FAQ patterns in content."""
        faq_indicators = {
            'has_faq': False,
            'question_count': 0
        }

        # Check for FAQ in headings
        faq_headings = soup.find_all(['h1', 'h2', 'h3', 'h4'],
            string=re.compile(r'(FAQ|Frequently Asked|Questions)', re.I))

        if faq_headings:
            faq_indicators['has_faq'] = True

        # Check for question-answer patterns
        # Look for elements with FAQ-related classes
        faq_elements = soup.find_all(class_=re.compile(r'(faq|question|accordion)', re.I))
        if faq_elements:
            faq_indicators['has_faq'] = True
            faq_indicators['question_count'] = len(faq_elements)

        # Look for definition lists (often used for FAQs)
        dt_tags = soup.find_all('dt')
        if len(dt_tags) >= 3:
            faq_indicators['has_faq'] = True
            faq_indicators['question_count'] = max(faq_indicators['question_count'], len(dt_tags))

        return faq_indicators

    def _detect_schema_markup(self, soup: BeautifulSoup) -> Dict:
        """Detect Schema.org structured data."""
        schema_data = {
            'has_schema': False,
            'types': []
        }

        # Look for JSON-LD schema
        json_ld_scripts = soup.find_all('script', {'type': 'application/ld+json'})
        for script in json_ld_scripts:
            try:
                data = json.loads(script.string)
                schema_data['has_schema'] = True

                # Handle both single objects and arrays
                if isinstance(data, list):
                    for item in data:
                        if '@type' in item:
                            schema_data['types'].append(item['@type'])
                elif isinstance(data, dict):
                    if '@type' in data:
                        schema_data['types'].append(data['@type'])
                    # Check for @graph
                    if '@graph' in data:
                        for item in data['@graph']:
                            if '@type' in item:
                                schema_data['types'].append(item['@type'])
            except (json.JSONDecodeError, TypeError):
                pass

        # Look for microdata (itemtype)
        microdata_elements = soup.find_all(attrs={'itemtype': True})
        for el in microdata_elements:
            schema_data['has_schema'] = True
            itemtype = el.get('itemtype', '')
            if 'schema.org' in itemtype:
                type_name = itemtype.split('/')[-1]
                if type_name not in schema_data['types']:
                    schema_data['types'].append(type_name)

        return schema_data

    def _check_heading_hierarchy(self, soup: BeautifulSoup) -> bool:
        """Check if heading hierarchy is valid (H1 -> H2 -> H3, etc.)."""
        headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
        if not headings:
            return False

        prev_level = 0
        for heading in headings:
            level = int(heading.name[1])
            # Allow same level or one level deeper, or any higher level
            if level > prev_level + 1 and prev_level != 0:
                return False
            prev_level = level

        return True

    def _analyze_robots_txt(self, url: str) -> Dict:
        """Analyze robots.txt for AI crawler restrictions."""
        parsed = urlparse(url)
        robots_url = f"{parsed.scheme}://{parsed.netloc}/robots.txt"

        result = {
            'exists': False,
            'blocks_ai': False,
            'blocked_bots': [],
            'allows_all': True,
            'sitemap_url': None,
            'raw_content': ''
        }

        try:
            response = requests.get(robots_url, timeout=5)
            if response.status_code == 200:
                result['exists'] = True
                result['raw_content'] = response.text[:1000]  # First 1000 chars

                content = response.text.lower()

                # Check for AI bot blocking
                ai_bots = ['gptbot', 'chatgpt-user', 'claudebot', 'anthropic',
                          'ccbot', 'perplexitybot', 'google-extended']

                for bot in ai_bots:
                    if bot in content:
                        # Check if it's being disallowed
                        bot_section = re.search(
                            rf'user-agent:\s*{bot}.*?(?=user-agent:|$)',
                            content,
                            re.DOTALL | re.IGNORECASE
                        )
                        if bot_section and 'disallow: /' in bot_section.group():
                            result['blocks_ai'] = True
                            result['blocked_bots'].append(bot)

                # Check for blanket blocking
                if 'user-agent: *' in content:
                    wildcard_section = re.search(
                        r'user-agent:\s*\*.*?(?=user-agent:|$)',
                        content,
                        re.DOTALL | re.IGNORECASE
                    )
                    if wildcard_section and 'disallow: /' in wildcard_section.group():
                        # Check if it's truly blocking everything
                        if 'allow:' not in wildcard_section.group():
                            result['allows_all'] = False

                # Extract sitemap
                sitemap_match = re.search(r'sitemap:\s*(\S+)', content, re.IGNORECASE)
                if sitemap_match:
                    result['sitemap_url'] = sitemap_match.group(1)

        except requests.RequestException:
            pass

        return result

    # =========================================================================
    # CRITERION EVALUATION
    # =========================================================================

    def _evaluate_criterion(
        self,
        criterion_name: str,
        criterion_info: Dict,
        url: str,
        html: str,
        metadata: Dict,
        analysis: Dict,
        robots: Dict
    ) -> AICriterionScore:
        """Evaluate a single criterion using Claude AI."""

        # Build context for this specific criterion
        context = self._build_criterion_context(
            criterion_name, url, metadata, analysis, robots
        )

        prompt = f"""You are an AI Discoverability expert evaluating a website's visibility to LLMs (ChatGPT, Claude, Perplexity, etc.).

**Criterion: {criterion_name}** (Weight: {criterion_info['weight']*100:.0f}%)

**Description:** {criterion_info['description']}

**What to Check:**
{chr(10).join(f'- {check}' for check in criterion_info['checks'])}

**Website:** {url}
**Title:** {metadata.get('title', 'N/A')}
**Meta Description:** {metadata.get('meta_description', 'N/A')[:200]}

**Analysis Data:**
{context}

Based on this analysis, evaluate the website's {criterion_name}. Provide:
1. A score from 0-10 (be critical but fair)
2. A one-sentence summary observation
3. 2-4 specific findings (mix of strengths and weaknesses)
4. 2-3 actionable recommendations for improvement

Respond in JSON format:
{{
    "score": <number 0-10>,
    "observation": "<one sentence summary>",
    "findings": ["finding1", "finding2", "finding3"],
    "recommendations": ["rec1", "rec2", "rec3"]
}}"""

        try:
            message = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=600,
                messages=[{"role": "user", "content": prompt}]
            )

            response_text = message.content[0].text

            # Extract JSON from response
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                result = json.loads(json_match.group())
            else:
                raise ValueError("No JSON found in response")

            score = max(0, min(10, float(result.get("score", 5))))

            return AICriterionScore(
                name=criterion_name,
                score=score,
                weight=criterion_info['weight'],
                observation=result.get("observation", "Unable to fully evaluate"),
                findings=result.get("findings", [])[:4],
                recommendations=result.get("recommendations", [])[:3]
            )

        except Exception as e:
            print(f"[!] Error evaluating {criterion_name}: {str(e)}")
            return AICriterionScore(
                name=criterion_name,
                score=5.0,
                weight=criterion_info['weight'],
                observation=f"Evaluation encountered an issue: {str(e)[:50]}",
                findings=["Manual review recommended"],
                recommendations=["Review this criterion manually"]
            )

    def _build_criterion_context(
        self,
        criterion_name: str,
        url: str,
        metadata: Dict,
        analysis: Dict,
        robots: Dict
    ) -> str:
        """Build relevant context for criterion evaluation."""

        context_builders = {
            "Content Clarity & Parsability": lambda: f"""
- H1 present: {analysis.get('has_h1')} | H1 text: "{analysis.get('h1_text', '')[:50]}"
- Heading count: H1={analysis.get('h1_count')}, H2={analysis.get('h2_count')}, H3={analysis.get('h3_count')}
- Valid heading hierarchy: {analysis.get('heading_hierarchy_valid')}
- Semantic elements: main={analysis.get('has_main')}, article={analysis.get('has_article')}, nav={analysis.get('has_nav')}
- Lists: {analysis.get('list_count')} | Tables: {analysis.get('table_count')}
- Word count: {analysis.get('word_count')}
- OG title: {metadata.get('og_title', 'None')[:50]}""",

            "Answer-Oriented Content": lambda: f"""
- Has FAQ section: {analysis.get('has_faq')}
- FAQ questions detected: {analysis.get('faq_question_count')}
- Question patterns in content: {analysis.get('question_patterns')}
- How-to/What-is patterns: {analysis.get('how_to_patterns')}
- Has FAQ Schema: {analysis.get('has_faq_schema')}
- Word count: {analysis.get('word_count')}
- Tables (for comparisons): {analysis.get('table_count')}""",

            "Technical Accessibility": lambda: f"""
- HTTPS: {metadata.get('https')}
- robots.txt exists: {robots.get('exists')}
- Blocks AI crawlers: {robots.get('blocks_ai')}
- Blocked bots: {', '.join(robots.get('blocked_bots', [])) or 'None'}
- Has sitemap: {robots.get('sitemap_url') is not None}
- Inline scripts (JS-heavy): {analysis.get('inline_script_heavy')}
- Script count: {analysis.get('script_count')}
- Has noscript fallback: {analysis.get('noscript_content')}
- Form count: {analysis.get('form_count')}""",

            "Structured Data & Markup": lambda: f"""
- Has Schema.org: {analysis.get('has_schema')}
- Schema types: {', '.join(analysis.get('schema_types', [])) or 'None'}
- Meta description: {bool(metadata.get('meta_description'))} ({len(metadata.get('meta_description', ''))} chars)
- OG tags: title={bool(metadata.get('og_title'))}, desc={bool(metadata.get('og_description'))}, type={metadata.get('og_type', 'None')}
- Twitter Card: {metadata.get('twitter_card', 'None')}
- Charset defined: {metadata.get('charset')}
- Author meta: {bool(metadata.get('author'))}""",

            "Information Architecture": lambda: f"""
- Has navigation: {analysis.get('has_nav')}
- Has main content area: {analysis.get('has_main')}
- Has footer: {analysis.get('has_footer')}
- Section elements: {analysis.get('has_section')}
- Internal links: {analysis.get('link_count')}
- Valid heading hierarchy: {analysis.get('heading_hierarchy_valid')}
- H2 sections: {analysis.get('h2_count')}
- URL structure: {url}""",

            "Citation-Worthiness": lambda: f"""
- Author attribution: {bool(metadata.get('author'))}
- Word count (content depth): {analysis.get('word_count')}
- Has data tables: {analysis.get('table_count') > 0}
- Lists (structured info): {analysis.get('list_count')}
- Organization schema: {analysis.get('has_organization_schema')}
- HTTPS (credibility): {metadata.get('https')}
- Question patterns: {analysis.get('question_patterns')}""",

            "Comparative & Specification Content": lambda: f"""
- Tables (specs/comparisons): {analysis.get('table_count')}
- Lists (features): {analysis.get('list_count')}
- Product schema: {analysis.get('has_product_schema')}
- Word count: {analysis.get('word_count')}
- Has FAQ: {analysis.get('has_faq')}
- H2 count (section topics): {analysis.get('h2_count')}
- H3 count (sub-topics): {analysis.get('h3_count')}"""
        }

        builder = context_builders.get(criterion_name, lambda: "General analysis available")
        return builder()

    # =========================================================================
    # SCORE CALCULATION
    # =========================================================================

    def _calculate_weighted_score(self, scores: Dict[str, AICriterionScore]) -> float:
        """Calculate weighted overall score (0-100)."""
        total = 0.0
        total_weight = 0.0

        for criterion_name, score_data in scores.items():
            total += score_data.score * score_data.weight
            total_weight += score_data.weight

        if total_weight > 0:
            weighted_avg = total / total_weight  # 0-10
            return round(weighted_avg * 10, 1)  # Convert to 0-100
        return 50.0

    def _calculate_llm_confidence(
        self,
        scores: Dict[str, AICriterionScore],
        analysis: Dict,
        robots: Dict
    ) -> int:
        """Calculate how confident an LLM would be understanding this site."""

        confidence = 50  # Base confidence

        # Major factors
        if robots.get('blocks_ai'):
            confidence -= 30  # Major penalty for blocking AI

        if analysis.get('has_schema'):
            confidence += 10

        if analysis.get('heading_hierarchy_valid'):
            confidence += 5

        if analysis.get('has_faq'):
            confidence += 10

        # Content clarity score heavily influences confidence
        clarity_score = scores.get("Content Clarity & Parsability")
        if clarity_score:
            confidence += int((clarity_score.score - 5) * 4)  # -20 to +20

        # Answer-oriented content also important
        answer_score = scores.get("Answer-Oriented Content")
        if answer_score:
            confidence += int((answer_score.score - 5) * 3)  # -15 to +15

        # Word count factor
        word_count = analysis.get('word_count', 0)
        if word_count < 200:
            confidence -= 10
        elif word_count > 1000:
            confidence += 5

        return max(0, min(100, confidence))

    # =========================================================================
    # STRENGTHS & BLOCKERS
    # =========================================================================

    def _extract_strengths(self, scores: Dict[str, AICriterionScore]) -> List[str]:
        """Extract top key strengths from high-scoring criteria."""
        strengths = []

        # Sort by score descending
        sorted_scores = sorted(
            scores.items(),
            key=lambda x: x[1].score,
            reverse=True
        )

        for criterion_name, score_data in sorted_scores[:4]:
            if score_data.score >= 6:
                # Get positive findings
                for finding in score_data.findings[:2]:
                    if not any(neg in finding.lower() for neg in ['lack', 'missing', 'no ', 'poor', 'weak']):
                        strengths.append(finding)
                        if len(strengths) >= 5:
                            break
            if len(strengths) >= 5:
                break

        return strengths[:5]

    def _extract_blockers(
        self,
        scores: Dict[str, AICriterionScore],
        robots: Dict,
        analysis: Dict
    ) -> List[str]:
        """Extract critical blockers (red flags)."""
        blockers = []

        # Critical: robots.txt blocking AI
        if robots.get('blocks_ai'):
            blocked = ', '.join(robots.get('blocked_bots', []))
            blockers.append(f"[BLOCKED] robots.txt blocks AI crawlers: {blocked}")

        # Critical: No schema markup
        if not analysis.get('has_schema'):
            blockers.append("[WARNING] No Schema.org structured data detected")

        # Critical: Very low content
        if analysis.get('word_count', 0) < 200:
            blockers.append("[WARNING] Insufficient content (< 200 words)")

        # Critical: Heavy JS dependency
        if analysis.get('inline_script_heavy'):
            blockers.append("[WARNING] Heavy JavaScript may prevent content indexing")

        # Check low-scoring criteria
        for criterion_name, score_data in scores.items():
            if score_data.score < 4:
                blockers.append(f"[LOW] Low score in {criterion_name}: {score_data.observation[:80]}")

        return blockers[:6]

    # =========================================================================
    # RECOMMENDATIONS & ROADMAP
    # =========================================================================

    def _generate_recommendations(
        self,
        all_recommendations: List[Dict],
        scores: Dict[str, AICriterionScore]
    ) -> List[AIRecommendation]:
        """Generate prioritized recommendations with ROI analysis."""

        recommendations = []

        # Sort by score impact (lower scores = higher priority)
        sorted_recs = sorted(all_recommendations, key=lambda x: x['score'])

        # Use Claude to enhance recommendations with ROI
        rec_texts = [r['recommendation'] for r in sorted_recs[:8]]

        prompt = f"""Given these website improvement recommendations for AI discoverability:

{chr(10).join(f'{i+1}. ({sorted_recs[i]["criterion"]}) {rec}' for i, rec in enumerate(rec_texts))}

For each recommendation, estimate:
1. Cost of Implementation: Low (1-4 hours), Medium (1-3 days), High (1+ weeks)
2. Expected Impact: Score improvement potential
3. ROI: High (quick win), Medium (good investment), Low (long-term)
4. Timeline: Immediate/Short-term (1-4 weeks)/Medium-term (1-3 months)/Long-term

Respond in JSON array format:
[
  {{
    "title": "Brief title",
    "description": "What to do",
    "cost": "Low/Medium/High",
    "improvement": "e.g., +1.5 points",
    "roi": "High/Medium/Low",
    "timeline": "Immediate/Short-term/Medium-term/Long-term"
  }},
  ...
]"""

        try:
            message = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=1000,
                messages=[{"role": "user", "content": prompt}]
            )

            response_text = message.content[0].text
            json_match = re.search(r'\[[\s\S]*\]', response_text)

            if json_match:
                enhanced_recs = json.loads(json_match.group())

                for i, rec in enumerate(enhanced_recs[:8]):
                    original = sorted_recs[i] if i < len(sorted_recs) else sorted_recs[0]
                    recommendations.append(AIRecommendation(
                        title=rec.get('title', f"Recommendation {i+1}"),
                        criterion=original['criterion'],
                        description=rec.get('description', original['recommendation']),
                        cost_of_implementation=rec.get('cost', 'Medium'),
                        expected_improvement=rec.get('improvement', '+0.5 points'),
                        roi_assessment=rec.get('roi', 'Medium'),
                        timeline=rec.get('timeline', 'Short-term'),
                        priority=i + 1
                    ))
        except Exception as e:
            print(f"[!] Error enhancing recommendations: {e}")
            # Fallback to basic recommendations
            for i, rec in enumerate(sorted_recs[:8]):
                recommendations.append(AIRecommendation(
                    title=f"Improve {rec['criterion']}",
                    criterion=rec['criterion'],
                    description=rec['recommendation'],
                    cost_of_implementation="Medium",
                    expected_improvement="+0.5 points",
                    roi_assessment="Medium",
                    timeline="Short-term",
                    priority=i + 1
                ))

        return recommendations

    def _generate_roadmap(
        self,
        recommendations: List[AIRecommendation],
        current_score: float
    ) -> ImplementationRoadmap:
        """Generate phased implementation roadmap."""

        phases = []

        # Phase 1: Quick Wins (Immediate, Low cost, High ROI)
        quick_wins = [r for r in recommendations if r.roi_assessment == "High" and r.cost_of_implementation == "Low"]
        if quick_wins:
            phases.append(RoadmapPhase(
                name="Quick Wins",
                timeframe="0-4 weeks",
                tasks=[r.title for r in quick_wins[:4]],
                expected_score_improvement=f"{current_score:.1f} → {min(100, current_score + 8):.1f}",
                total_effort="4-8 hours"
            ))

        # Phase 2: Strategic Improvements (Medium cost, good impact)
        strategic = [r for r in recommendations if r.cost_of_implementation == "Medium"]
        if strategic:
            phases.append(RoadmapPhase(
                name="Strategic Improvements",
                timeframe="1-3 months",
                tasks=[r.title for r in strategic[:4]],
                expected_score_improvement=f"{min(100, current_score + 8):.1f} → {min(100, current_score + 15):.1f}",
                total_effort="2-4 weeks"
            ))

        # Phase 3: Comprehensive (High cost, long-term)
        comprehensive = [r for r in recommendations if r.cost_of_implementation == "High"]
        if comprehensive:
            phases.append(RoadmapPhase(
                name="Comprehensive Optimization",
                timeframe="3-6 months",
                tasks=[r.title for r in comprehensive[:3]],
                expected_score_improvement=f"{min(100, current_score + 15):.1f} → {min(100, current_score + 25):.1f}",
                total_effort="1-2 months"
            ))

        # Calculate total improvement
        max_improvement = min(25, 100 - current_score)
        improvement_pct = (max_improvement / current_score * 100) if current_score > 0 else 0

        return ImplementationRoadmap(
            phases=phases,
            total_improvement=f"+{max_improvement:.1f} points ({improvement_pct:.0f}% increase potential)"
        )

    # =========================================================================
    # PREDICTED PROMPTS & IDENTITY
    # =========================================================================

    def _generate_predicted_prompts(
        self,
        url: str,
        metadata: Dict,
        analysis: Dict,
        scores: Dict[str, AICriterionScore]
    ) -> List[str]:
        """Generate predicted prompts the site could answer."""

        website_name = metadata.get('title', '').split('|')[0].strip()
        description = metadata.get('meta_description', '')

        prompt = f"""Based on this website:
- Name: {website_name}
- URL: {url}
- Description: {description[:200]}
- Has FAQ: {analysis.get('has_faq')}
- Word count: {analysis.get('word_count')}

Generate 5-7 example questions/prompts that users might ask an LLM that this website could potentially answer.
These should be natural questions someone might type into ChatGPT or Claude.

Format as a JSON array of strings:
["Question 1?", "Question 2?", ...]"""

        try:
            message = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=400,
                messages=[{"role": "user", "content": prompt}]
            )

            response_text = message.content[0].text
            json_match = re.search(r'\[[\s\S]*?\]', response_text)

            if json_match:
                return json.loads(json_match.group())[:7]
        except Exception:
            pass

        # Fallback generic prompts
        return [
            f"What does {website_name} do?",
            f"How does {website_name} work?",
            f"Is {website_name} good for [use case]?",
            f"What are the features of {website_name}?",
            f"How much does {website_name} cost?"
        ]

    def _generate_primary_identity(
        self,
        url: str,
        metadata: Dict,
        html: str
    ) -> str:
        """Generate one-sentence summary of what the site does."""

        soup = BeautifulSoup(html, 'html.parser')

        # Extract key content
        title = metadata.get('title', '')
        description = metadata.get('meta_description', '')
        h1 = soup.find('h1')
        h1_text = h1.get_text().strip() if h1 else ''

        prompt = f"""Based on this website information, write ONE clear sentence describing what this website/company does. Be specific and factual.

URL: {url}
Title: {title}
H1: {h1_text}
Meta Description: {description[:300]}

Write only the one-sentence summary, no explanations."""

        try:
            message = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=100,
                messages=[{"role": "user", "content": prompt}]
            )

            return message.content[0].text.strip()
        except Exception:
            return description[:150] if description else f"Website at {url}"

    # =========================================================================
    # LIVE LLM TESTS (Optional)
    # =========================================================================

    def _run_live_llm_tests(
        self,
        company_name: str,
        url: str
    ) -> LiveTestResults:
        """Run live queries against LLMs to test visibility (placeholder)."""

        # Note: This would require API integrations with multiple LLMs
        # For now, return a placeholder indicating this feature needs API keys

        tests = [
            LiveTestResult(
                llm_name="Claude",
                query=f"What does {company_name} do?",
                found=False,
                accuracy="Not Tested",
                snippet="Live testing requires additional API configuration"
            ),
            LiveTestResult(
                llm_name="Note",
                query="Live LLM visibility testing",
                found=False,
                accuracy="Not Available",
                snippet="This feature requires API keys for ChatGPT, Perplexity, etc."
            )
        ]

        return LiveTestResults(
            tests=tests,
            overall_visibility_score=0
        )

    # =========================================================================
    # SERIALIZATION
    # =========================================================================

    def to_dict(self, result: AIAuditResult) -> Dict[str, Any]:
        """Convert AIAuditResult to dictionary for JSON serialization."""
        return {
            "id": result.id,
            "url": result.url,
            "website_name": result.website_name,
            "audit_timestamp": result.audit_timestamp,
            "overall_score": result.overall_score,
            "llm_confidence_score": result.llm_confidence_score,
            "primary_identity": result.primary_identity,
            "scores": {
                name: {
                    "score": round(s.score, 1),
                    "weight": s.weight,
                    "observation": s.observation,
                    "findings": s.findings,
                    "recommendations": s.recommendations
                }
                for name, s in result.scores.items()
            },
            "key_strengths": result.key_strengths,
            "critical_blockers": result.critical_blockers,
            "recommendations": [
                {
                    "title": r.title,
                    "criterion": r.criterion,
                    "description": r.description,
                    "cost_of_implementation": r.cost_of_implementation,
                    "expected_improvement": r.expected_improvement,
                    "roi_assessment": r.roi_assessment,
                    "timeline": r.timeline,
                    "priority": r.priority
                }
                for r in result.recommendations
            ],
            "implementation_roadmap": {
                "phases": [
                    {
                        "name": p.name,
                        "timeframe": p.timeframe,
                        "tasks": p.tasks,
                        "expected_score_improvement": p.expected_score_improvement,
                        "total_effort": p.total_effort
                    }
                    for p in result.implementation_roadmap.phases
                ],
                "total_improvement": result.implementation_roadmap.total_improvement
            },
            "predicted_prompts": result.predicted_prompts,
            "live_test_results": {
                "tests": [
                    {
                        "llm_name": t.llm_name,
                        "query": t.query,
                        "found": t.found,
                        "accuracy": t.accuracy,
                        "snippet": t.snippet
                    }
                    for t in result.live_test_results.tests
                ],
                "overall_visibility_score": result.live_test_results.overall_visibility_score
            } if result.live_test_results else None
        }


# =============================================================================
# CLI ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python ai_audit_engine.py <url> [--live-tests]")
        print("Example: python ai_audit_engine.py https://example.com")
        sys.exit(1)

    url = sys.argv[1]
    run_live = "--live-tests" in sys.argv

    try:
        auditor = AIDiscoverabilityAuditor()
        result = auditor.audit(url, run_live_tests=run_live)

        print("\n" + "="*60)
        print("AI DISCOVERABILITY AUDIT RESULTS")
        print("="*60)
        print(f"\nWebsite: {result.website_name}")
        print(f"URL: {result.url}")
        print(f"Timestamp: {result.audit_timestamp}")
        print(f"\nOverall Score: {result.overall_score}/100")
        print(f"LLM Confidence: {result.llm_confidence_score}%")
        print(f"\nPrimary Identity: {result.primary_identity}")

        print("\nSCORES BY CRITERION:")
        for name, score in result.scores.items():
            bar = "#" * int(score.score) + "-" * (10 - int(score.score))
            print(f"  {name}: {score.score:.1f}/10 [{bar}] ({score.weight*100:.0f}% weight)")

        print("\nKEY STRENGTHS:")
        for s in result.key_strengths:
            print(f"  - {s}")

        if result.critical_blockers:
            print("\nCRITICAL BLOCKERS:")
            for b in result.critical_blockers:
                print(f"  ! {b}")

        print("\nTOP RECOMMENDATIONS:")
        for r in result.recommendations[:5]:
            print(f"  {r.priority}. [{r.roi_assessment} ROI] {r.title}")
            print(f"     Cost: {r.cost_of_implementation} | Timeline: {r.timeline}")

        print("\nPREDICTED PROMPTS THIS SITE COULD ANSWER:")
        for p in result.predicted_prompts:
            print(f"  - {p}")

    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)
