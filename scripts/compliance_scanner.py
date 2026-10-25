import os
import re

FORBIDDEN_WORDS = [
    r'\bECG\b',
    r'\bEKG\b',
    r'\bSinus\b',
    r'\bNormal\b',
    r'\bAbnormal\b',
    r'\bHealthy\b',
    r'\bUnhealthy\b',
    r'\bdiagnosis\b',
    r'\barrhythmia\b',
    r'\bclinical\b',
]

TFLITE_TERMS = [
    r'\bTensorFlow\b',
    r'\btflite\b',
    r'\bTFLite\b',
]

EXCLUDED_DIRS = {
    '.git',
    '.dart_tool',
    'build',
    '.pio',
    '.vscode',
    '.idea',
    'venv',
    'env',
    'node_modules',
}

# Master plan specification docs that define the constraints (read-only references)
EXCLUDED_FILES = {
    'compliance_scanner.py',
    'AGENT_PLAN.md',
    'PulsePatch Lite — Master Build Plan for the Engineering Agent.md',
    'compliance_scan_results.md',
}

TARGET_EXTS = {'.dart', '.arb', '.md'}

def scan():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    forbidden_matches = []
    tflite_matches = []

    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS and not d.startswith('.')]

        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext not in TARGET_EXTS or f in EXCLUDED_FILES:
                continue

            file_path = os.path.join(root, f)
            rel_path = os.path.relpath(file_path, root_dir).replace('\\', '/')

            # Only scan relevant folders: app, docs, FINAL_REPORT.md, PROGRESS.md
            if not (rel_path.startswith('app/') or rel_path.startswith('docs/') or rel_path in ['FINAL_REPORT.md', 'PROGRESS.md']):
                continue

            with open(file_path, 'r', encoding='utf-8', errors='ignore') as fp:
                for line_num, line in enumerate(fp, 1):
                    stripped = line.strip()
                    for pat in FORBIDDEN_WORDS:
                        if re.search(pat, stripped, re.IGNORECASE):
                            forbidden_matches.append({
                                'file': rel_path,
                                'line': line_num,
                                'pattern': pat,
                                'content': stripped
                            })
                    for pat in TFLITE_TERMS:
                        if re.search(pat, stripped, re.IGNORECASE):
                            tflite_matches.append({
                                'file': rel_path,
                                'line': line_num,
                                'pattern': pat,
                                'content': stripped
                            })

    out_path = os.path.join(root_dir, 'docs', 'compliance_scan_results.md')
    with open(out_path, 'w', encoding='utf-8') as out:
        out.write("# PulsePatch Lite — Compliance & Forbidden Wording Audit Scan\n\n")
        out.write(f"**Total Forbidden Word Occurrences Found:** {len(forbidden_matches)}\n")
        out.write(f"**Total TensorFlow / TFLite References Found:** {len(tflite_matches)}\n\n")

        out.write("## 1. Forbidden Wording Matches\n\n")
        out.write("| # | Term | File:Line | Context Snippet |\n")
        out.write("|---|---|---|---|\n")
        for idx, m in enumerate(forbidden_matches, 1):
            clean_content = m['content'].replace('|', '\\|')
            out.write(f"| {idx} | `{m['pattern']}` | `{m['file']}:{m['line']}` | `{clean_content}` |\n")

        out.write("\n## 2. TensorFlow / TFLite References (to replace with 'small neural network running locally in the app')\n\n")
        out.write("| # | Term | File:Line | Context Snippet |\n")
        out.write("|---|---|---|---|\n")
        for idx, m in enumerate(tflite_matches, 1):
            clean_content = m['content'].replace('|', '\\|')
            out.write(f"| {idx} | `{m['pattern']}` | `{m['file']}:{m['line']}` | `{clean_content}` |\n")

    print(f"Scan complete. Wrote results to {out_path}")
    print(f"Forbidden word occurrences: {len(forbidden_matches)}")
    print(f"TFLite/TensorFlow references: {len(tflite_matches)}")

if __name__ == '__main__':
    scan()
