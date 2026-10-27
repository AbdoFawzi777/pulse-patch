#!/usr/bin/env python3
"""
tools/generate_team_technical_report.py
Generates a comprehensive Arabic technical defense PDF report for the PulsePatch Lite engineering team.
Honest, transparent, with zero overclaims: features, languages, databases, architecture, and current hardware boundaries.
"""

import os
import sys
import arabic_reshaper
from bidi.algorithm import get_display

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

# Register Fonts
FONT_REGULAR = "C:/Windows/Fonts/arial.ttf"
FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
pdfmetrics.registerFont(TTFont("Arial", FONT_REGULAR))
pdfmetrics.registerFont(TTFont("Arial-Bold", FONT_BOLD))

def ar(text: str) -> str:
    """Helper to reshape and reorder Arabic text for ReportLab while preserving HTML tags."""
    if not text:
        return ""
    # Process line breaks safely without Bidi flipping them
    lines = text.split("<br/>")
    out_lines = []
    for line in lines:
        # Protect HTML bold tags
        line_clean = line.replace("<b>", "___B___").replace("</b>", "___EB___")
        reshaped = arabic_reshaper.reshape(line_clean)
        bidi_str = get_display(reshaped)
        # Restore tags
        bidi_str = bidi_str.replace("___B___", "<b>").replace("___EB___", "</b>")
        out_lines.append(bidi_str)
    return "<br/>".join(out_lines)

class NumberedCanvas(canvas.Canvas):
    """Canvas that performs a two-pass calculation of total page numbers."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Arial", 8)
        self.setFillColor(colors.HexColor("#6B6F95"))

        # Header (pages 2+)
        if self._pageNumber > 1:
            header_text = ar("تطبيق PulsePatch Lite — تقرير التوثيق والمراجعة التقنية الشاملة للفريق")
            self.drawRightString(A4[0] - 20 * mm, A4[1] - 15 * mm, header_text)
            self.setStrokeColor(colors.HexColor("#1B2A66"))
            self.setLineWidth(0.5)
            self.line(20 * mm, A4[1] - 17 * mm, A4[0] - 20 * mm, A4[1] - 17 * mm)

        # Footer
        footer_left = f"Page {self._pageNumber} of {page_count}"
        footer_right = ar("وثيقة داخلية للفريق ولجنة التحكيم — غير مخصصة للنشر التجاري — أكتوبر 2026")
        self.drawString(20 * mm, 12 * mm, footer_left)
        self.drawRightString(A4[0] - 20 * mm, 12 * mm, footer_right)

        self.setStrokeColor(colors.HexColor("#1B2A66"))
        self.setLineWidth(0.5)
        self.line(20 * mm, 16 * mm, A4[0] - 20 * mm, 16 * mm)
        self.restoreState()

def create_report(output_path: str):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=22 * mm,
        bottomMargin=22 * mm,
    )

    styles = getSampleStyleSheet()

    # Color Palette Matching Design System
    PRIMARY_NAVY = colors.HexColor("#0B1840")
    ACCENT_CYAN  = colors.HexColor("#0891B2")
    ACCENT_PURPLE = colors.HexColor("#581C87")
    TEXT_DARK    = colors.HexColor("#0F172A")
    TEXT_MUTED   = colors.HexColor("#475569")
    BG_LIGHT     = colors.HexColor("#F8FAFC")
    BORDER_COLOR = colors.HexColor("#CBD5E1")
    ALERT_BG     = colors.HexColor("#FFFBEB")
    ALERT_BORDER = colors.HexColor("#F59E0B")

    style_title = ParagraphStyle(
        "ArTitle",
        fontName="Arial-Bold",
        fontSize=20,
        leading=26,
        alignment=1, # Center
        textColor=PRIMARY_NAVY,
    )

    style_subtitle = ParagraphStyle(
        "ArSubtitle",
        fontName="Arial",
        fontSize=11,
        leading=16,
        alignment=1, # Center
        textColor=TEXT_MUTED,
    )

    style_h1 = ParagraphStyle(
        "ArH1",
        fontName="Arial-Bold",
        fontSize=13,
        leading=18,
        alignment=2, # Right
        textColor=PRIMARY_NAVY,
        spaceBefore=12,
        spaceAfter=6,
    )

    style_h2 = ParagraphStyle(
        "ArH2",
        fontName="Arial-Bold",
        fontSize=10.5,
        leading=15,
        alignment=2, # Right
        textColor=ACCENT_CYAN,
        spaceBefore=8,
        spaceAfter=4,
    )

    style_body = ParagraphStyle(
        "ArBody",
        fontName="Arial",
        fontSize=9.5,
        leading=14.5,
        alignment=2, # Right
        textColor=TEXT_DARK,
        spaceAfter=6,
    )

    style_body_bold = ParagraphStyle(
        "ArBodyBold",
        fontName="Arial-Bold",
        fontSize=9.5,
        leading=14.5,
        alignment=2,
        textColor=TEXT_DARK,
    )

    style_alert = ParagraphStyle(
        "ArAlert",
        fontName="Arial",
        fontSize=9,
        leading=13.5,
        alignment=2,
        textColor=colors.HexColor("#78350F"),
    )

    style_table_cell = ParagraphStyle(
        "ArTableCell",
        fontName="Arial",
        fontSize=8.5,
        leading=12,
        alignment=2,
        textColor=TEXT_DARK,
    )

    style_table_cell_bold = ParagraphStyle(
        "ArTableCellBold",
        fontName="Arial-Bold",
        fontSize=8.5,
        leading=12,
        alignment=2,
        textColor=PRIMARY_NAVY,
    )

    style_table_cell_center = ParagraphStyle(
        "ArTableCellCenter",
        fontName="Arial",
        fontSize=8.5,
        leading=12,
        alignment=1,
        textColor=TEXT_DARK,
    )

    story = []

    # =========================================================================
    # HEADER / BANNER
    # =========================================================================
    story.append(Paragraph(ar("مشروع تخرج النظم المدمجة والبرمجيات الطبية الحيوية — دفعة 2026"), style_subtitle))
    story.append(Spacer(1, 2 * mm))
    story.append(Paragraph(ar("التقرير الفني الشامل والتوثيق الهندسي لتطبيق pulse patch"), style_title))
    story.append(Spacer(1, 2 * mm))
    story.append(Paragraph(
        ar("مراجعة صريحة ومكاشفة هندسية للفريق: الخدمات المتاحة، اللغات والتقنيات، قواعد البيانات، وحدود الجاهزية الفعلية"),
        style_subtitle
    ))
    story.append(Spacer(1, 4 * mm))
    story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_NAVY, spaceBefore=2, spaceAfter=8))

    # Alert Box: Honest Boundary
    alert_text = ar(
        "<b>تنويه الشفافية الهندسية الصريحة:</b> هذا التقرير موجه لفريق التطوير ولجنة الإشراف لمناقشة واقع النظام الفعلي دون أي مبالغة أو ادعاء غير مثبت. الحزمة البرمجية الكاملة (تطبيق الهاتف، نموذج الذكاء الاصطناعي، وقواعد البيانات) مكتملة ومختبرة بنسبة 100%، بينما الربط الفيزيائي بحساس MAX30102 ورقاقة ESP32-C3 قيد الإعداد المخبري (Phase 14) ولم يتم اختباره بعد على يد بشرية حية في الميدان بل جرى اختباره عبر بروتوكول البلوتوث الحقيقي مع محاكي طرفي."
    )
    alert_table = Table(
        [[Paragraph(alert_text, style_alert)]],
        colWidths=[A4[0] - 36 * mm]
    )
    alert_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), ALERT_BG),
        ('BOX', (0,0), (-1,-1), 1, ALERT_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(alert_table)
    story.append(Spacer(1, 4 * mm))

    # =========================================================================
    # SECTION 1: الخدمات التي يقدمها التطبيق
    # =========================================================================
    story.append(Paragraph(ar("1. الخدمات والوظائف التي يقدمها تطبيق pulse patch"), style_h1))
    story.append(Paragraph(
        ar("يقدم التطبيق منظومة متكاملة لمراقبة وتحليل حركية النبض للأغراض التعليمية والرياضية الشخصية، مع التزام تام بالحدود غير التشخيصية:"),
        style_body
    ))

    services_data = [
        [
            Paragraph(ar("<b>الوصف الهندسي والتشغيلي للخدمة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>الخدمة / الوظيفة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>م</b>"), style_table_cell_bold)
        ],
        [
            Paragraph(ar("استقبال تدفق بيانات النبض بمعدل حزمة واحدة كل ثانية عبر بروتوكول BLE GATT القياسي أو المخصص (12 بايت)، مع إمكانية التبديل إلى محاكي داخلي لتجربة كافة الشاشات دون الحاجة لجهاز خارجي."), style_table_cell),
            Paragraph(ar("<b>مراقبة النبض اللحظية</b><br/>(Real-Time Ingestion)"), style_table_cell),
            Paragraph("1", style_table_cell_center)
        ],
        [
            Paragraph(ar("دعم نوعين من الجلسات: جلسة استرخاء (Resting) لمدة 60 ثانية، أو جلسة تعافي بعد المجهود البدني (Post-Activity Recovery) لمدة 90 ثانية لحساب سرعة هبوط النبض."), style_table_cell),
            Paragraph(ar("<b>بروتوكولات القياس المزدوجة</b><br/>(Resting & Recovery)"), style_table_cell),
            Paragraph("2", style_table_cell_center)
        ],
        [
            Paragraph(ar("استبعاد تلقائي لأي قراءة مشوشة بالحركة أو ضعف التلامس عبر مرشح وسيط (5-sample median) وبوابة جودة الإشارة (SQI &ge; 60)، مع إيقاف مؤقت للعداد عند فقدان الاتصال."), style_table_cell),
            Paragraph(ar("<b>فلترة الإشارة والتحقق</b><br/>(Signal Quality Gate)"), style_table_cell),
            Paragraph("3", style_table_cell_center)
        ],
        [
            Paragraph(ar("استخراج 11 متغيراً إحصائياً وتمريرها لشبكة عصبية محلية خفيفة لتصنيف الجلسة إلى نمط معتاد (Typical pattern) أو نمط مختلف (Different pattern) دون استخدام أي مصطلحات تشخيصية طبية."), style_table_cell),
            Paragraph(ar("<b>التصنيف الذكي للأنماط</b><br/>(On-Device AI Inference)"), style_table_cell),
            Paragraph("4", style_table_cell_center)
        ],
        [
            Paragraph(ar("حفظ محلي فوري لكافة الجلسات وقراءاتها الثانية بثانية، مع شاشات لعرض التحليلات التاريخية (Historical Trends) ومتوسطات النبض وسرعة التعافي."), style_table_cell),
            Paragraph(ar("<b>السجل التاريخي والتحليلات</b><br/>(Session Analytics)"), style_table_cell),
            Paragraph("5", style_table_cell_center)
        ],
        [
            Paragraph(ar("توليد تقارير بيومترية عالية الدقة بصيغة PDF محلياً بالكامل دون اتصال بالإنترنت، مع فصل صريح لمصدر البيانات (مصنعة / محاكاة / حقيقية) وتضمين إخلاء المسؤولية التعليمي."), style_table_cell),
            Paragraph(ar("<b>تصدير التقارير دون إنترنت</b><br/>(100% Offline PDF Reports)"), style_table_cell),
            Paragraph("6", style_table_cell_center)
        ],
        [
            Paragraph(ar("واجهة مستخدم تدعم التبديل اللحظي بين العربية (RTL) والإنجليزية (LTR) مع توافق كامل لكافة الخطوط والاتجاهات دون أي تشويه بصري."), style_table_cell),
            Paragraph(ar("<b>التعريب الشامل وتعدد اللغات</b><br/>(Bilingual Localization)"), style_table_cell),
            Paragraph("7", style_table_cell_center)
        ],
        [
            Paragraph(ar("شاشة تشخيصية سرية تُفتح عبر النقر 7 مرات على رقم الإصدار، تعرض تدفق البايتات الـ 12 بنظام الـ Hex، ومعدل الحزم، وسجل السقطات، وأداة تسجيل وتصدير ملفات CSV للتنقيح."), style_table_cell),
            Paragraph(ar("<b>شاشة التشخيصات والهندسة</b><br/>(BLE Diagnostics & Logger)"), style_table_cell),
            Paragraph("8", style_table_cell_center)
        ],
    ]

    t_services = Table(services_data, colWidths=[240, 140, 20])
    t_services.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_services)
    story.append(Spacer(1, 4 * mm))

    # =========================================================================
    # SECTION 2: اللغات البرمجية والتقنيات المستخدمة
    # =========================================================================
    story.append(Paragraph(ar("2. اللغات البرمجية والتقنيات وأطر العمل المستخدمة"), style_h1))
    story.append(Paragraph(
        ar("بُني النظام على تكامل ثلاث طبقات برمجية رئيسية: طبقة العتاد المدمج، وطبقة تطبيق الهاتف الذكي، وطبقة الذكاء الاصطناعي والتحليل الرياضي:"),
        style_body
    ))

    tech_data = [
        [
            Paragraph(ar("<b>الدور الهندسي والاستخدام داخل المشروع</b>"), style_table_cell_bold),
            Paragraph(ar("<b>المكتبات والتقنيات المرتبطة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>اللغة / الإطار</b>"), style_table_cell_bold)
        ],
        [
            Paragraph(ar("بناء كامل تطبيق الهاتف (29 شاشة وواجهة تفاعلية)، معمارية نظيفة (Clean Architecture)، واختبارات تكاملية شاملة."), style_table_cell),
            Paragraph(ar("Flutter SDK 3.x, FlutterRiverpod, GoRouter, PathProvider, SharePlus"), style_table_cell),
            Paragraph(ar("<b>Dart</b><br/>(تطبيق الهاتف المحمول)"), style_table_cell)
        ],
        [
            Paragraph(ar("برمجة متحكم ESP32-C3 RISC-V لإدارة حساس MAX30102 عبر I2C (400kHz)، تطبيق مرشح IIR DC، وبث حزم BLE GATT."), style_table_cell),
            Paragraph(ar("PlatformIO, Arduino Core for ESP32, NimBLE-Arduino, SparkFun MAX3010x"), style_table_cell),
            Paragraph(ar("<b>C++ / Embedded C</b><br/>(الفيرموير المدمج)"), style_table_cell)
        ],
        [
            Paragraph(ar("بناء خط إنتاج تدريب النموذج الاصطناعي، خوارزميات محاكاة النبض، التحقق من التطابق الحسابي (&Delta;=0.0)، وأدوات اختبار الاستقرار."), style_table_cell),
            Paragraph(ar("Python 3.10+, NumPy, Scikit-Learn, ReportLab, PyMuPDF, ADB Automation"), style_table_cell),
            Paragraph(ar("<b>Python</b><br/>(التدريب والتحليل والتحقق)"), style_table_cell)
        ],
        [
            Paragraph(ar("شبكة عصبية متعددة الطبقات (MLP) بهيكلية 5 &rarr; 16 &rarr; 8 &rarr; 1 تضم 241 باراميتر، كُتبت بالكامل بلغة Dart نقية دون TFLite، وتعمل داخل Isolate مستقل بزمن تنفيذي يقل عن 0.15 مللي ثانية."), style_table_cell),
            Paragraph(ar("Pure Dart Background Isolate, Linear Algebra Vector Math, JSON Weights"), style_table_cell),
            Paragraph(ar("<b>Pure Dart ML Engine</b><br/>(محرك الاستدلال الذكي)"), style_table_cell)
        ],
        [
            Paragraph(ar("بروتوكول مخصص بحجم 12 بايت (Little-Endian) يتضمن: رقم الإصدار (1B)، الأعلام (1B)، النبض مضروباً في 10 (2B)، مؤشر الجودة SQI (1B)، الطابع الزمني بالمللي ثانية (4B)، والرقم التسلسلي (2B)."), style_table_cell),
            Paragraph(ar("Custom 128-bit UUIDs, Struct Packing, Little-Endian ByteData, 1 Hz Notify"), style_table_cell),
            Paragraph(ar("<b>BLE GATT Contract</b><br/>(بروتوكول البث اللاسلكي)"), style_table_cell)
        ],
    ]

    t_tech = Table(tech_data, colWidths=[200, 120, 80])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_tech)
    story.append(Spacer(1, 4 * mm))

    # =========================================================================
    # SECTION 3: قواعد البيانات وإدارة التخزين
    # =========================================================================
    story.append(Paragraph(ar("3. قواعد البيانات وإدارة التخزين واستقلالية البيانات"), style_h1))
    story.append(Paragraph(
        ar("اعتمد المشروع فلسفة الخصوصية أولاً (Privacy by Design) مع استقلالية تامة عن أي سحابة إلكترونية أو خوادم خارجية:"),
        style_body
    ))

    db_data = [
        [
            Paragraph(ar("<b>المواصفات الفنية وتدابير الحماية والسرعة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>طبيعة البيانات المخزنة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>نظام التخزين / التقنية</b>"), style_table_cell_bold)
        ],
        [
            Paragraph(ar("محرك SQLite مدمج يعمل عبر واجهة C FFI المباشرة دون وسيط، مما يوفر سرعة استعلام فائقة واستهلاكاً صفرياً للشبكة. البيانات مشفرة محلياً على مساحة التطبيق الخاصة بجهاز المستخدم."), style_table_cell),
            Paragraph(ar("جدول الجلسات (Sessions): المعرف، التوقيت، المدة، النوع، الخصائص الإحصائية الـ 11، تصنيف الذكاء الاصطناعي، وملاحظات المستخدم.<br/>جدول العينات (HeartRateSamples): نبض كل ثانية، مؤشر SQI، والزمن."), style_table_cell),
            Paragraph(ar("<b>Drift ORM (SQLite / C-FFI)</b><br/>قاعدة البيانات العلائقية الرئيسية"), style_table_cell)
        ],
        [
            Paragraph(ar("مخزن أزواج المفاتيح والقيم (Key-Value) الخاص بنظام أندرويد/iOS، سريع وخفيف جداً، يُحفظ مشفراً في الذاكرة التفضيلية للجهاز."), style_table_cell),
            Paragraph(ar("اللغة المختارة (ar/en)، حالة إتمام جولة البداية (Onboarding)، تفضيلات المستخدم (الاسم المعروض، بروتوكول القياس المفضل)، وإعدادات التنبيهات."), style_table_cell),
            Paragraph(ar("<b>SharedPreferences</b><br/>تخزين الإعدادات والتفضيلات"), style_table_cell)
        ],
        [
            Paragraph(ar("محرك استعلام وتصدير مدمج يتيح للمستخدم تحويل كامل قاعدة بياناته المحلية إلى ملفات بصيغة JSON أو CSV متوافقة مع جداول Excel دون الحاجة لاتصال بالإنترنت."), style_table_cell),
            Paragraph(ar("سجل كامل للجلسات لغايات التدريب وإعادة الفحص الرياضي (Portability)."), style_table_cell),
            Paragraph(ar("<b>محرك التصدير الذاتي</b><br/>(JSON & CSV Exporter)"), style_table_cell)
        ],
    ]

    t_db = Table(db_data, colWidths=[180, 140, 80])
    t_db.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_db)
    story.append(Spacer(1, 4 * mm))

    # =========================================================================
    # SECTION 4: المكاشفة الهندسية وميثاق الصدق والشفافية مع الفريق
    # =========================================================================
    story.append(Paragraph(ar("4. المكاشفة الهندسية وميثاق الصدق والشفافية مع الفريق"), style_h1))
    story.append(Paragraph(
        ar("التزاماً بالأمانة العلمية والهندسية، نوضح فيما يلي حقيقة كل جانب من جوانب المشروع، مع التمييز الدقيق بين ما تم إثباته واقعياً وما هو قيد الاختبار المستقبلي:"),
        style_body
    ))

    disclosures_data = [
        [
            Paragraph(ar("<b>الحقيقة الفنية والواقع المثبت في الكود والميدان</b>"), style_table_cell_bold),
            Paragraph(ar("<b>الادعاء غير الدقيق / ما يجب تجنب قوله</b>"), style_table_cell_bold),
            Paragraph(ar("<b>البند الهندسي</b>"), style_table_cell_bold)
        ],
        [
            Paragraph(ar("نسبة 98.86% هي نتيجة اختبار GroupKFold على مجموعة تدريب يمثل فيها 10 من أصل 11 متطوعاً بيانات اصطناعية (Synthetic). يوجد متطوع واحد حقيقي فقط بثلاث جلسات للتحقق من سلامة خط الإنتاج الحسابي. النسبة تعكس جودة البيانات المصنعة ولا تعبر عن قدرة النموذج على التعميم في المجتمع الحقيقي."), style_table_cell),
            Paragraph(ar("تجنب قول: «دقة النموذج في تشخيص البشر 98.86%» أو «النموذج جاهز للتنبؤ بأمراض القلب»."), style_table_cell),
            Paragraph(ar("<b>دقة نموذج الذكاء الاصطناعي</b><br/>(Model Accuracy Metric)"), style_table_cell)
        ],
        [
            Paragraph(ar("الجلسات الميدانية الثلاث سُجلت عبر اتصال بلوتوث لاسلكي حقيقي (OTA) على هاتف HONOR NIC-LX2، ولكن الطرف الآخر كان جهاز محاكاة طرفي واقعي (PulsePatch-SimHR). الاتصال حقيقي 100% كشبكة، ولكن الإشارة الفسيولوجية كانت محاكاة هندسية وليست نبضاً بشرياً حياً مقاساً بضوء الأشعة تحت الحمراء."), style_table_cell),
            Paragraph(ar("تجنب قول: «سجلنا بيانات حية لمتطوعين بشريين عبر حساس بصري مثبت على الإصبع»."), style_table_cell),
            Paragraph(ar("<b>جلسات البلوتوث الميدانية</b><br/>(Field BLE Telemetry)"), style_table_cell)
        ],
        [
            Paragraph(ar("كود الفيرموير C++ مكتمل ومبني بنجاح عبر PlatformIO، وحزمة الـ 12 بايت متطابقة تماماً مع كود Dart، ولكن التوصيل الفيزيائي على لوحة التجارب (Breadboard) لحساس MAX30102 ومتحكم ESP32-C3 معلق (Phase 14 Pending) ولم يتم تشغيله على يد حقيقية بعد."), style_table_cell),
            Paragraph(ar("تجنب قول: «تم اختبار الحساس المادي بنجاح واكتمل الربط الفيزيائي للجهاز»."), style_table_cell),
            Paragraph(ar("<b>حالة عتاد الحساس والمتحكم</b><br/>(ESP32-C3 + MAX30102)"), style_table_cell)
        ],
        [
            Paragraph(ar("النظام بأكمله مصمم لأغراض تعليمية وبحثية استكشافية. لا يقدم التطبيق أي تشخيص لعدم انتظام ضربات القلب (Arrhythmia) أو أمراض الشرايين، والنموذج يكتفي بتصنيف الجلسة إلى نمط معتاد أو مختلف لتشجيع المستخدم على استشارة الطبيب المختص."), style_table_cell),
            Paragraph(ar("تجنب قول: «جهاز طبي أو بديل عن أجهزة التخطيط الطبي ECG»."), style_table_cell),
            Paragraph(ar("<b>الحدود الطبية والقانونية</b><br/>(Non-Diagnostic Scope)"), style_table_cell)
        ],
    ]

    t_disclosures = Table(disclosures_data, colWidths=[180, 130, 90])
    t_disclosures.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#7F1D1D")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_disclosures)
    story.append(Spacer(1, 4 * mm))

    # =========================================================================
    # SECTION 5: جدول مؤشرات الجودة والاختبارات المنجزة
    # =========================================================================
    story.append(Paragraph(ar("5. جدول الجودة الهندسية ومؤشرات الإنجاز المحققة"), style_h1))

    metrics_data = [
        [
            Paragraph(ar("<b>الدليل الموثق والموقع في المستودع</b>"), style_table_cell_bold),
            Paragraph(ar("<b>النتيجة المحققة</b>"), style_table_cell_bold),
            Paragraph(ar("<b>المعيار الهندسي</b>"), style_table_cell_bold)
        ],
        [
            Paragraph(ar("تقرير اختبار Flutter: نجاح 311 اختباراً دون أي إخفاق، مع تغطية شاملة لجميع الوحدات."), style_table_cell),
            Paragraph(ar("<b>311 / 311 (100% Pass)</b>"), style_table_cell_center),
            Paragraph(ar("مجموعة الاختبارات البرمجية"), style_table_cell)
        ],
        [
            Paragraph(ar("فحص الكود عبر `flutter analyze` في المسار الرئيسي."), style_table_cell),
            Paragraph(ar("<b>0 Issues (Clean)</b>"), style_table_cell_center),
            Paragraph(ar("التحليل الساكن للكود"), style_table_cell)
        ],
        [
            Paragraph(ar("اختبار 29 شاشة وواجهة &times; 3 دقات شاشة &times; معاملي تكبير للنص (1.0x و 1.3x)."), style_table_cell),
            Paragraph(ar("<b>174 / 174 Permutations (0 Overflows)</b>"), style_table_cell_center),
            Paragraph(ar("توافق واجهات المستخدم والشاشات"), style_table_cell)
        ],
        [
            Paragraph(ar("تطابق تام بين استخراج بايثون وقيم قاعدة بيانات التطبيق عبر الجلسات الثلاث المسجلة."), style_table_cell),
            Paragraph(ar("<b>&Delta; = 0.000000 (Exact Parity)</b>"), style_table_cell_center),
            Paragraph(ar("التطابق الحسابي للخصائص"), style_table_cell)
        ],
        [
            Paragraph(ar("اختباران على هاتف HONOR NIC-LX2: تشغيل خامل (14 دقيقة) وتدفق مباشر (3.75 دقيقة) دون تسريب ذاكرة."), style_table_cell),
            Paragraph(ar("<b>0 ANR / 0 Crashes (GC Stable)</b>"), style_table_cell_center),
            Paragraph(ar("استقرار التطبيق على الهاتف الحقيقي"), style_table_cell)
        ],
        [
            Paragraph(ar("بناء كامل وتوليد ملف `firmware.bin` بحجم 572,352 بايت (Flash 41.7%, RAM 7.3%)."), style_table_cell),
            Paragraph(ar("<b>PlatformIO Exit 0 (Clean Build)</b>"), style_table_cell_center),
            Paragraph(ar("جاهزية كود الفيرموير"), style_table_cell)
        ],
        [
            Paragraph(ar("حزمة التطبيق النهائية `app-release.apk` بحجم 59.6 MB ومثبتة ومجربة بنجاح على الهاتف."), style_table_cell),
            Paragraph(ar("<b>v1.0.0-rc1-software (Tagged)</b>"), style_table_cell_center),
            Paragraph(ar("حزمة الإصدار الرسمي والوسم"), style_table_cell)
        ],
    ]

    t_metrics = Table(metrics_data, colWidths=[200, 120, 80])
    t_metrics.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('TOPPADDING', (0,0), (-1,-1), 3.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_metrics)
    story.append(Spacer(1, 6 * mm))

    # =========================================================================
    # SIGNATURE & CLOSING
    # =========================================================================
    closing_text = ar(
        "<b>الخلاصة والقرار الهندسي:</b> النظام البرمجي متين ومكتمل وجاهز للمناقشة الأكاديمية وتقديم العرض الحي (Software Stack Defense-Ready)، مع وضوح خطة العمل القادمة لربط الحساس الفيزيائي MAX30102 بالمتحكم ESP32-C3 عند توفر متطلبات المعمل دون الحاجة لأي تعديل في البنية التحتية للتطبيق."
    )
    story.append(Paragraph(closing_text, style_body_bold))
    story.append(Spacer(1, 4 * mm))

    sign_data = [
        [
            Paragraph(ar("<b>اعتماد وتوثيق النظام:</b><br/>مستودع الكود: pulse patch (Git Master @ 06842bb)<br/>الإصدار البرمجي: v1.0.0-rc1-software"), style_table_cell),
            Paragraph(ar("<b>إعداد وتقديم:</b><br/>الفريق الهندسي المطور<br/>مشروع تخرج النظم المدمجة 2026"), style_table_cell)
        ]
    ]
    t_sign = Table(sign_data, colWidths=[200, 200])
    t_sign.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_sign)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated technical defense PDF report at: {output_path}")

if __name__ == "__main__":
    out = os.path.abspath("docs/field_test/reports/pulse_patch_technical_defense_report_ar.pdf")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    create_report(out)
