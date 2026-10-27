#!/usr/bin/env python3
"""
tools/verify_styled_erd.py
Extracts table names and column names directly from the generated
docs/erd/pulse_patch_erd_styled.svg using SVG DOM parsing,
and compares them against the real SQLite schema.
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from verify_erd_parity import get_real_sqlite_schema

def extract_from_svg(svg_path: Path) -> dict[str, set[str]]:
    tree = ET.parse(svg_path)
    root = tree.getroot()

    # In our SVG, each card is a <g filter="url(#cardShadow)">
    # It contains:
    # 1. Title and table_name in header:
    #    <text ... text-anchor="end" font-family="'Courier New', monospace" ...>{table_name}</text>
    # 2. Rows:
    #    <text ... font-size="12.5" ...>{col_name}</text>

    erd_schema = {}
    known_tables = {'sessions', 'samples', 'session_stats', 'ai_results', 'reminders', 'app_settings'}

    for g in root.iter('{http://www.w3.org/2000/svg}g'):
        # Check if this <g> contains a table name
        table_name = None
        for text_elem in g.iter('{http://www.w3.org/2000/svg}text'):
            txt = (text_elem.text or "").strip()
            if txt in known_tables:
                table_name = txt
                break
        
        if table_name:
            cols = set()
            for text_elem in g.iter('{http://www.w3.org/2000/svg}text'):
                # Column names have font-size="12.5"
                size = text_elem.attrib.get('font-size')
                if size == '12.5':
                    col_name = (text_elem.text or "").strip()
                    if col_name:
                        cols.add(col_name)
            erd_schema[table_name] = cols

    return erd_schema

def main():
    real_schema = get_real_sqlite_schema()
    svg_path = Path("docs/erd/pulse_patch_erd_styled.svg")
    if not svg_path.exists():
        print(f"Error: {svg_path} not found.")
        sys.exit(1)

    styled_schema = extract_from_svg(svg_path)

    print("================================================================================")
    print("PulsePatch Lite — Styled ERD SVG Parity Verification")
    print("================================================================================")
    print(f"Target SVG:        {svg_path}")
    print(f"Real Tables Count: {len(real_schema)}")
    print(f"ERD Tables Count:  {len(styled_schema)}")
    print("--------------------------------------------------------------------------------")

    all_tables = sorted(set(real_schema.keys()) | set(styled_schema.keys()))
    has_error = False

    for table in all_tables:
        if table not in real_schema:
            print(f"[-] Extra table in styled ERD: {table}")
            has_error = True
            continue
        if table not in styled_schema:
            print(f"[-] Missing table in styled ERD: {table}")
            has_error = True
            continue

        real_cols = real_schema[table]
        styled_cols = styled_schema[table]

        missing = sorted(real_cols - styled_cols)
        extra = sorted(styled_cols - real_cols)

        if missing or extra:
            has_error = True
            print(f"[FAIL] Table '{table}':")
            if missing:
                print(f"       Missing columns: {missing}")
            if extra:
                print(f"       Extra columns:   {extra}")
        else:
            print(f"[PASS] Table '{table}': {len(real_cols)} columns verified exactly from SVG DOM.")

    print("================================================================================")
    if has_error:
        print("VERDICT: FAILED — Discrepancies found.")
        sys.exit(1)
    else:
        print("VERDICT: 100% PARITY — 0 missing and 0 extra tables/columns in styled ERD SVG.")
        print("================================================================================")

if __name__ == "__main__":
    main()
