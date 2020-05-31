#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/
ADDR="$HOME/.AppImage"
mkdir $ADDR

cp ~/Downloads/*.AppImage "$ADDR/"
chmod u+x "$ADDR/*.AppImage"

echo "[Desktop Entry]
Type=Application
Name=StarUML
Comment='A sophisticated software modeler for agile and concise modeling'
Icon='$ADDR/StarUML.png'
Exec='$ADDR/StarUML-3.2.2.AppImage'
Terminal=false
Categories=Development;UML;Modeling" > "~/.local/share/applications/StarUML.desktop"
