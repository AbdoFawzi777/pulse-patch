import pymupdf
from pathlib import Path

svg_path = Path("docs/erd/pulse_patch_erd.svg")
content = svg_path.read_text(encoding="utf-8")

# Replace width="100%" with absolute width and height from viewBox
content = content.replace('width="100%"', 'width="2406" height="1272"')
svg_path.write_text(content, encoding="utf-8")

doc = pymupdf.open("docs/erd/pulse_patch_erd.svg")
page = doc[0]
print("SVG dimensions:", page.rect)

# Generate PNG >= 2400 width
# Since base width is 2406, scale 1.25 gives ~3008px width
mat = pymupdf.Matrix(1.25, 1.25)
pix = page.get_pixmap(matrix=mat, alpha=False)
pix.save("docs/erd/pulse_patch_erd.png")
print("Saved docs/erd/pulse_patch_erd.png:", pix.width, "x", pix.height)

# Generate A4 Landscape PDF
# Convert page to a PDF document directly
pdf_bytes = doc.convert_to_pdf()
pdf_doc = pymupdf.open("pdf", pdf_bytes)

# Place into A4 Landscape page (841.89 x 595.28 points)
a4_doc = pymupdf.open()
a4_page = a4_doc.new_page(width=841.89, height=595.28)

# Compute bounding box with margins (margin 20)
margin = 20.0
avail_w = 841.89 - (2 * margin)
avail_h = 595.28 - (2 * margin)

# Aspect ratio of the diagram: 2406 / 1272 = ~1.891
# A4 Landscape aspect: 801.89 / 555.28 = ~1.444
# Scale down to fit width
scale = avail_w / page.rect.width
draw_w = avail_w
draw_h = page.rect.height * scale
target_rect = pymupdf.Rect(margin, margin + (avail_h - draw_h) / 2, margin + draw_w, margin + (avail_h - draw_h) / 2 + draw_h)

a4_page.show_pdf_page(target_rect, pdf_doc, 0)
a4_doc.save("docs/erd/pulse_patch_erd.pdf")
print("Saved docs/erd/pulse_patch_erd.pdf (A4 Landscape)")
