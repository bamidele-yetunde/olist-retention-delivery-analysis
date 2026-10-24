"""
Build docs/insights_memo.pdf - the one-page stakeholder memo.
Usage (from the project root):  python scripts/build_memo.py
"""
import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import Image, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle, KeepTogether

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "insights_memo.pdf")
IMG = os.path.join(ROOT, "images", "01_review_score_vs_delay.png")

INK, INK2, BLUE, SOFT = colors.HexColor("#0B0B0B"), colors.HexColor("#52514E"), colors.HexColor("#1C5CAB"), colors.HexColor("#EAF1FB")
base = ParagraphStyle("base", fontName="Helvetica", fontSize=9, leading=11.4, textColor=INK, alignment=TA_LEFT)
title = ParagraphStyle("title", parent=base, fontName="Helvetica-Bold", fontSize=15, leading=18, textColor=INK)
sub = ParagraphStyle("sub", parent=base, fontSize=8.5, textColor=INK2)
h = ParagraphStyle("h", parent=base, fontName="Helvetica-Bold", fontSize=10, leading=13, textColor=BLUE, spaceBefore=6, spaceAfter=2)
bullet = ParagraphStyle("bullet", parent=base, leftIndent=9, bulletIndent=0, spaceAfter=1.5)
kpi_v = ParagraphStyle("kpi_v", parent=base, fontName="Helvetica-Bold", fontSize=11.5, leading=14, textColor=BLUE)
kpi_l = ParagraphStyle("kpi_l", parent=base, fontSize=7.5, leading=9, textColor=INK2)
foot = ParagraphStyle("foot", parent=base, fontSize=7.5, leading=9.5, textColor=INK2)

doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=16 * mm, rightMargin=16 * mm, topMargin=13 * mm, bottomMargin=11 * mm,
                        title="Olist delivery & reviews - insights memo", author="Ideraoluwa")
story = []
story += [Paragraph("Olist: late deliveries are costing reviews — and the cheapest fix", title),
          Paragraph("Insights memo · 96,203 delivered orders, Jan 2017 – Aug 2018 · Brazilian E-Commerce Public Dataset by Olist (Kaggle) · Prepared by Ideraoluwa, Data Analyst", sub),
          Spacer(1, 5)]

story += [Paragraph("Bottom line", h),
          Paragraph("Only <b>6.8%</b> of orders arrive after the promised date, but they generate <b>37% of all 1-star reviews</b>. Customers judge the "
                    "<i>promise</i>, not the speed: an order that takes 22–30 days still scores 3.95 if it meets its date and 2.57 if it misses it. "
                    "Lateness is concentrated on a dozen routes and two periods, and in 72% of cases the seller shipped on time — the carrier leg is where the "
                    "time is lost. The cheapest fix is a route-aware delivery promise; the second is a carrier SLA on Rio de Janeiro and the Northeast. "
                    "Delivery is <b>not</b> a retention lever: 97% of customers never reorder regardless.", base)]

kpis = [("96,203", "delivered orders"), ("6.8%", "delivered late"), ("4.28 vs 2.26", "avg review: on time vs late"),
        ("6.8% vs 54.2%", "1-star rate: on time vs late"), ("37%", "of 1-star reviews come from late orders"), ("3.0%", "of customers ever reorder")]
cells = [[Paragraph(v, kpi_v) for v, _ in kpis], [Paragraph(l, kpi_l) for _, l in kpis]]
kt = Table(cells, colWidths=[29.5 * mm] * 6)
kt.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), SOFT), ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ("TOPPADDING", (0, 0), (-1, 0), 5), ("BOTTOMPADDING", (0, 1), (-1, 1), 5), ("LEFTPADDING", (0, 0), (-1, -1), 5)]))
story += [Spacer(1, 5), kt, Spacer(1, 3)]

story += [Paragraph("What the data says", h)]
findings = [
    "<b>A missed promise turns a 4.3-star experience into a 1-star one.</b> 1–3 days late: avg score 3.28, 25% 1-star. 4–7 days late: 2.09, 59% 1-star. "
    "Past a week: ~1.7, 70% 1-star. Only 6.8% of orders arrive late, but they produce 37% of all 1-star reviews (54% of late orders get 1 star vs 7% of on-time orders).",
    "<b>The promise matters more than the speed.</b> At every delivery-time band, orders that met the promised date score 0.5–1.8 stars higher than orders of the same speed that missed it. "
    "The estimate is padded by ~12 days on average, yet it is the <i>same</i> padding everywhere — so it fails exactly where transit is slow.",
    "<b>Lateness is concentrated.</b> 12 seller→customer routes produce 69% of late orders (SP→RJ alone 18%, late 14% of the time). Deliveries to Rio de Janeiro and the nine Northeast states are 22% of orders but 40% of late ones. "
    "The late rate spikes in Nov 2017 (12%) and Feb–Mar 2018 (14–19%). Late orders spend 28 days in carrier transit vs 8 for on-time orders; seller handling only grows from 2.6 to 5.5 days.",
    "<b>Multi-item orders are a second problem.</b> Orders with 2+ items get 1 star 2.5× as often (21.7% vs 8.7%), orders split across sellers 36% — although they are <i>less</i> often late. Consistent with split or partial deliveries.",
    "<b>Retention is structural.</b> 97.0% of customers never place a second order. A late first order lowers the repeat rate from 3.03% to 2.52% — real but small — and the first order's review score does not predict a return at all.",
]
story += [Paragraph(f, bullet, bulletText="•") for f in findings]

story += [Paragraph("Recommendation, cheapest first", h)]
recs = [
    "<b>Make the delivery promise route-aware.</b> A 7-day buffer on the 12 worst routes alone would have turned 40% of all late orders into on-time ones — ≈ 1,550 orders and ≈ 730 fewer 1-star reviews a year; "
    "with the Nov–Mar peak added on every route, 49% (≈ 900 reviews); applied everywhere, 56% (≈ 1,040), lifting the platform average from 4.14 to 4.22. Zero logistics cost — A/B test it against checkout conversion.",
    "<b>Carrier SLA on deliveries to Rio de Janeiro and the Northeast.</b> Cutting the overall late share from 6.8% to 3.5% moves ≈ 1,900 orders a year on time and avoids ≈ 900 1-star reviews.",
    "<b>Investigate split deliveries on multi-item orders</b> (1-star reviews 2.5× as often, 4.1× for multi-seller orders), and <b>stop measuring delivery as a retention lever</b> — measure it on review score and 1-star rate.",
]
story += [Paragraph(r, bullet, bulletText=str(i + 1) + ".") for i, r in enumerate(recs)]

img = Image(IMG, width=140 * mm, height=140 * mm * 837 / 1906)
story += [Spacer(1, 4), KeepTogether([img])]

story += [Spacer(1, 3),
          Paragraph("Method: MySQL 8 (schema, 11 analysis queries), Python (pandas, matplotlib), Power BI (5-page dashboard, star schema, DAX), Excel (what-if model). "
                    "Late = delivered after the estimated date; revenue = item price; review = latest per order. Limits: review effects are correlational; carrier costs and Olist's take rate are not in the data. "
                    "Full repository: github.com/[your-handle]/olist-retention-delivery-analysis", foot)]

doc.build(story)
print("saved", os.path.relpath(OUT, ROOT))
