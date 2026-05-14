import os
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).parent
SRC  = ROOT / "appicon.png"
DEST = ROOT / "windows/runner/resources/app_icon.ico"

img = Image.open(SRC).convert("RGBA")

# Just save as ICO directly
img.save(DEST, format="ICO")
print("Saved raw image to ICO")
