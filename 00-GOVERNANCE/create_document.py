from pathlib import Path
from datetime import date
import subprocess, html, sys, shutil

if len(sys.argv) < 5:
    print("Usage: python3 create_document.py CODE DOMAIN_FOLDER TITLE STATUS")
    sys.exit(1)

CODE = sys.argv[1]
DOMAIN = sys.argv[2]
TITLE = sys.argv[3]
STATUS = sys.argv[4].upper()

ROOT = Path.home() / "Desktop" / "iKIA-LOGISTICS"
DOC_NAME = f"{CODE}_{TITLE}_v1.0"

domain_path = ROOT / DOMAIN
md_path = domain_path / "02-MARKDOWN" / f"{DOC_NAME}.md"
docx_path = domain_path / "01-DOCS" / STATUS / f"{DOC_NAME}.docx"
archive_path = domain_path / "08-ARCHIVE" / f"{DOC_NAME}.docx"

for p in [md_path.parent, docx_path.parent, archive_path.parent]:
    p.mkdir(parents=True, exist_ok=True)

if not md_path.exists():
    md_path.write_text(f"# {DOC_NAME}\n\n## سند در انتظار تکمیل\n", encoding="utf-8")

md = md_path.read_text(encoding="utf-8")

def md_to_html(md_text):
    out = []
    in_ul = False
    for line in md_text.splitlines():
        s = line.strip()
        if not s:
            if in_ul:
                out.append("</ul>")
                in_ul = False
            continue
        if s.startswith("# "):
            if in_ul: out.append("</ul>"); in_ul = False
            out.append(f"<h1>{html.escape(s[2:])}</h1>")
        elif s.startswith("## "):
            if in_ul: out.append("</ul>"); in_ul = False
            out.append(f"<h2>{html.escape(s[3:])}</h2>")
        elif s.startswith("### "):
            if in_ul: out.append("</ul>"); in_ul = False
            out.append(f"<h3>{html.escape(s[4:])}</h3>")
        elif s.startswith("- "):
            if not in_ul:
                out.append("<ul>")
                in_ul = True
            out.append(f"<li>{html.escape(s[2:])}</li>")
        else:
            if in_ul: out.append("</ul>"); in_ul = False
            out.append(f"<p>{html.escape(s)}</p>")
    if in_ul:
        out.append("</ul>")
    return "\n".join(out)

html_doc = f"""<html>
<head>
<meta charset="utf-8">
<style>
body {{
 direction: rtl;
 font-family: Arial, sans-serif;
 font-size: 14pt;
 line-height: 1.9;
 color: #111827;
 margin: 40px;
}}
h1,h2,h3 {{
 color: #0B1F3A;
}}
ul {{ line-height: 1.8; }}
</style>
</head>
<body>
{md_to_html(md)}
</body>
</html>
"""

tmp_html = Path("/tmp") / f"{DOC_NAME}.html"
tmp_html.write_text(html_doc, encoding="utf-8")

subprocess.run(["textutil", "-convert", "docx", str(tmp_html), "-output", str(docx_path)], check=True)
shutil.copyfile(docx_path, archive_path)

index = ROOT / "00-GOVERNANCE" / "GV-00_Document_Index.csv"
with index.open("a", encoding="utf-8") as f:
    f.write(f"{CODE},{DOMAIN},{TITLE},1.0,{STATUS},{docx_path.relative_to(ROOT)},{date.today()}\n")

print("✅ Markdown:", md_path)
print("✅ DOCX:", docx_path)
print("✅ Archive:", archive_path)
print("✅ Index:", index)

subprocess.run(["open", str(docx_path)])
