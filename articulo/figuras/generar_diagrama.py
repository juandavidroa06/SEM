"""Regenera el diagrama vectorial del modelo para el manuscrito."""
from pathlib import Path
from math import atan2, cos, sin, pi

from reportlab.lib.colors import HexColor, black, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


HERE = Path(__file__).resolve().parent
OUTPUT = HERE / "modelo_sem.pdf"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\arialbd.ttf")
if FONT.exists() and FONT_BOLD.exists():
    pdfmetrics.registerFont(TTFont("ArialUnicode", str(FONT)))
    pdfmetrics.registerFont(TTFont("ArialUnicode-Bold", str(FONT_BOLD)))
    REGULAR, BOLD = "ArialUnicode", "ArialUnicode-Bold"
else:
    REGULAR, BOLD = "Helvetica", "Helvetica-Bold"


PAGE = (540, 330)
c = canvas.Canvas(str(OUTPUT), pagesize=PAGE, pageCompression=1)
c.setTitle("Diagrama del modelo SEM con coeficientes estandarizados")
c.setAuthor("Estimaciones propias con la ECP 2023 del DANE")


def oval(cx, cy, width, height, lines, font_size=12):
    c.setFillColor(HexColor("#F6F8FC"))
    c.setStrokeColor(HexColor("#334155"))
    c.setLineWidth(1.5)
    c.ellipse(cx - width / 2, cy - height / 2, cx + width / 2, cy + height / 2,
              stroke=1, fill=1)
    line_height = font_size + 5
    first_y = cy + (len(lines) - 1) * line_height / 2 - font_size * 0.32
    for i, (text, bold) in enumerate(lines):
        c.setFont(BOLD if bold else REGULAR, font_size if i else font_size + 0.5)
        c.setFillColor(black)
        c.drawCentredString(cx, first_y - i * line_height, text)


def arrow(x1, y1, x2, y2, label, label_xy):
    c.setStrokeColor(HexColor("#1F2937"))
    c.setFillColor(HexColor("#1F2937"))
    c.setLineWidth(1.7)
    c.line(x1, y1, x2, y2)
    angle = atan2(y2 - y1, x2 - x1)
    size = 9
    left = (x2 - size * cos(angle - pi / 6), y2 - size * sin(angle - pi / 6))
    right = (x2 - size * cos(angle + pi / 6), y2 - size * sin(angle + pi / 6))
    path = c.beginPath()
    path.moveTo(x2, y2)
    path.lineTo(*left)
    path.lineTo(*right)
    path.close()
    c.drawPath(path, stroke=0, fill=1)
    c.setFont(BOLD, 11)
    c.drawCentredString(*label_xy, label)


# Latent constructs (ellipses) and their measured indicators.
oval(115, 250, 190, 86, [
    ("Confianza interpersonal", True),
    ("4 indicadores ordinales", False),
    ("λ P2025S4 = 0,674", False),
])
oval(115, 80, 190, 86, [
    ("Confianza institucional", True),
    ("15 indicadores ordinales", False),
    ("λ P5263S1 = 0,840", False),
])
oval(430, 165, 200, 122, [
    ("Familiaridad autorreportada", True),
    ("6 indicadores binarios", False),
    ("λ P5376S1 = 0,857", False),
    ("R² = 0,016", False),
], font_size=11)

# Structural paths point to the single endogenous construct.
arrow(210, 250, 352, 210, "H1: β = 0,094***", (278, 245))
arrow(210, 80, 352, 120, "H2: β = 0,065***", (278, 85))

# Correlation between the two latent predictors.
c.setStrokeColor(HexColor("#475569"))
c.setFillColor(HexColor("#475569"))
c.setLineWidth(1.2)
c.line(115, 207, 115, 123)
for y, sign in ((207, -1), (123, 1)):
    path = c.beginPath()
    path.moveTo(115, y)
    path.lineTo(111, y + 7 * sign)
    path.lineTo(119, y + 7 * sign)
    path.close()
    c.drawPath(path, stroke=0, fill=1)
c.setFont(REGULAR, 10)
c.drawString(124, 162, "r = 0,265***")

c.setFont(REGULAR, 9)
c.setFillColor(HexColor("#475569"))
c.drawCentredString(PAGE[0] / 2, 17,
                    "*** p < 0,001. Asociaciones transversales estimadas con FEX_P.")
c.save()
print(OUTPUT)
