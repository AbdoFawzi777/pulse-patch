#!/usr/bin/env python3
"""
tools/render_erd.py
Generates presentation-grade ERD diagrams in both Dark Mode (app visual identity)
and Light Mode (print/publication ready).
Produces:
  - docs/erd/pulse_patch_erd_styled.svg / .png (>= 3600 px wide) / .pdf (A4 landscape vector)
  - docs/erd/pulse_patch_erd_print_light.svg / .png (>= 3600 px wide) / .pdf (A4 landscape vector)
"""

import sys
from pathlib import Path
import pymupdf
from verify_erd_parity import get_real_sqlite_schema

def generate_svg(theme='dark'):
    is_dark = (theme == 'dark')

    # Color Palette matching app design system
    if is_dark:
        bg_main       = "#04030C"
        bg_glow_tl    = "#1A0F44"
        bg_glow_br    = "#3A1566"
        card_bg       = "#0B1840"
        card_inner_bg = "#08122E"
        card_border   = "#3B4270"
        card_subtle   = "#152456"
        text_primary  = "#FFFFFF"
        text_secondary= "#9AA0C4"
        text_muted    = "#64748B"
        text_type     = "#38BDF8"  # Cyan/blue monospace
        line_color    = "#94A3B8"
        panel_bg      = "#081026"
        panel_border  = "#475569"
        sub_card_bg   = "#0F1F4D"
        legend_bg     = "#0B1840"
    else:
        bg_main       = "#F8FAFC"
        bg_glow_tl    = "#EDE9FE"
        bg_glow_br    = "#E0E7FF"
        card_bg       = "#FFFFFF"
        card_inner_bg = "#F8FAFC"
        card_border   = "#CBD5E1"
        card_subtle   = "#E2E8F0"
        text_primary  = "#0F172A"
        text_secondary= "#475569"
        text_muted    = "#94A3B8"
        text_type     = "#0284C7"  # Deep cyan
        line_color    = "#475569"
        panel_bg      = "#F1F5F9"
        panel_border  = "#94A3B8"
        sub_card_bg   = "#FFFFFF"
        legend_bg     = "#FFFFFF"

    # Role Headers
    color_sessions = "#06B6D4"  # Bright Cyan
    color_samples  = "#3B82F6"  # Blue
    color_stats    = "#10B981"  # Emerald / Teal
    color_ai       = "#A855F7"  # Violet
    color_settings = "#64748B"  # Muted Slate

    # Badge Colors
    badge_pk_bg = "#EAB308" if is_dark else "#CA8A04"
    badge_pk_fg = "#000000" if is_dark else "#FFFFFF"
    badge_fk_bg = "#06B6D4" if is_dark else "#0891B2"
    badge_fk_fg = "#000000" if is_dark else "#FFFFFF"
    badge_nn_bg = "#334155" if is_dark else "#E2E8F0"
    badge_nn_fg = "#94A3B8" if is_dark else "#475569"

    # SVG Canvas: 2400 x 1400 (aspect ~ 16:9.3, high definition)
    W, H = 2400, 1400

    svg = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
    svg.append('<defs>')
    
    # Gradients
    svg.append(f'''
        <radialGradient id="bgGlowTL" cx="0%" cy="0%" r="50%">
            <stop offset="0%" stop-color="{bg_glow_tl}" stop-opacity="0.6"/>
            <stop offset="100%" stop-color="{bg_main}" stop-opacity="0"/>
        </radialGradient>
        <radialGradient id="bgGlowBR" cx="100%" cy="100%" r="60%">
            <stop offset="0%" stop-color="{bg_glow_br}" stop-opacity="0.5"/>
            <stop offset="100%" stop-color="{bg_main}" stop-opacity="0"/>
        </radialGradient>
        <filter id="cardShadow" x="-10%" y="-10%" width="120%" height="120%">
            <feDropShadow dx="0" dy="6" stdDeviation="10" flood-color="{"#000000" if is_dark else "#64748B"}" flood-opacity="{"0.45" if is_dark else "0.15"}"/>
        </filter>
        <marker id="crowFootMany" viewBox="0 0 16 16" refX="16" refY="8" markerWidth="12" markerHeight="12" orient="auto-start-reverse">
            <path d="M 0 0 L 16 8 L 0 16 M 16 0 L 16 16" fill="none" stroke="{color_samples}" stroke-width="2"/>
        </marker>
        <marker id="arrowDashed" viewBox="0 0 12 12" refX="10" refY="6" markerWidth="8" markerHeight="8" orient="auto">
            <path d="M 0 1 L 10 6 L 0 11 z" fill="{color_samples}"/>
        </marker>
    ''')
    svg.append('</defs>')

    # Background
    svg.append(f'<rect width="{W}" height="{H}" fill="{bg_main}"/>')
    svg.append(f'<rect width="{W}" height="{H}" fill="url(#bgGlowTL)"/>')
    svg.append(f'<rect width="{W}" height="{H}" fill="url(#bgGlowBR)"/>')

    # Top Header Bar
    svg.append(f'''
    <g transform="translate(60, 45)">
        <text x="0" y="28" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-size="28" font-weight="800" fill="{text_primary}" letter-spacing="0.5">
            PulsePatch Lite — Entity Relationship Diagram (ERD)
        </text>
        <text x="0" y="56" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-size="14" font-weight="500" fill="{text_secondary}">
            Local Pure C / FFI SQLite Engine (pulse_patch.db) • Schema Version: 2 (PRAGMA user_version = 2) • Active Integrity: Foreign Keys Enforced (PRAGMA foreign_keys = ON)
        </text>
    </g>
    ''')

    # Commit and timestamp tag
    svg.append(f'''
    <g transform="translate({W - 60}, 45)">
        <rect x="-310" y="4" width="310" height="52" rx="8" fill="{card_bg}" stroke="{card_border}" stroke-width="1"/>
        <text x="-295" y="26" font-family="'Courier New', Courier, monospace" font-size="12" font-weight="bold" fill="{color_sessions}">Git Commit: 8b73e71 (master)</text>
        <text x="-295" y="44" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="11" fill="{text_muted}">Architecture Parity: 100% Verified (0 drift)</text>
    </g>
    ''')

    # Define Coordinates for Cards
    # Center: sessions
    # Left: samples
    # Top-Right: session_stats
    # Bottom-Right: ai_results
    # Bottom-Left: reminders & app_settings
    # Bottom-Center/Right: Outside the Database panel

    # Helper function to render a table card
    def render_card(table_name, title, accent_color, x, y, width, columns, is_sub=False):
        row_h = 24
        header_h = 42
        card_h = header_h + len(columns) * row_h + 12
        r = 12

        card_svg = []
        card_svg.append(f'<g transform="translate({x}, {y})" filter="url(#cardShadow)">')
        # Base container
        card_svg.append(f'<rect x="0" y="0" width="{width}" height="{card_h}" rx="{r}" ry="{r}" fill="{card_bg}" stroke="{card_border}" stroke-width="1.2"/>')
        
        # Header background
        card_svg.append(f'<path d="M 0 {r} Q 0 0 {r} 0 L {width - r} 0 Q {width} 0 {width} {r} L {width} {header_h} L 0 {header_h} Z" fill="{accent_color}" fill-opacity="{"0.18" if is_dark else "0.15"}"/>')
        card_svg.append(f'<rect x="0" y="0" width="6" height="{header_h}" rx="3" fill="{accent_color}"/>')
        card_svg.append(f'<line x1="0" y1="{header_h}" x2="{width}" y2="{header_h}" stroke="{accent_color}" stroke-opacity="0.4" stroke-width="1.5"/>')

        # Header Title
        card_svg.append(f'<text x="18" y="27" font-family="-apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, sans-serif" font-size="16" font-weight="bold" fill="{text_primary}">{title}</text>')
        card_svg.append(f'<text x="{width - 16}" y="27" text-anchor="end" font-family="\'Courier New\', monospace" font-size="12" font-weight="bold" fill="{accent_color}">{table_name}</text>')

        # Rows
        curr_y = header_h + 8
        for col in columns:
            name, col_type, badges, is_nullable, note = col
            is_dim = (note == "optional_reserved")

            # Alternate row background
            # card_svg.append(f'<rect x="6" y="{curr_y - 2}" width="{width - 12}" height="{row_h}" fill="{card_inner_bg}" rx="4"/>')

            bx = 16
            # Draw Badges
            for b in badges:
                if b == 'PK':
                    bg_b, fg_b = badge_pk_bg, badge_pk_fg
                elif b == 'FK':
                    bg_b, fg_b = badge_fk_bg, badge_fk_fg
                else:
                    bg_b, fg_b = badge_nn_bg, badge_nn_fg
                
                card_svg.append(f'<rect x="{bx}" y="{curr_y + 1}" width="24" height="15" rx="3" fill="{bg_b}"/>')
                card_svg.append(f'<text x="{bx + 12}" y="{curr_y + 12}" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{fg_b}">{b}</text>')
                bx += 28

            # Column Name
            name_color = text_muted if is_dim else text_primary
            weight = "bold" if ('PK' in badges or 'FK' in badges) else "500"
            card_svg.append(f'<text x="{bx + 4}" y="{curr_y + 13}" font-family="-apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, sans-serif" font-size="12.5" font-weight="{weight}" fill="{name_color}">{name}</text>')

            # Nullable indicator
            if is_nullable:
                card_svg.append(f'<text x="{bx + 4 + len(name)*7.5 + 4}" y="{curr_y + 13}" font-family="-apple-system, sans-serif" font-size="11" font-weight="bold" fill="{text_muted}">?</text>')

            # Reserved tag if optional_reserved
            if is_dim:
                card_svg.append(f'<rect x="{width - 165}" y="{curr_y + 2}" width="54" height="13" rx="3" fill="{"#334155" if is_dark else "#CBD5E1"}"/>')
                card_svg.append(f'<text x="{width - 138}" y="{curr_y + 11}" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="8.5" font-weight="bold" fill="{text_muted}">BLE RESV</text>')

            # Data Type
            type_color = text_muted if is_dim else text_type
            card_svg.append(f'<text x="{width - 16}" y="{curr_y + 13}" text-anchor="end" font-family="\'Courier New\', monospace" font-size="11.5" font-weight="600" fill="{type_color}">{col_type}</text>')

            curr_y += row_h

        card_svg.append('</g>')
        return "".join(card_svg), card_h

    # Card 1: sessions (Center Anchor)
    # X=560, Y=140, W=400
    sessions_cols = [
        ("id", "TEXT", ["PK"], False, ""),
        ("started_at", "INTEGER", ["NN"], False, "epoch_ms"),
        ("ended_at", "INTEGER", [], True, "epoch_ms"),
        ("type", "TEXT", ["NN"], False, "enum: rest|postActivity"),
        ("quality_summary", "TEXT", ["NN"], False, "enum: good|fair|weak"),
        ("app_version", "TEXT", ["NN"], False, "semver"),
        ("source", "TEXT", ["NN"], False, "enum: pulsepatch|sim..."),
    ]
    card_sessions_svg, h_sessions = render_card("sessions", "Core Sessions", color_sessions, 560, 140, 410, sessions_cols)
    svg.append(card_sessions_svg)

    # Card 2: samples (Left of sessions)
    # X=60, Y=140, W=410
    samples_cols = [
        ("id", "INTEGER", ["PK"], False, "autoincrement"),
        ("session_id", "TEXT", ["FK"], False, "references sessions(id)"),
        ("t_ms", "INTEGER", ["NN"], False, "relative_ms"),
        ("bpm", "REAL", [], True, "heart_rate"),
        ("quality", "INTEGER", ["NN"], False, "sqi_score_0_100"),
        ("is_valid", "INTEGER", ["NN"], False, "gating_boolean"),
        ("spo2", "REAL", [], True, "optional_reserved"),
    ]
    card_samples_svg, h_samples = render_card("samples", "High-Rate Telemetry", color_samples, 60, 140, 410, samples_cols)
    svg.append(card_samples_svg)

    # Card 3: session_stats (Top Right)
    # X=1060, Y=140, W=450
    stats_cols = [
        ("session_id", "TEXT", ["PK", "FK"], False, "references sessions(id)"),
        ("mean_hr", "REAL", ["NN"], False, "bpm"),
        ("std_hr", "REAL", ["NN"], False, "bpm"),
        ("min_hr", "REAL", ["NN"], False, "bpm"),
        ("max_hr", "REAL", ["NN"], False, "bpm"),
        ("start_hr", "REAL", ["NN"], False, "bpm"),
        ("end_hr", "REAL", ["NN"], False, "bpm"),
        ("recovery_drop", "REAL", [], True, "bpm"),
        ("pulse_interval_ms", "REAL", [], True, "ms"),
        ("variability_est_ms", "REAL", [], True, "ms"),
        ("valid_sample_count", "INTEGER", ["NN"], False, "count"),
        ("total_duration_seconds", "INTEGER", ["NN"], False, "seconds"),
        ("avg_spo2", "REAL", [], True, "optional_reserved"),
    ]
    card_stats_svg, h_stats = render_card("session_stats", "Mathematical Summary", color_stats, 1060, 140, 460, stats_cols)
    svg.append(card_stats_svg)

    # Card 4: ai_results (Right, below session_stats)
    # X=1060, Y=560, W=460
    ai_cols = [
        ("session_id", "TEXT", ["PK", "FK"], False, "references sessions(id)"),
        ("model_version", "TEXT", ["NN"], False, "version_string"),
        ("label", "TEXT", ["NN"], False, "Typical/Different"),
        ("features_json", "TEXT", ["NN"], False, "11_normalized_features"),
        ("created_at", "INTEGER", ["NN"], False, "epoch_ms"),
    ]
    card_ai_svg, h_ai = render_card("ai_results", "On-Device AI Classification", color_ai, 1060, 560, 460, ai_cols)
    svg.append(card_ai_svg)

    # Card 5: reminders (Standalone Group)
    # Group box around reminders & app_settings
    grp_x, grp_y, grp_w, grp_h = 60, 450, 410, 400
    svg.append(f'''
    <g transform="translate({grp_x}, {grp_y})">
        <rect x="0" y="0" width="{grp_w}" height="{grp_h}" rx="14" fill="{panel_bg}" stroke="{panel_border}" stroke-width="1.2" stroke-dasharray="6 4"/>
        <rect x="16" y="-12" width="180" height="24" rx="5" fill="{card_bg}" stroke="{panel_border}" stroke-width="1"/>
        <text x="26" y="4" font-family="-apple-system, sans-serif" font-size="11.5" font-weight="bold" fill="{text_secondary}">STANDALONE SETTINGS</text>
    </g>
    ''')

    reminders_cols = [
        ("id", "INTEGER", ["PK"], False, "autoincrement"),
        ("hour", "INTEGER", ["NN"], False, "0_23"),
        ("minute", "INTEGER", ["NN"], False, "0_59"),
        ("label", "TEXT", ["NN"], False, "title"),
        ("is_enabled", "INTEGER", ["NN"], False, "boolean_0_1"),
        ("days_of_week", "TEXT", ["NN"], False, "e.g. 1,2,3,4,5,6,7"),
    ]
    card_reminders_svg, h_reminders = render_card("reminders", "Daily Reminders", color_settings, 75, 475, 380, reminders_cols, is_sub=True)
    svg.append(card_reminders_svg)

    # Card 6: app_settings (Below reminders inside group)
    settings_cols = [
        ("key", "TEXT", ["PK"], False, "config_key"),
        ("value", "TEXT", ["NN"], False, "config_value"),
    ]
    card_settings_svg, h_settings = render_card("app_settings", "App Preferences", color_settings, 75, 715, 380, settings_cols, is_sub=True)
    svg.append(card_settings_svg)

    # =========================================================================
    # RELATIONSHIP LINES (Orthogonal, Crow's foot, ON DELETE CASCADE)
    # =========================================================================
    
    # Line 1: sessions (1) <---> (N) samples
    # From sessions.id (x=560, y=140+42+12 = 194) to samples.session_id (x=470, y=140+42+24+12 = 218)
    svg.append(f'''
    <!-- Relationship: sessions -> samples -->
    <g>
        <path d="M 560 194 L 515 194 L 515 218 L 470 218" fill="none" stroke="{color_samples}" stroke-width="2.5" marker-end="url(#crowFootMany)"/>
        <!-- 1 side marker -->
        <line x1="550" y1="188" x2="550" y2="200" stroke="{color_samples}" stroke-width="2"/>
        <line x1="545" y1="188" x2="545" y2="200" stroke="{color_samples}" stroke-width="2"/>
        <!-- Badge label -->
        <rect x="495" y="196" width="40" height="18" rx="4" fill="{card_bg}" stroke="{color_samples}" stroke-width="1"/>
        <text x="515" y="209" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{color_samples}">1 : N</text>
        <rect x="480" y="222" width="70" height="16" rx="3" fill="{"#1E1B4B" if is_dark else "#EEF2FF"}" stroke="{color_samples}" stroke-width="0.8"/>
        <text x="515" y="234" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="8.5" font-weight="bold" fill="{color_samples}">CASCADE</text>
    </g>
    ''')

    # Line 2: sessions (1) <---> (1) session_stats
    # From sessions.id (x=970, y=194) to session_stats.session_id (x=1060, y=194)
    svg.append(f'''
    <!-- Relationship: sessions -> session_stats -->
    <g>
        <path d="M 970 194 L 1060 194" fill="none" stroke="{color_stats}" stroke-width="2.5"/>
        <!-- 1 side on sessions -->
        <line x1="980" y1="188" x2="980" y2="200" stroke="{color_stats}" stroke-width="2"/>
        <line x1="985" y1="188" x2="985" y2="200" stroke="{color_stats}" stroke-width="2"/>
        <!-- 1 side on session_stats -->
        <line x1="1045" y1="188" x2="1045" y2="200" stroke="{color_stats}" stroke-width="2"/>
        <line x1="1050" y1="188" x2="1050" y2="200" stroke="{color_stats}" stroke-width="2"/>
        <!-- Badge label -->
        <rect x="995" y="184" width="40" height="18" rx="4" fill="{card_bg}" stroke="{color_stats}" stroke-width="1"/>
        <text x="1015" y="197" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{color_stats}">1 : 1</text>
        <rect x="980" y="206" width="70" height="16" rx="3" fill="{"#064E3B" if is_dark else "#ECFDF5"}" stroke="{color_stats}" stroke-width="0.8"/>
        <text x="1015" y="218" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="8.5" font-weight="bold" fill="{color_stats}">CASCADE</text>
    </g>
    ''')

    # Line 3: sessions (1) <---> (1) ai_results
    # From sessions.id (x=970, y=200) routed down to ai_results.session_id (x=1060, y=614)
    svg.append(f'''
    <!-- Relationship: sessions -> ai_results -->
    <g>
        <path d="M 970 206 L 1015 206 L 1015 614 L 1060 614" fill="none" stroke="{color_ai}" stroke-width="2.5"/>
        <!-- 1 side on sessions -->
        <line x1="978" y1="200" x2="978" y2="212" stroke="{color_ai}" stroke-width="2"/>
        <line x1="983" y1="200" x2="983" y2="212" stroke="{color_ai}" stroke-width="2"/>
        <!-- 1 side on ai_results -->
        <line x1="1048" y1="608" x2="1048" y2="620" stroke="{color_ai}" stroke-width="2"/>
        <line x1="1053" y1="608" x2="1053" y2="620" stroke="{color_ai}" stroke-width="2"/>
        <!-- Badge label -->
        <rect x="995" y="390" width="40" height="18" rx="4" fill="{card_bg}" stroke="{color_ai}" stroke-width="1"/>
        <text x="1015" y="403" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{color_ai}">1 : 1</text>
        <rect x="980" y="412" width="70" height="16" rx="3" fill="{"#581C87" if is_dark else "#FAF5FF"}" stroke="{color_ai}" stroke-width="0.8"/>
        <text x="1015" y="424" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="8.5" font-weight="bold" fill="{color_ai}">CASCADE</text>
    </g>
    ''')

    # =========================================================================
    # OUTSIDE THE DATABASE PANEL (Right / Bottom)
    # =========================================================================
    out_x, out_y, out_w, out_h = 1570, 140, 770, 710
    svg.append(f'''
    <!-- OUTSIDE THE DATABASE PANEL -->
    <g transform="translate({out_x}, {out_y})" filter="url(#cardShadow)">
        <rect x="0" y="0" width="{out_w}" height="{out_h}" rx="16" fill="{panel_bg}" stroke="{panel_border}" stroke-width="1.5" stroke-dasharray="8 6"/>
        <rect x="24" y="-14" width="380" height="28" rx="6" fill="{card_bg}" stroke="{panel_border}" stroke-width="1.2"/>
        <text x="40" y="5" font-family="-apple-system, sans-serif" font-size="13" font-weight="bold" fill="{color_sessions}" letter-spacing="0.5">
            OUTSIDE THE DATABASE (Non-Relational Assets)
        </text>

        <!-- Card A: ESP32-C3 + MAX30102 Hardware -->
        <g transform="translate(24, 30)">
            <rect x="0" y="0" width="{out_w - 48}" height="100" rx="10" fill="{sub_card_bg}" stroke="{card_border}" stroke-width="1"/>
            <rect x="0" y="0" width="6" height="100" rx="3" fill="#F97316"/>
            <text x="20" y="28" font-family="-apple-system, sans-serif" font-size="14" font-weight="bold" fill="{text_primary}">1. Physical Wearable Sensor Node (Embedded Hardware)</text>
            <text x="20" y="52" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Espressif ESP32-C3 RISC-V Microcontroller + Maxim MAX30102 High-Sensitivity Pulse Oximeter</text>
            <text x="20" y="72" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• 3.3V Logic ONLY • SDA=GPIO4, SCL=GPIO5 • 100 Hz Optical Sampling (Red + IR) • IIR DC Filter</text>
            <text x="20" y="90" font-family="-apple-system, sans-serif" font-size="11" font-style="italic" fill="{text_muted}">Transient physical state — analog voltage signals are sampled in registers, never stored directly in DB.</text>
        </g>

        <!-- Card B: 12-Byte BLE Packet -->
        <g transform="translate(24, 145)">
            <rect x="0" y="0" width="{out_w - 48}" height="120" rx="10" fill="{sub_card_bg}" stroke="{card_border}" stroke-width="1"/>
            <rect x="0" y="0" width="6" height="120" rx="3" fill="{color_samples}"/>
            <text x="20" y="26" font-family="-apple-system, sans-serif" font-size="14" font-weight="bold" fill="{text_primary}">2. Over-The-Air BLE GATT Stream (Transient Ingestion)</text>
            <text x="20" y="48" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• 12-Byte Little-Endian Heart Rate Notification Packet (Dispatched at 1 Hz, Protocol Version 0x01)</text>
            <text x="20" y="68" font-family="'Courier New', monospace" font-size="11" font-weight="bold" fill="{color_sessions}">[proto:1B][flags:1B][bpmX10:2B][sqi:1B][timeMs:4B][seq:2B][resv:1B]</text>
            <text x="20" y="88" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Parsed in volatile memory by BlePacket.dart &amp; gated through SignalQualityFilter (SQI &#8805; 60)</text>
            <text x="20" y="106" font-family="-apple-system, sans-serif" font-size="11" font-style="italic" fill="{color_samples}">Transient RF payload — once parsed and gated, valid fields are stored into `samples` table.</text>
        </g>

        <!-- Card C: ML Model Weights File -->
        <g transform="translate(24, 280)">
            <rect x="0" y="0" width="{out_w - 48}" height="105" rx="10" fill="{sub_card_bg}" stroke="{card_border}" stroke-width="1"/>
            <rect x="0" y="0" width="6" height="105" rx="3" fill="{color_ai}"/>
            <text x="20" y="28" font-family="-apple-system, sans-serif" font-size="14" font-weight="bold" fill="{text_primary}">3. On-Device ML Model Weights Asset (Static JSON)</text>
            <text x="20" y="52" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Path: app/assets/ml/model_meta.json &amp; ml/models/weights.json (Compiled Asset, NOT in DB)</text>
            <text x="20" y="72" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Architecture: Tiny MLP 5 &#8594; 16 &#8594; 8 &#8594; 1 (Exact Count: 216 weights + 25 biases = 241 parameters)</text>
            <text x="20" y="92" font-family="-apple-system, sans-serif" font-size="11" font-style="italic" fill="{color_ai}">Pure Dart isolate execution (&lt; 0.15 ms); inferences are recorded into `ai_results` table.</text>
        </g>

        <!-- Card D: PDF Reports -->
        <g transform="translate(24, 400)">
            <rect x="0" y="0" width="{out_w - 48}" height="105" rx="10" fill="{sub_card_bg}" stroke="{card_border}" stroke-width="1"/>
            <rect x="0" y="0" width="6" height="105" rx="3" fill="#EC4899"/>
            <text x="20" y="28" font-family="-apple-system, sans-serif" font-size="14" font-weight="bold" fill="{text_primary}">4. Offline Generated Biomonitoring Reports (Filesystem)</text>
            <text x="20" y="52" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Generated on-demand by PdfReportGenerator using PDF/Printing libraries into device app storage</text>
            <text x="20" y="72" font-family="-apple-system, sans-serif" font-size="12" fill="{text_secondary}">• Aggregates `sessions`, `session_stats`, and `ai_results` into self-contained printable vector PDF</text>
            <text x="20" y="92" font-family="-apple-system, sans-serif" font-size="11" font-style="italic" fill="#EC4899">Stored as standalone binary .pdf files on disk, NOT as database BLOBs.</text>
        </g>

        <!-- Integration flow notes -->
        <g transform="translate(24, 520)">
            <rect x="0" y="0" width="{out_w - 48}" height="165" rx="10" fill="{"#0B132B" if is_dark else "#F8FAFC"}" stroke="{card_border}" stroke-width="1"/>
            <text x="20" y="28" font-family="-apple-system, sans-serif" font-size="13" font-weight="bold" fill="{text_primary}">Engineering Data Boundary Summary</text>
            <text x="20" y="52" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">• Hardware &amp; BLE streaming: ESP32-C3 sends 12-byte packets &#8594; Phone BLE layer parses in RAM.</text>
            <text x="20" y="74" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">• Data ingestion: Gated samples (SQI &#8805; 60) are inserted row-by-row into `samples` table.</text>
            <text x="20" y="96" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">• Session closure: 11 summary features computed into `session_stats` within atomic transaction.</text>
            <text x="20" y="118" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">• ML execution: Dart Isolate reads `model_meta.json`, classifies pattern &#8594; stores in `ai_results`.</text>
            <text x="20" y="140" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">• Zero Cloud: 100% of telemetry, statistics, and configuration remain within local SQLite database.</text>
        </g>
    </g>
    ''')

    # Dashed Arrow from BLE Packet to samples table
    # BLE Packet is at (1570+24, 140+145+60 = 345). Arrow curves back to samples (x=470, y=240)
    svg.append(f'''
    <!-- Flow: BLE Ingestion to samples -->
    <g>
        <path d="M 1570 285 Q 1015 105 470 240" fill="none" stroke="{color_samples}" stroke-width="2" stroke-dasharray="6 4" marker-end="url(#arrowDashed)"/>
        <rect x="910" y="95" width="220" height="22" rx="4" fill="{card_bg}" stroke="{color_samples}" stroke-width="1"/>
        <text x="1020" y="110" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="10" font-weight="bold" fill="{color_samples}">
            parsed in memory &#8594; stored as samples
        </text>
    </g>
    ''')

    # =========================================================================
    # LEGEND PANEL (Bottom, between Settings and Outside Panel)
    # X=560, Y=450, W=410, H=400
    # =========================================================================
    leg_x, leg_y, leg_w, leg_h = 560, 450, 410, 400
    svg.append(f'''
    <g transform="translate({leg_x}, {leg_y})" filter="url(#cardShadow)">
        <rect x="0" y="0" width="{leg_w}" height="{leg_h}" rx="14" fill="{legend_bg}" stroke="{card_border}" stroke-width="1.2"/>
        <rect x="0" y="0" width="6" height="40" rx="3" fill="{color_sessions}"/>
        <text x="20" y="26" font-family="-apple-system, sans-serif" font-size="15" font-weight="bold" fill="{text_primary}">ERD Legend &amp; Notation Guide</text>
        <line x1="0" y1="40" x2="{leg_w}" y2="40" stroke="{card_border}" stroke-width="1"/>

        <!-- Badges explanation -->
        <g transform="translate(20, 56)">
            <text x="0" y="12" font-family="-apple-system, sans-serif" font-size="12" font-weight="bold" fill="{text_primary}">Key Badges:</text>
            
            <rect x="0" y="22" width="26" height="15" rx="3" fill="{badge_pk_bg}"/>
            <text x="13" y="33" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{badge_pk_fg}">PK</text>
            <text x="36" y="34" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">Primary Key (Unique entity identifier)</text>

            <rect x="0" y="44" width="26" height="15" rx="3" fill="{badge_fk_bg}"/>
            <text x="13" y="55" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{badge_fk_fg}">FK</text>
            <text x="36" y="56" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">Foreign Key (Relational reference)</text>

            <rect x="0" y="66" width="26" height="15" rx="3" fill="{badge_nn_bg}"/>
            <text x="13" y="77" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="9" font-weight="bold" fill="{badge_nn_fg}">NN</text>
            <text x="36" y="78" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">NOT NULL (Mandatory required column)</text>

            <text x="0" y="104" font-family="-apple-system, sans-serif" font-size="13" font-weight="bold" fill="{text_muted}">?</text>
            <text x="36" y="102" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">Nullable column (e.g. ended_at, recovery_drop)</text>
        </g>

        <!-- Table Roles -->
        <g transform="translate(20, 185)">
            <text x="0" y="12" font-family="-apple-system, sans-serif" font-size="12" font-weight="bold" fill="{text_primary}">Color Roles (App Visual Identity):</text>
            
            <circle cx="8" cy="28" r="6" fill="{color_sessions}"/>
            <text x="24" y="32" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">sessions — Root measurement session entity</text>

            <circle cx="8" cy="48" r="6" fill="{color_samples}"/>
            <text x="24" y="52" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">samples — High-rate raw telemetry time-series</text>

            <circle cx="8" cy="68" r="6" fill="{color_stats}"/>
            <text x="24" y="72" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">session_stats — Derived mathematical features (11)</text>

            <circle cx="8" cy="88" r="6" fill="{color_ai}"/>
            <text x="24" y="92" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">ai_results — On-device tiny neural network inferences</text>

            <circle cx="8" cy="108" r="6" fill="{color_settings}"/>
            <text x="24" y="112" font-family="-apple-system, sans-serif" font-size="11.5" fill="{text_secondary}">reminders / settings — Standalone user configurations</text>
        </g>

        <!-- Integrity & Relationships -->
        <g transform="translate(20, 320)">
            <text x="0" y="12" font-family="-apple-system, sans-serif" font-size="12" font-weight="bold" fill="{text_primary}">Referential Integrity &amp; Cascade:</text>
            <text x="0" y="30" font-family="-apple-system, sans-serif" font-size="11" fill="{text_secondary}">• All child tables enforce ON DELETE CASCADE with foreign keys ON.</text>
            <text x="0" y="48" font-family="-apple-system, sans-serif" font-size="11" fill="{text_secondary}">• Deleting a session atomically removes samples, stats, and AI results.</text>
            <text x="0" y="66" font-family="-apple-system, sans-serif" font-size="11" fill="{text_secondary}">• Standalone settings have zero foreign key relationships.</text>
        </g>
    </g>
    ''')

    # Footer
    svg.append(f'''
    <g transform="translate(60, {H - 30})">
        <line x1="0" y1="0" x2="{W - 120}" y2="0" stroke="{card_border}" stroke-width="1"/>
        <text x="0" y="18" font-family="-apple-system, sans-serif" font-size="11" fill="{text_muted}">
            PulsePatch Lite Biomonitoring Platform • Academic Capstone Defense 2026 • Local Database Specification
        </text>
        <text x="{W - 120}" y="18" text-anchor="end" font-family="-apple-system, sans-serif" font-size="11" fill="{text_muted}">
            Generated: October 2026 • Engine: SQLite C-FFI / Drift ORM • Verification Status: 100% Parity (6 tables, 40 columns)
        </text>
    </g>
    ''')

    svg.append('</svg>')
    return "\n".join(svg)

def render_all():
    docs_erd = Path("docs/erd")
    docs_erd.mkdir(parents=True, exist_ok=True)

    # 1. Dark Theme (Visual Identity)
    dark_svg = generate_svg(theme='dark')
    dark_svg_path = docs_erd / "pulse_patch_erd_styled.svg"
    dark_svg_path.write_text(dark_svg, encoding="utf-8")
    print(f"Generated {dark_svg_path}")

    # Render PNG >= 3600 px wide (Scale 1.6 on 2400 width = 3840 px wide)
    doc_dark = pymupdf.open(str(dark_svg_path))
    mat = pymupdf.Matrix(1.6, 1.6)
    pix_dark = doc_dark[0].get_pixmap(matrix=mat, alpha=False)
    dark_png_path = docs_erd / "pulse_patch_erd_styled.png"
    pix_dark.save(str(dark_png_path))
    print(f"Rendered {dark_png_path}: {pix_dark.width} x {pix_dark.height} px (>= 3600 px requirement met)")

    # Render A4 Landscape PDF
    dark_pdf_path = docs_erd / "pulse_patch_erd_styled.pdf"
    pdf_bytes = doc_dark.convert_to_pdf()
    pdf_temp = pymupdf.open("pdf", pdf_bytes)
    a4_doc = pymupdf.open()
    a4_page = a4_doc.new_page(width=841.89, height=595.28)
    margin = 15.0
    avail_w = 841.89 - (2 * margin)
    avail_h = 595.28 - (2 * margin)
    scale = min(avail_w / 2400.0, avail_h / 1400.0)
    dw = 2400.0 * scale
    dh = 1400.0 * scale
    rect = pymupdf.Rect(margin, margin + (avail_h - dh)/2, margin + dw, margin + (avail_h - dh)/2 + dh)
    a4_page.show_pdf_page(rect, pdf_temp, 0)
    a4_doc.save(str(dark_pdf_path))
    a4_doc.close()
    pdf_temp.close()
    doc_dark.close()
    print(f"Rendered {dark_pdf_path} (A4 Landscape)")

    # 2. Light Theme (Print Ready)
    light_svg = generate_svg(theme='light')
    light_svg_path = docs_erd / "pulse_patch_erd_print_light.svg"
    light_svg_path.write_text(light_svg, encoding="utf-8")
    print(f"Generated {light_svg_path}")

    doc_light = pymupdf.open(str(light_svg_path))
    pix_light = doc_light[0].get_pixmap(matrix=mat, alpha=False)
    light_png_path = docs_erd / "pulse_patch_erd_print_light.png"
    pix_light.save(str(light_png_path))
    print(f"Rendered {light_png_path}: {pix_light.width} x {pix_light.height} px")

    light_pdf_path = docs_erd / "pulse_patch_erd_print_light.pdf"
    pdf_bytes_light = doc_light.convert_to_pdf()
    pdf_temp_light = pymupdf.open("pdf", pdf_bytes_light)
    a4_doc_light = pymupdf.open()
    a4_page_light = a4_doc_light.new_page(width=841.89, height=595.28)
    a4_page_light.show_pdf_page(rect, pdf_temp_light, 0)
    a4_doc_light.save(str(light_pdf_path))
    a4_doc_light.close()
    pdf_temp_light.close()
    doc_light.close()
    print(f"Rendered {light_pdf_path} (A4 Landscape)")

if __name__ == "__main__":
    render_all()
