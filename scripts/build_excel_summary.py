"""
Build excel/olist_executive_summary.xlsx from the tables the notebook exports
to data/processed/.  Every what-if number is a live formula driven by two
input cells, so a manager can play with the scenario.

Usage (from the project root):   python scripts/build_excel_summary.py
"""
import os

import pandas as pd
from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.comments import Comment
from openpyxl.formatting.rule import ColorScaleRule, DataBarRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, "data", "processed")
OUT = os.path.join(ROOT, "excel", "olist_executive_summary.xlsx")

# ---------- styles ----------
FONT = "Arial"
f_title = Font(name=FONT, size=16, bold=True, color="0B0B0B")
f_h1 = Font(name=FONT, size=12, bold=True, color="FFFFFF")
f_h2 = Font(name=FONT, size=10, bold=True, color="0B0B0B")
f_body = Font(name=FONT, size=10, color="0B0B0B")
f_muted = Font(name=FONT, size=9, italic=True, color="52514E")
f_input = Font(name=FONT, size=10, bold=True, color="0000FF")       # blue = editable input
f_link = Font(name=FONT, size=10, color="008000")                   # green = pulled from another sheet
f_big = Font(name=FONT, size=18, bold=True, color="1C5CAB")
fill_h1 = PatternFill("solid", fgColor="1C5CAB")
fill_input = PatternFill("solid", fgColor="FFFF00")
fill_soft = PatternFill("solid", fgColor="EAF1FB")
fill_kpi = PatternFill("solid", fgColor="F4F6F9")
thin = Side(style="thin", color="D0D0D0")
border = Border(top=thin, bottom=thin, left=thin, right=thin)
center = Alignment(horizontal="center", vertical="center", wrap_text=True)
left = Alignment(horizontal="left", vertical="center", wrap_text=True)

PCT = "0.0%"
PCT2 = "0.00%"
INT = "#,##0"
DEC1 = "#,##0.0"
DEC2 = "#,##0.00"
BRL = '"R$"#,##0'


def write_table(ws, df, start_row, start_col=1, formats=None, header_fill=fill_h1, widths=None):
    """Write a DataFrame as a formatted table. formats = {column_name: number_format}."""
    formats = formats or {}
    for j, col in enumerate(df.columns):
        c = ws.cell(row=start_row, column=start_col + j, value=str(col))
        c.font = f_h1
        c.fill = header_fill
        c.alignment = center
        c.border = border
    for i, row in enumerate(df.itertuples(index=False), start=1):
        for j, val in enumerate(row):
            if isinstance(val, float) and pd.isna(val):
                val = None
            c = ws.cell(row=start_row + i, column=start_col + j, value=val)
            c.font = f_body
            c.border = border
            fmt = formats.get(df.columns[j])
            if fmt:
                c.number_format = fmt
            c.alignment = left if isinstance(val, str) else Alignment(horizontal="right", vertical="center")
    if widths:
        for j, w in enumerate(widths):
            ws.column_dimensions[get_column_letter(start_col + j)].width = w
    ws.freeze_panes = ws.cell(row=start_row + 1, column=start_col)
    return start_row + len(df)


def pct_cols(df, cols):
    """Convert percentage columns (0-100) to fractions for Excel % formats."""
    df = df.copy()
    for c in cols:
        df[c] = df[c] / 100
    return df


# ---------- load notebook outputs ----------
head = pd.read_csv(f"{P}/summary_headline.csv", index_col=0)["value"]
wi = pd.read_csv(f"{P}/summary_whatif_inputs.csv", index_col=0)["value"]
rescue = pd.read_csv(f"{P}/summary_promise_buffer_rescue.csv")
by_delay = pd.read_csv(f"{P}/summary_by_delay_bucket.csv")
pvs = pd.read_csv(f"{P}/summary_promise_vs_speed.csv")
monthly = pd.read_csv(f"{P}/summary_by_month.csv")
by_state = pd.read_csv(f"{P}/summary_by_state.csv")
routes = pd.read_csv(f"{P}/summary_late_routes.csv")
cat = pd.read_csv(f"{P}/summary_by_category.csv")
coh = pd.read_csv(f"{P}/summary_cohort_retention.csv", index_col=0)
stages = pd.read_csv(f"{P}/summary_delivery_stages.csv")

wb = Workbook()

# =====================================================================
# Sheet 1: Summary
# =====================================================================
ws = wb.active
ws.title = "Summary"
ws.sheet_view.showGridLines = False
for col, w in zip("ABCDEFGH", [40, 22, 4, 4, 54, 18, 4, 4]):
    ws.column_dimensions[col].width = w

ws["A1"] = "Olist e-commerce: why late deliveries cost reviews, and what to fix first"
ws["A1"].font = f_title
ws["A2"] = "96,203 delivered orders, Jan 2017 – Aug 2018 · Source: Brazilian E-Commerce Public Dataset by Olist (Kaggle) · numbers from sql/20_headline_numbers.sql and notebooks/olist_analysis.ipynb"
ws["A2"].font = f_muted
ws.page_setup.orientation = "landscape"
ws.page_setup.fitToWidth = 1
ws.page_setup.fitToHeight = 0
ws.sheet_properties.pageSetUpPr.fitToPage = True

# --- KPI tiles (row 4-5) ---
kpis = [("Delivered orders", head["delivered_orders"], INT),
        ("Revenue (R$)", head["revenue_brl"], BRL),
        ("Orders delivered late", head["pct_late"] / 100, PCT),
        ("Avg review: on time vs late", f"{head['avg_score_on_time']:.2f} vs {head['avg_score_late']:.2f}", None),
        ("1-star rate: on time vs late", f"{head['pct_one_star_on_time']:.1f}% vs {head['pct_one_star_late']:.1f}%", None),
        ("Customers who ever reorder", head["repeat_customer_pct"] / 100, PCT)]
for i, (label, val, fmt) in enumerate(kpis):
    r = 4 + (i // 3) * 3
    c = 1 + (i % 3) * 2 if i % 3 < 2 else 5
    col = [1, 2, 5][i % 3]
    lc = ws.cell(row=r, column=col, value=label); lc.font = f_muted; lc.fill = fill_kpi
    vc = ws.cell(row=r + 1, column=col, value=val); vc.font = f_big if not isinstance(val, str) else Font(name=FONT, size=14, bold=True, color="1C5CAB")
    vc.fill = fill_kpi
    if fmt:
        vc.number_format = fmt
    for cc in (lc, vc):
        cc.alignment = left

# --- Findings ---
r = 11
ws.cell(row=r, column=1, value="What the data says").font = f_h2
findings = [
    f"1. Late delivery drives bad reviews: {head['pct_late']:.1f}% of orders arrive after the promised date but produce {head['pct_of_all_one_stars_from_late_orders']:.0f}% of all 1-star reviews. Average score {head['avg_score_on_time']:.2f} on time vs {head['avg_score_late']:.2f} late.",
    "2. Customers grade the promise, not the speed: a 22-30 day delivery that met its date averages 3.95 stars; the same speed that missed it averages 2.57.",
    f"3. Lateness is concentrated: 12 routes produce 69% of late orders (SP→RJ alone 18%); it spikes in Nov 2017 (12%) and Feb–Mar 2018 (14–19%). In {100 - head['pct_late_orders_seller_shipped_late']:.0f}% of late orders the seller shipped on time — the carrier leg loses ~20 extra days.",
    "4. Multi-item (21.7% 1-star) and multi-seller orders (36.1%) are a second, separate problem — consistent with split or partial deliveries.",
    f"5. Retention is structural: {head['repeat_customer_pct']:.1f}% of customers ever reorder. A late first order lowers that from {wi['repeat_rate_first_order_on_time_pct']:.2f}% to {wi['repeat_rate_first_order_late_pct']:.2f}% — real, but delivery is not the retention lever.",
]
for i, t in enumerate(findings, start=1):
    c = ws.cell(row=r + i, column=1, value=t); c.font = f_body; c.alignment = left
    ws.merge_cells(start_row=r + i, start_column=1, end_row=r + i, end_column=7)
    ws.row_dimensions[r + i].height = 30

# --- What-if block ---
r = 18
ws.cell(row=r, column=1, value="What-if: how much is worth fixing?").font = f_h2
ws.cell(row=r, column=5, value="Legend: yellow cells with blue text are the only inputs to change. Everything else is a formula.").font = f_muted

# Reference data (column A/B)
ref = [("Annual delivered orders (20-month window annualised)", wi["annual_delivered_orders"], INT, "96,203 orders / 20 months × 12"),
       ("Current late share", wi["current_late_share_pct"] / 100, PCT2, "sql/20_headline_numbers.sql"),
       ("1-star rate, late orders", wi["one_star_rate_late_pct"] / 100, PCT, "sql/20_headline_numbers.sql"),
       ("1-star rate, on-time orders", wi["one_star_rate_on_time_pct"] / 100, PCT, "sql/20_headline_numbers.sql"),
       ("Avg review score, late orders", wi["avg_score_late"], DEC2, "sql/20_headline_numbers.sql"),
       ("Avg review score, on-time orders", wi["avg_score_on_time"], DEC2, "sql/20_headline_numbers.sql"),
       ("Repeat rate after a late first order", wi["repeat_rate_first_order_late_pct"] / 100, PCT2, "sql/17_repeat_purchase.sql"),
       ("Repeat rate after an on-time first order", wi["repeat_rate_first_order_on_time_pct"] / 100, PCT2, "sql/17_repeat_purchase.sql"),
       ("Average order value (R$)", wi["avg_order_value_brl"], DEC2, "sql/20_headline_numbers.sql"),
       ("Revenue sitting in late orders, 20 months (R$)", wi["revenue_in_late_orders_brl"], BRL, "sql/20_headline_numbers.sql")]
ws.cell(row=r + 1, column=1, value="Reference data (from the analysis)").font = f_h2
for i, (label, val, fmt, src) in enumerate(ref, start=2):
    ws.cell(row=r + i, column=1, value=label).font = f_body
    c = ws.cell(row=r + i, column=2, value=float(val)); c.font = f_body; c.number_format = fmt; c.fill = fill_soft
    c.comment = Comment(f"Source: {src}", "analysis")
# cell map for formulas
A_ORD, A_LATE, A_1S_L, A_1S_O, A_SC_L, A_SC_O, A_RP_L, A_RP_O, A_AOV, A_REV = [f"$B${r + i}" for i in range(2, 12)]

# Inputs (column E/F)
ws.cell(row=r + 1, column=5, value="Inputs — change these").font = f_h2
inputs = [("Scenario A: target late share after the carrier fix", 0.035, PCT2),
          ("Scenario B: promise buffer added (days, 1–14)", 7, "0"),
          ("Scenario B: scope — 1 = 12 worst routes, 2 = those routes + Nov–Mar everywhere, 3 = all orders", 1, "0")]
for i, (label, val, fmt) in enumerate(inputs, start=2):
    ws.cell(row=r + i, column=5, value=label).font = f_body
    c = ws.cell(row=r + i, column=6, value=val); c.font = f_input; c.fill = fill_input; c.number_format = fmt; c.border = border
I_TARGET, I_BUFFER, I_SCOPE = f"$F${r + 2}", f"$F${r + 3}", f"$F${r + 4}"

# Scenario A outputs
ra = r + 6
ws.cell(row=ra, column=5, value="Scenario A — cut the late share (carrier SLA on the worst routes)").font = f_h2
scen_a = [("Orders per year moved from late to on time", f"={A_ORD}*MAX(0,{A_LATE}-{I_TARGET})", INT),
          ("1-star reviews avoided per year", f"=F{ra + 1}*({A_1S_L}-{A_1S_O})", INT),
          ("Platform average review score: today", f"=(1-{A_LATE})*{A_SC_O}+{A_LATE}*{A_SC_L}", DEC2),
          ("Platform average review score: after", f"=(1-{I_TARGET})*{A_SC_O}+{I_TARGET}*{A_SC_L}", DEC2),
          ("Extra repeat customers per year", f"=F{ra + 1}*({A_RP_O}-{A_RP_L})", DEC1),
          ("Revenue from those repeat orders (R$ / year)", f"=F{ra + 5}*{A_AOV}", BRL)]
for i, (label, formula, fmt) in enumerate(scen_a, start=1):
    ws.cell(row=ra + i, column=5, value=label).font = f_body
    c = ws.cell(row=ra + i, column=6, value=formula); c.font = f_body; c.number_format = fmt; c.border = border

# Scenario B outputs (lookup into the buffer table)
rb = ra + 8
ws.cell(row=rb, column=5, value="Scenario B — make the promise route-aware (zero logistics cost)").font = f_h2
scen_b = [("Share of today's late orders that would become on time", f"=INDEX('Promise buffer'!$B$2:$D$15, MATCH({I_BUFFER}, 'Promise buffer'!$A$2:$A$15, 0), {I_SCOPE})", PCT),
          ("Late orders rescued per year", f"={A_ORD}*{A_LATE}*F{rb + 1}", INT),
          ("1-star reviews avoided per year", f"=F{rb + 2}*({A_1S_L}-{A_1S_O})", INT),
          ("Late share after the change", f"={A_LATE}*(1-F{rb + 1})", PCT2),
          ("Platform average review score: after", f"=(1-F{rb + 4})*{A_SC_O}+F{rb + 4}*{A_SC_L}", DEC2)]
for i, (label, formula, fmt) in enumerate(scen_b, start=1):
    ws.cell(row=rb + i, column=5, value=label).font = f_body
    c = ws.cell(row=rb + i, column=6, value=formula); c.font = f_body; c.number_format = fmt; c.border = border
ws.cell(row=rb + 7, column=5, value="Assumption for B: a late order that falls inside a longer promise behaves like an on-time order (supported by the 'Promise vs speed' sheet, but it is correlational — A/B test before rolling out, and watch conversion on the longer promise).").font = f_muted
ws.merge_cells(start_row=rb + 7, start_column=5, end_row=rb + 7, end_column=6)
ws.cell(row=rb + 7, column=5).alignment = left
ws.row_dimensions[rb + 7].height = 64

# Recommendation
rr = rb + 9
ws.cell(row=rr, column=1, value="Recommendation (cheapest first)").font = f_h2
recs = ["1. Make the delivery promise route-aware: a 7-day buffer on the 12 worst routes rescues 40% of late orders (≈730 fewer 1-star reviews a year); with the Nov–Mar peak added, 49%; everywhere, 56%. Zero logistics cost — A/B test it against conversion.",
        "2. Put a carrier SLA on deliveries to Rio de Janeiro and the nine Northeast states — 22% of orders but 40% of the late ones (12.4% late rate vs 4.5% in São Paulo).",
        "3. Investigate split/partial deliveries on multi-item orders (1-star reviews 2.5× as often as single-item orders; 4.1× for multi-seller orders).",
        "4. Stop treating delivery as a retention lever; measure it on review score and 1-star rate."]
for i, t in enumerate(recs, start=1):
    c = ws.cell(row=rr + i, column=1, value=t); c.font = f_body; c.alignment = left
    ws.merge_cells(start_row=rr + i, start_column=1, end_row=rr + i, end_column=7)

# =====================================================================
# Sheet: Promise buffer (lookup table for scenario B)
# =====================================================================
wsb = wb.create_sheet("Promise buffer")
cols = {"buffer_days": "Buffer days added", "pct_rescued_12_worst_routes": "Rescued: 12 worst routes only", "pct_rescued_routes_plus_nov_mar": "Rescued: routes + Nov–Mar",
        "pct_rescued_all_orders": "Rescued: all orders", "one_star_avoided_per_year_12_worst_routes": "1-star avoided / yr: 12 routes",
        "one_star_avoided_per_year_routes_plus_nov_mar": "1-star avoided / yr: routes + Nov–Mar", "one_star_avoided_per_year_all_orders": "1-star avoided / yr: all orders"}
tbl = rescue[list(cols)].rename(columns=cols)
tbl = pct_cols(tbl, ["Rescued: 12 worst routes only", "Rescued: routes + Nov–Mar", "Rescued: all orders"])
write_table(wsb, tbl, 1, formats={"Rescued: 12 worst routes only": PCT, "Rescued: routes + Nov–Mar": PCT, "Rescued: all orders": PCT, "1-star avoided / yr: 12 routes": INT,
                                  "1-star avoided / yr: routes + Nov–Mar": INT, "1-star avoided / yr: all orders": INT}, widths=[14, 20, 20, 16, 20, 24, 20])
wsb.cell(row=17, column=1, value="Rescued = share of ALL 6,531 late orders whose delay was ≤ the buffer AND that fall inside the scope (the 12 worst seller→customer routes; those routes plus every order bought Nov–Mar; or every order). Yearly counts use the annualised volume on the Summary sheet.").font = f_muted
wsb.merge_cells("A17:G17"); wsb.row_dimensions[17].height = 40

# =====================================================================
# Sheet: Delay vs reviews
# =====================================================================
wsd = wb.create_sheet("Delay vs reviews")
t = by_delay.rename(columns={"delay_bucket": "Delivery vs promise", "orders": "Orders", "pct_of_orders": "% of orders", "avg_score": "Avg review score",
                             "pct_one_star": "% 1-star", "pct_4_5": "% 4-5 star", "revenue": "Revenue (R$)"})
t = pct_cols(t, ["% of orders", "% 1-star", "% 4-5 star"])[["Delivery vs promise", "Orders", "% of orders", "Avg review score", "% 1-star", "% 4-5 star", "Revenue (R$)"]]
end = write_table(wsd, t, 1, formats={"Orders": INT, "% of orders": PCT, "Avg review score": DEC2, "% 1-star": PCT, "% 4-5 star": PCT, "Revenue (R$)": BRL}, widths=[26, 12, 12, 16, 12, 12, 16])
wsd.conditional_formatting.add(f"E2:E{end}", ColorScaleRule(start_type="min", start_color="FFFFFF", end_type="max", end_color="E34948"))
wsd.conditional_formatting.add(f"D2:D{end}", ColorScaleRule(start_type="min", start_color="FFFFFF", end_type="max", end_color="2A78D6"))
ch = BarChart(); ch.type = "col"; ch.title = "Average review score by delivery vs promise"; ch.y_axis.title = "Avg score"; ch.style = 10
ch.add_data(Reference(wsd, min_col=4, min_row=1, max_row=end), titles_from_data=True)
ch.set_categories(Reference(wsd, min_col=1, min_row=2, max_row=end)); ch.height = 8; ch.width = 18; ch.legend = None
wsd.add_chart(ch, "I2")

# =====================================================================
# Sheet: Promise vs speed
# =====================================================================
wsp = wb.create_sheet("Promise vs speed")
t = pvs.rename(columns={"speed_bucket": "Actual delivery time", "avg_score_on_time": "Avg score: met promise", "avg_score_late": "Avg score: missed promise",
                        "orders_on_time": "Orders: met promise", "orders_late": "Orders: missed promise", "score_gap": "Gap"})
t = t[["Actual delivery time", "Orders: met promise", "Orders: missed promise", "Avg score: met promise", "Avg score: missed promise", "Gap"]]
end = write_table(wsp, t, 1, formats={"Orders: met promise": INT, "Orders: missed promise": INT, "Avg score: met promise": DEC2, "Avg score: missed promise": DEC2, "Gap": DEC2}, widths=[22, 18, 20, 20, 22, 10])
wsp.cell(row=end + 2, column=1, value="Read across a row: same delivery speed, very different scores depending on whether the promised date was met. The 60+ days row has only 2 on-time orders.").font = f_muted
wsp.merge_cells(start_row=end + 2, start_column=1, end_row=end + 2, end_column=6)

# =====================================================================
# Sheet: By month
# =====================================================================
wsm = wb.create_sheet("By month")
t = monthly.rename(columns={"order_month": "Month", "orders": "Orders", "revenue": "Revenue (R$)", "pct_late": "% late", "avg_score": "Avg review score",
                            "pct_one_star": "% 1-star", "avg_delivery_days": "Avg delivery days"})
t = pct_cols(t, ["% late", "% 1-star"])
end = write_table(wsm, t, 1, formats={"Orders": INT, "Revenue (R$)": BRL, "% late": PCT, "Avg review score": DEC2, "% 1-star": PCT, "Avg delivery days": DEC1}, widths=[12, 10, 16, 10, 16, 10, 16])
wsm.conditional_formatting.add(f"D2:D{end}", DataBarRule(start_type="num", start_value=0, end_type="max", color="E34948"))
lc = LineChart(); lc.title = "% of orders delivered late, by month"; lc.style = 12; lc.height = 8; lc.width = 20; lc.legend = None
lc.add_data(Reference(wsm, min_col=4, min_row=1, max_row=end), titles_from_data=True)
lc.set_categories(Reference(wsm, min_col=1, min_row=2, max_row=end)); lc.y_axis.number_format = "0%"
wsm.add_chart(lc, "I2")

# =====================================================================
# Sheet: By state
# =====================================================================
wss = wb.create_sheet("By state")
t = by_state.rename(columns={"customer_state": "State", "state_name": "State name", "region": "Region", "orders": "Orders", "revenue": "Revenue (R$)",
                             "pct_late": "% late", "late_orders": "Late orders", "share_of_late_orders": "Share of all late orders",
                             "avg_delivery_days": "Avg delivery days", "avg_promised_days": "Avg promised days", "avg_score": "Avg review score", "pct_one_star": "% 1-star"})
t = pct_cols(t, ["% late", "Share of all late orders", "% 1-star"])
t = t[["State", "State name", "Region", "Orders", "Revenue (R$)", "% late", "Late orders", "Share of all late orders", "Avg delivery days", "Avg promised days", "Avg review score", "% 1-star"]]
end = write_table(wss, t, 1, formats={"Orders": INT, "Revenue (R$)": BRL, "% late": PCT, "Late orders": INT, "Share of all late orders": PCT, "Avg delivery days": DEC1,
                                      "Avg promised days": DEC1, "Avg review score": DEC2, "% 1-star": PCT}, widths=[8, 20, 14, 10, 15, 9, 11, 14, 12, 12, 12, 9])
wss.conditional_formatting.add(f"F2:F{end}", DataBarRule(start_type="num", start_value=0, end_type="max", color="E34948"))
wss.conditional_formatting.add(f"K2:K{end}", ColorScaleRule(start_type="min", start_color="F8CFCB", end_type="max", end_color="FFFFFF"))

# =====================================================================
# Sheet: Late routes
# =====================================================================
wsr = wb.create_sheet("Late routes")
t = routes.head(20).rename(columns={"route": "Route (seller state → customer state)", "orders": "Orders", "late_orders": "Late orders", "pct_late": "% late",
                                    "cum_pct_of_late_orders": "Cumulative share of all late orders", "avg_delivery_days": "Avg delivery days",
                                    "avg_promised_days": "Avg promised days", "avg_score": "Avg review score"})
t = pct_cols(t, ["% late", "Cumulative share of all late orders"])
t = t[["Route (seller state → customer state)", "Orders", "Late orders", "% late", "Cumulative share of all late orders", "Avg delivery days", "Avg promised days", "Avg review score"]]
end = write_table(wsr, t, 1, formats={"Orders": INT, "Late orders": INT, "% late": PCT, "Cumulative share of all late orders": PCT, "Avg delivery days": DEC1, "Avg promised days": DEC1, "Avg review score": DEC2},
                  widths=[34, 10, 12, 9, 22, 14, 14, 14])
wsr.conditional_formatting.add(f"D2:D{end}", DataBarRule(start_type="num", start_value=0, end_type="max", color="E34948"))

# =====================================================================
# Sheet: Categories
# =====================================================================
wsc = wb.create_sheet("Categories")
t = cat.head(20).rename(columns={"category": "Category", "orders": "Orders", "items_sold": "Items sold", "revenue": "Revenue (R$)", "pct_of_revenue": "% of revenue",
                                 "freight_pct_of_price": "Freight as % of price", "pct_late": "% late", "avg_score": "Avg review score", "pct_one_star": "% 1-star"})
t = pct_cols(t, ["% of revenue", "Freight as % of price", "% late", "% 1-star"])
t = t[["Category", "Orders", "Items sold", "Revenue (R$)", "% of revenue", "Freight as % of price", "% late", "Avg review score", "% 1-star"]]
end = write_table(wsc, t, 1, formats={"Orders": INT, "Items sold": INT, "Revenue (R$)": BRL, "% of revenue": PCT, "Freight as % of price": PCT, "% late": PCT, "Avg review score": DEC2, "% 1-star": PCT},
                  widths=[26, 10, 10, 16, 12, 16, 9, 14, 9])
wsc.conditional_formatting.add(f"D2:D{end}", DataBarRule(start_type="num", start_value=0, end_type="max", color="2A78D6"))

# =====================================================================
# Sheet: Cohorts
# =====================================================================
wsh = wb.create_sheet("Cohorts")
t = coh.reset_index().rename(columns={"cohort_month": "Acquisition month"})
for c in t.columns[1:]:
    t[c] = t[c] / 100
end = write_table(wsh, t, 1, formats={c: PCT2 for c in t.columns[1:]}, widths=[18] + [10] * (t.shape[1] - 1))
wsh.conditional_formatting.add(f"B2:{get_column_letter(t.shape[1])}{end}", ColorScaleRule(start_type="min", start_color="FFFFFF", end_type="max", end_color="2A78D6"))
wsh.cell(row=end + 2, column=1, value="% of each month's new customers who placed another order N months later. Cohorts shown have at least 6 months of follow-up.").font = f_muted
wsh.merge_cells(start_row=end + 2, start_column=1, end_row=end + 2, end_column=7)

# =====================================================================
# Sheet: Notes
# =====================================================================
wsn = wb.create_sheet("Notes")
wsn.column_dimensions["A"].width = 30; wsn.column_dimensions["B"].width = 100
notes = [("Dataset", "Brazilian E-Commerce Public Dataset by Olist — https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce (CC BY-NC-SA 4.0)"),
         ("Analysis population", "Orders with status 'delivered', a delivery date, purchased 1 Jan 2017 – 31 Aug 2018 (20 full months): 96,203 orders, 93,096 customers."),
         ("Late / delay days", "delay_days = delivered date − promised (estimated) date in calendar days. Late = delay_days > 0."),
         ("Delivery days", "Purchase timestamp → delivered timestamp. Promised days = purchase → estimated delivery date."),
         ("Seller handling / carrier transit", "Approved → handed to carrier, and handed to carrier → delivered."),
         ("Revenue", "Sum of item prices (R$). Freight is reported separately."),
         ("Review score", "Latest review for the order (555 orders have two)."),
         ("Repeat customer", "customer_unique_id with 2+ delivered orders in the window."),
         ("Legend", "Yellow cells with blue text = inputs you can change. Blue-shaded cells = reference data from the analysis (with a comment naming the SQL file). Black = formulas."),
         ("Reproduce", "sql/01..04 build the MySQL schema and fact table; sql/10..20 are the analysis queries; notebooks/olist_analysis.ipynb produces every table in this workbook; scripts/build_excel_summary.py builds the file.")]
for i, (k, v) in enumerate(notes, start=1):
    a = wsn.cell(row=i, column=1, value=k); a.font = f_h2; a.alignment = left
    b = wsn.cell(row=i, column=2, value=v); b.font = f_body; b.alignment = left
    wsn.row_dimensions[i].height = 32

os.makedirs(os.path.dirname(OUT), exist_ok=True)
wb.save(OUT)
print("saved", os.path.relpath(OUT, ROOT))
