#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/
BASE="/opt/cmaptools"
CMAP="$BASE/CmapTools"
CMAP_IMAGE="$BASE/cmap-logo.png"
if ! test -f $CMAP ; then
  echo "Please install CmapTools in '$BASE' directory"
  exit 1
fi

if ! test -f $CMAP_IMAGE ; then
  echo "Please download CmapTools logo and save as 'cmap-logo.png' in '$BASE' directory"
  exit 1
fi

echo "[Desktop Entry]
Type=Application
Name=Cmap Tools
Comment='Create Concept Maps'
Icon='$CMAP_IMAGE'
Exec='$CMAP'
Terminal=false
Categories=Education;Concept;Modeling" > "/usr/share/applications/CmapTools.desktop"
