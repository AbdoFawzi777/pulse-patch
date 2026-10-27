#!/usr/bin/env python3
"""
tools/add_outside_box.py
Augments the generated pulse_patch_erd.svg and pulse_patch_erd.png with a clear,
styled separate box labeled 'OUTSIDE THE DATABASE (Hardware, Transport & File Assets)'.
Also generates docs/erd/pulse_patch_erd.pdf (A4 landscape).
"""

import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import fitz  # PyMuPDF

def augment_svg():
    svg_path = Path("docs/erd/pulse_patch_erd.svg")
    content = svg_path.read_text(encoding="utf-8")

    # Match viewBox: viewBox="4 4 2406.57421875 1032.5"
    m = re.search(r'viewBox="([0-9\.\-]+)\s+([0-9\.\-]+)\s+([0-9\.\-]+)\s+([0-9\.\-]+)"', content)
    if not m:
        print("viewBox not found in SVG")
        return

    min_x, min_y, width, height = float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4))

    # We add 260px height at the bottom for the "Outside the Database" box
    extra_height = 240.0
    new_height = height + extra_height

    content = content.replace(m.group(0), f'viewBox="{min_x} {min_y} {width} {new_height}"')
    
    # Update max-width / height attributes if present
    content = re.sub(r'style="max-width:\s*[0-9\.]+px;', f'style="max-width: {width}px;', content)

    # Box coordinates
    box_x = min_x + 30
    box_y = height + 20
    box_w = width - 60
    box_h = 200

    outside_svg_fragment = f"""
    <!-- OUTSIDE THE DATABASE CALLOUT BOX -->
    <g id="outside-the-database" transform="translate({box_x}, {box_y})">
        <rect x="0" y="0" width="{box_w}" height="{box_h}" rx="12" ry="12" 
              fill="#F8FAFC" stroke="#64748B" stroke-width="2" stroke-dasharray="8 6"/>
        
        <rect x="16" y="-14" width="340" height="28" rx="6" ry="6" fill="#0B1840"/>
        <text x="30" y="5" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#22D3EE">
            OUTSIDE THE DATABASE (Non-Relational Assets)
        </text>

        <!-- Item 1: Hardware -->
        <g transform="translate(30, 36)">
            <rect x="0" y="0" width="540" height="65" rx="8" ry="8" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="1.5"/>
            <text x="16" y="24" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#0F172A">
                Embedded Hardware Module
            </text>
            <text x="16" y="46" font-family="Arial, sans-serif" font-size="11" fill="#475569">
                ESP32-C3 RISC-V + MAX30102 Optical PPG (3.3V, I2C GPIO4/5 @ 400kHz)
            </text>
        </g>

        <!-- Item 2: Transport -->
        <g transform="translate(600, 36)">
            <rect x="0" y="0" width="540" height="65" rx="8" ry="8" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="1.5"/>
            <text x="16" y="24" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#0F172A">
                Over-The-Air BLE GATT Stream
            </text>
            <text x="16" y="46" font-family="Arial, sans-serif" font-size="11" fill="#475569">
                12-Byte Little-Endian Heart Rate Notification Packet (1 Hz, protocol v1)
            </text>
        </g>

        <!-- Item 3: ML Weights -->
        <g transform="translate(30, 115)">
            <rect x="0" y="0" width="540" height="65" rx="8" ry="8" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="1.5"/>
            <text x="16" y="24" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#0F172A">
                Machine Learning Static Weights
            </text>
            <text x="16" y="46" font-family="Arial, sans-serif" font-size="11" fill="#475569">
                assets/ml/weights.json (Tiny MLP 5->16->8->1, 241 params in Dart Isolate)
            </text>
        </g>

        <!-- Item 4: PDF Reports -->
        <g transform="translate(600, 115)">
            <rect x="0" y="0" width="540" height="65" rx="8" ry="8" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="1.5"/>
            <text x="16" y="24" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#0F172A">
                Generated PDF Biomonitoring Reports
            </text>
            <text x="16" y="46" font-family="Arial, sans-serif" font-size="11" fill="#475569">
                Rendered offline on device via PdfReportGenerator into app storage directory
            </text>
        </g>

        <!-- Summary Note -->
        <g transform="translate(1170, 36)">
            <rect x="0" y="0" width="1170" height="144" rx="8" ry="8" fill="#F1F5F9" stroke="#94A3B8" stroke-width="1.5"/>
            <text x="20" y="28" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#1E293B">
                Architectural Distinction &amp; Data Boundary Notes
            </text>
            <text x="20" y="54" font-family="Arial, sans-serif" font-size="11" fill="#334155">
                • These entities are NOT SQLite tables and are NOT stored as relational records.
            </text>
            <text x="20" y="78" font-family="Arial, sans-serif" font-size="11" fill="#334155">
                • Hardware &amp; BLE streaming supply transient raw samples ingested into the `samples` table.
            </text>
            <text x="20" y="102" font-family="Arial, sans-serif" font-size="11" fill="#334155">
                • ML weights are compiled assets; model outputs populate the `ai_results` table.
            </text>
            <text x="20" y="126" font-family="Arial, sans-serif" font-size="11" fill="#334155">
                • PDF reports aggregate data from `sessions`, `session_stats`, and `ai_results` on demand.
            </text>
        </g>
    </g>
    """

    idx_close = content.rfind("</svg>")
    if idx_close != -1:
        new_content = content[:idx_close] + outside_svg_fragment + "\n</svg>"
        svg_path.write_text(new_content, encoding="utf-8")
        print("Updated docs/erd/pulse_patch_erd.svg with 'Outside the Database' callout box.")

def augment_png_and_pdf():
    # Render updated SVG to PNG and PDF using PyMuPDF (fitz)
    svg_path = "docs/erd/pulse_patch_erd.svg"
    png_path = "docs/erd/pulse_patch_erd.png"
    pdf_path = "docs/erd/pulse_patch_erd.pdf"

    svg_data = Path(svg_path).read_bytes()
    doc = fitz.open(stream=svg_data, filetype="svg")
    page = doc[0]

    # Generate high-res PNG (width >= 2400)
    # The SVG width is ~2406. With matrix scale 1.25, width = 3008 px
    scale = 1.3
    mat = fitz.Matrix(scale, scale)
    pix = page.get_pixmap(matrix=mat, alpha=False)
    pix.save(png_path)
    print(f"Rendered {png_path} ({pix.width}x{pix.height}) >= 2400 px width.")

    # Generate A4 Landscape PDF
    # A4 Landscape: 841.89 x 595.28 points (11.69 x 8.27 inches)
    pdf_doc = fitz.open()
    a4_landscape_rect = fitz.Rect(0, 0, 841.89, 595.28)
    pdf_page = pdf_doc.new_page(width=a4_landscape_rect.width, height=a4_landscape_rect.height)

    # Scale diagram to fit nicely inside A4 landscape with margins
    margin = 25.0
    target_rect = fitz.Rect(margin, margin, a4_landscape_rect.width - margin, a4_landscape_rect.height - margin)
    pdf_page.show_pdf_page(target_rect, doc, 0)
    pdf_doc.save(pdf_path)
    pdf_doc.close()
    doc.close()
    print(f"Rendered {pdf_path} (A4 Landscape).")

if __name__ == "__main__":
    augment_svg()
    augment_png_and_pdf()
