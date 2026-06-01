from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph,
    Spacer, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from datetime import datetime
import io

# OVG Brand Colors
DARK_BLUE = colors.HexColor("#1A1A2E")
ACCENT_BLUE = colors.HexColor("#4F8EF7")
LIGHT_GRAY = colors.HexColor("#F7F8FC")
TEXT_GRAY = colors.HexColor("#6B7280")
WHITE = colors.white
BORDER_GRAY = colors.HexColor("#E5E7EB")


def generate_invoice_pdf(invoice: dict) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4,
        rightMargin=15 * mm, leftMargin=15 * mm,
        topMargin=10 * mm, bottomMargin=15 * mm
    )

    styles = getSampleStyleSheet()
    story = []

    # ── Header ──────────────────────────────────────────────────────────────
    header_data = [
        [
            Paragraph(
                '<font size="18" color="#1A1A2E"><b>OM VINAYAKA GARMENTS</b></font><br/>'
                '<font size="8" color="#6B7280">SF No:252/1, Merkalath Thottam, Balaji Nagar,<br/>'
                'Poyampalayam, Pooluvapatti (PO), TUP - 2.</font>',
                ParagraphStyle('hdr', alignment=TA_LEFT)
            ),
            Paragraph(
                f'<font size="20" color="#4F8EF7"><b>INVOICE</b></font><br/>'
                f'<font size="9" color="#6B7280">Invoice No: </font>'
                f'<font size="9" color="#1A1A2E"><b>{invoice.get("invoice_number", "")}</b></font><br/>'
                f'<font size="8" color="#6B7280">Date: {datetime.fromisoformat(invoice["created_at"]).strftime("%d-%m-%Y") if isinstance(invoice.get("created_at"), str) else datetime.now().strftime("%d-%m-%Y")}</font>',
                ParagraphStyle('inv_num', alignment=TA_RIGHT)
            )
        ]
    ]
    header_table = Table(header_data, colWidths=[100 * mm, 75 * mm])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(header_table)

    # Contact row
    contact_data = [[
        Paragraph(
            '<font size="7.5" color="#6B7280">Cell: 9790052254, 8012552257 &nbsp;|&nbsp; '
            'GST: 33BHNPS9629C1ZZ &nbsp;|&nbsp; Email: idealovg@gmail.com &nbsp;|&nbsp; '
            'Web: www.idealinnerwear.in</font>',
            ParagraphStyle('contact', alignment=TA_LEFT)
        )
    ]]
    contact_table = Table(contact_data, colWidths=[180 * mm])
    story.append(contact_table)

    story.append(HRFlowable(width="100%", thickness=2, color=ACCENT_BLUE, spaceAfter=6))

    # ── Bill To ──────────────────────────────────────────────────────────────
    bill_to = [
        [
            Paragraph('<font size="8" color="#6B7280"><b>BILL TO</b></font>', ParagraphStyle('lbl', alignment=TA_LEFT)),
            Paragraph('<font size="8" color="#6B7280"><b>PAYMENT MODE</b></font>', ParagraphStyle('lbl', alignment=TA_LEFT)),
        ],
        [
            Paragraph(
                f'<font size="11" color="#1A1A2E"><b>{invoice.get("customer_name", "")}</b></font><br/>'
                f'<font size="9" color="#6B7280">{invoice.get("customer_mobile", "")}</font><br/>'
                f'<font size="8" color="#6B7280">{invoice.get("customer_address", "")}</font>',
                ParagraphStyle('cust', alignment=TA_LEFT)
            ),
            Paragraph(
                f'<font size="11" color="#1A1A2E"><b>{invoice.get("payment_mode", "Cash")}</b></font>',
                ParagraphStyle('pay', alignment=TA_LEFT)
            )
        ]
    ]
    bill_to_table = Table(bill_to, colWidths=[120 * mm, 55 * mm])
    bill_to_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), LIGHT_GRAY),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('ROUNDEDCORNERS', [3, 3, 3, 3]),
    ]))
    story.append(bill_to_table)
    story.append(Spacer(1, 6))

    # ── Items Table ──────────────────────────────────────────────────────────
    col_headers = ['S.No', 'Product', 'HSN', 'Size', 'Qty', 'Rate', 'Disc%', 'Taxable', 'CGST\n2.5%', 'SGST\n2.5%', 'Total']
    table_data = [col_headers]

    for idx, item in enumerate(invoice.get("items", []), 1):
        table_data.append([
            str(idx),
            f'{item["product_name"]}\n({item.get("quality", "")} | {item.get("category", "")})',
            item.get("hsn_code", "61112000"),
            item.get("size", ""),
            str(item.get("quantity", 0)),
            f'₹{item.get("rate", 0):.2f}',
            f'{item.get("discount_percent", 0)}%',
            f'₹{item.get("taxable_amount", 0):.2f}',
            f'₹{item.get("cgst_amount", 0):.2f}',
            f'₹{item.get("sgst_amount", 0):.2f}',
            f'₹{item.get("total_amount", 0):.2f}',
        ])

    col_widths = [9*mm, 38*mm, 18*mm, 16*mm, 10*mm, 16*mm, 12*mm, 18*mm, 14*mm, 14*mm, 18*mm]
    items_table = Table(table_data, colWidths=col_widths, repeatRows=1)
    items_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK_BLUE),
        ('TEXTCOLOR', (0, 0), (-1, 0), WHITE),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 7.5),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('ALIGN', (1, 1), (1, -1), 'LEFT'),
        ('FONTSIZE', (0, 1), (-1, -1), 7.5),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [WHITE, LIGHT_GRAY]),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER_GRAY),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(items_table)
    story.append(Spacer(1, 6))

    # ── Totals ──────────────────────────────────────────────────────────────
    totals_data = [
        ['', '', '', '', '', '', '', '', 'Sub Total:', f'₹{invoice.get("subtotal", 0):.2f}'],
        ['', '', '', '', '', '', '', '', 'CGST (2.5%):', f'₹{invoice.get("total_cgst", 0):.2f}'],
        ['', '', '', '', '', '', '', '', 'SGST (2.5%):', f'₹{invoice.get("total_sgst", 0):.2f}'],
        ['', '', '', '', '', '', '', '', 'GRAND TOTAL:', f'₹{invoice.get("grand_total", 0):.2f}'],
    ]
    total_col_widths = [9*mm, 38*mm, 18*mm, 16*mm, 10*mm, 16*mm, 12*mm, 18*mm, 24*mm, 22*mm]
    totals_table = Table(totals_data, colWidths=total_col_widths)
    totals_table.setStyle(TableStyle([
        ('ALIGN', (8, 0), (-1, -1), 'RIGHT'),
        ('FONTNAME', (8, 3), (-1, 3), 'Helvetica-Bold'),
        ('FONTSIZE', (8, 0), (-1, -1), 9),
        ('BACKGROUND', (8, 3), (-1, 3), ACCENT_BLUE),
        ('TEXTCOLOR', (8, 3), (-1, 3), WHITE),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LINEABOVE', (8, 3), (-1, 3), 1, ACCENT_BLUE),
    ]))
    story.append(totals_table)

    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=0.5, color=BORDER_GRAY, spaceAfter=6))

    # ── Bank Details + Terms ──────────────────────────────────────────────────
    footer_data = [[
        Paragraph(
            '<font size="8" color="#1A1A2E"><b>BANK DETAILS</b></font><br/>'
            '<font size="7.5" color="#6B7280">Bank: Indian Overseas Bank<br/>'
            'A/C No: 009502000006400<br/>'
            'IFSC: IOBA0000095<br/>'
            'A/C Name: Om Vinayaka Garments</font>',
            ParagraphStyle('bank', alignment=TA_LEFT)
        ),
        Paragraph(
            '<font size="8" color="#1A1A2E"><b>TERMS & CONDITIONS</b></font><br/>'
            '<font size="7.5" color="#6B7280">1. 100% Advance Payment<br/>'
            '2. GST 5% Extra<br/>'
            '3. Transport - To Pay Mode</font>',
            ParagraphStyle('terms', alignment=TA_LEFT)
        ),
        Paragraph(
            '<font size="8" color="#1A1A2E"><b>AUTHORIZED SIGNATORY</b></font><br/><br/><br/>'
            '<font size="7.5" color="#1A1A2E">Om Vinayaka Garments</font>',
            ParagraphStyle('sig', alignment=TA_RIGHT)
        ),
    ]]
    footer_table = Table(footer_data, colWidths=[65*mm, 65*mm, 47*mm])
    footer_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(footer_table)

    doc.build(story)
    return buffer.getvalue()
