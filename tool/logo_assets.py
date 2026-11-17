#!/usr/bin/env python3
"""Génère les logos à fond transparent de l'app à partir du logo source.

Le logo source (`design/logo.jpg` du dépôt dev) est un JPEG sur fond blanc :
affiché tel quel, il ferait un rectangle blanc en mode sombre. Ce script
« démélange » chaque pixel : il le lit comme une couleur du logo (vert, bleu,
jaune ou gris) posée sur du blanc avec une certaine opacité, et rend cette
couleur exacte avec cette opacité. Les bords restent lissés, les aplats
retrouvent la couleur pure du logo, et le bruit JPEG du fond disparaît.

Deux fichiers sont produits, recadrés au plus près du dessin :
- `logo.png` : les couleurs du logo, pour les fonds clairs ;
- `logo_dark.png` : le même, texte gris éclairci, pour les fonds sombres.

Usage (macOS, la conversion passe par `sips`), depuis `app/` :

    python3 -I tool/logo_assets.py ../design/logo.jpg assets/brand
"""

import os
import struct
import subprocess
import sys
import tempfile
import zlib

WHITE = (255, 255, 255)

# Couleurs relevées sur le logo (médiane des pixels de chaque trait).
BRAND = {
    "green": (0x8C, 0xD3, 0x5F),
    "blue": (0x29, 0xD3, 0xFF),
    "yellow": (0xFD, 0xD0, 0x14),
    "grey": (0x51, 0x51, 0x50),
}

# Texte du logo sur fond sombre : le gris secondaire du thème sombre de l'app.
DARK_TEXT = (0xC6, 0xC6, 0xC6)

# En deçà, c'est du bruit JPEG ; au-delà, c'est un aplat plein.
MIN_ALPHA = 0.06
MAX_ALPHA = 0.94
MARGIN = 12


def read_jpeg(path):
    """Pixels RGB (lignes de haut en bas) via une conversion BMP par sips."""
    with tempfile.TemporaryDirectory() as tmp:
        bmp = os.path.join(tmp, "logo.bmp")
        subprocess.run(["sips", "-s", "format", "bmp", path, "--out", bmp], check=True, capture_output=True)
        data = open(bmp, "rb").read()
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    step = struct.unpack_from("<H", data, 28)[0] // 8
    row_size = (width * step + 3) // 4 * 4
    rows = []
    for y in range(abs(height)):
        start = offset + y * row_size
        row = data[start:start + width * step]
        rows.append([(row[x * step + 2], row[x * step + 1], row[x * step]) for x in range(width)])
    if height > 0:  # BMP classique : lignes de bas en haut
        rows.reverse()
    return width, abs(height), rows


def unmix(pixel):
    """La couleur du logo et l'opacité qui, posées sur du blanc, donnent ce pixel."""
    v = [255 - c for c in pixel]
    best = None
    for name, color in BRAND.items():
        d = [255 - c for c in color]
        alpha = sum(a * b for a, b in zip(v, d)) / sum(b * b for b in d)
        alpha = min(1.0, max(0.0, alpha))
        residual = sum((a - alpha * b) ** 2 for a, b in zip(v, d))
        if best is None or residual < best[2]:
            best = (name, alpha, residual)
    name, alpha = best[0], best[1]
    if alpha < MIN_ALPHA:
        return None, 0.0
    return name, 1.0 if alpha > MAX_ALPHA else alpha


def write_png(path, width, height, rows):
    def chunk(kind, payload):
        body = kind + payload
        return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + bytes(channel for px in row for channel in px) for row in rows)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as out:
        out.write(png)


def main(source, out_dir):
    width, height, rows = read_jpeg(source)
    layers = [[unmix(px) for px in row] for row in rows]

    covered = [(x, y) for y, row in enumerate(layers) for x, (_, a) in enumerate(row) if a > 0]
    left = max(0, min(x for x, _ in covered) - MARGIN)
    right = min(width, max(x for x, _ in covered) + MARGIN + 1)
    top = max(0, min(y for _, y in covered) - MARGIN)
    bottom = min(height, max(y for _, y in covered) + MARGIN + 1)

    os.makedirs(out_dir, exist_ok=True)
    for filename, palette in (("logo.png", BRAND), ("logo_dark.png", {**BRAND, "grey": DARK_TEXT})):
        cropped = [
            [(*palette[name], round(a * 255)) if name else (0, 0, 0, 0) for name, a in row[left:right]]
            for row in layers[top:bottom]
        ]
        write_png(os.path.join(out_dir, filename), right - left, bottom - top, cropped)
        print(f"{filename} : {right - left}×{bottom - top}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
