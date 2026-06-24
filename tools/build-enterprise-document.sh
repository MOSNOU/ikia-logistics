#!/bin/bash

ROOT="$HOME/Desktop/iKIA-LOGISTICS"

if [ $# -lt 4 ]; then
  echo ""
  echo "Usage:"
  echo "build-enterprise-document DOMAIN CODE TITLE VERSION"
  echo ""
  echo "Example:"
  echo "build-enterprise-document 00-GOVERNANCE GV-00 Enterprise_Founding_Reality v1.0"
  exit 1
fi

DOMAIN=$1
CODE=$2
TITLE=$3
VERSION=$4

MD="$ROOT/$DOMAIN/02-MARKDOWN/${CODE}_${TITLE}_${VERSION}.md"
DOCX="$ROOT/$DOMAIN/01-DOCS/DRAFT/${CODE}_${TITLE}_${VERSION}.docx"

mkdir -p "$ROOT/$DOMAIN/01-DOCS/DRAFT"
mkdir -p "$ROOT/$DOMAIN/02-MARKDOWN"

if [ ! -f "$MD" ]; then
cat > "$MD" <<EOF
# ${CODE}_${TITLE}_${VERSION}

Status: Draft

Document Created Automatically

EOF
fi

TMPHTML="/tmp/${CODE}_${TITLE}.html"

cat > "$TMPHTML" <<EOF
<html>
<head>
<meta charset="utf-8">
<style>
body{
direction:rtl;
font-family:Arial;
font-size:14pt;
margin:40px;
line-height:1.9;
}
h1,h2,h3{
color:#0B1F3A;
}
</style>
</head>
<body>
<pre>
$(cat "$MD")
</pre>
</body>
</html>
EOF

textutil -convert docx "$TMPHTML" -output "$DOCX"

echo ""
echo "================================="
echo "DOCUMENT GENERATED"
echo "================================="
echo "$MD"
echo "$DOCX"
echo ""

open "$MD"
open "$DOCX"

