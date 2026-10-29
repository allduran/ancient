#!/usr/bin/env python3
# Uso: python3 scripts/gen-cursors.py assets/cursors/Ancient   (necesita python-pillow)
# Genera el tema de cursor "Ancient" (Xcursor) — dorado, al estilo de ancient. Original.
import os, struct, math, sys
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
SIZES = [24, 32, 48, 64]
SS = 8                      # supermuestreo
U = 32.0                    # cuadrícula de diseño 32×32

GOLD = [(255, 241, 204), (230, 199, 126), (201, 164, 92), (122, 98, 50)]
DARK = (20, 14, 6, 255)

def grad(sz):
    img = Image.new("RGBA", (sz, sz))
    px = img.load()
    for y in range(sz):
        t = y / (sz - 1)
        if t < 0.35: a, b, k = GOLD[0], GOLD[1], t / 0.35
        elif t < 0.7: a, b, k = GOLD[1], GOLD[2], (t - 0.35) / 0.35
        else: a, b, k = GOLD[2], GOLD[3], (t - 0.7) / 0.3
        c = tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3)) + (255,)
        for x in range(sz): px[x, y] = c
    return img

def canvas(size):
    return Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))

def P(size, pts):
    s = size * SS / U
    return [(x * s, y * s) for x, y in pts]

def W(size, w):
    return max(1, int(w * size * SS / U))

def gold_shape(size, draw_fn, outline=2.2):
    """draw_fn(draw, size, fill, width_extra) dibuja la forma; se rellena en oro con borde oscuro."""
    sz = size * SS
    base = canvas(size)
    d = ImageDraw.Draw(base)
    draw_fn(d, size, DARK, W(size, outline))          # borde oscuro (forma engordada)
    mask = Image.new("L", (sz, sz), 0)
    draw_fn(ImageDraw.Draw(mask), size, 255, 0)       # forma
    g = grad(sz)
    base.paste(g, (0, 0), mask)
    return base

def arrow_pts():
    return [(2, 2), (2, 25), (8, 19.5), (12.2, 29), (16.4, 27.2), (12.4, 17.8), (20.5, 17.8)]

def draw_arrow(d, size, fill, extra):
    pts = P(size, arrow_pts())
    d.polygon(pts, fill=fill)
    if extra: d.line(pts + [pts[0]], fill=fill, width=extra, joint="curve")

def arrow(size, sparkle=False):
    img = gold_shape(size, draw_arrow)
    d = ImageDraw.Draw(img)
    # brillo del borde izquierdo
    d.line(P(size, [(3.6, 6), (3.6, 21)]), fill=(255, 250, 230, 200), width=W(size, 0.9))
    if sparkle:   # rombo brillante: "se puede hacer clic"
        c = P(size, [(23, 23)])[0]; r = size * SS / U * 4.2
        dia = [(c[0], c[1] - r), (c[0] + r * 0.7, c[1]), (c[0], c[1] + r), (c[0] - r * 0.7, c[1])]
        d.polygon(dia, fill=DARK)
        r2 = r * 0.62
        dia2 = [(c[0], c[1] - r2), (c[0] + r2 * 0.7, c[1]), (c[0], c[1] + r2), (c[0] - r2 * 0.7, c[1])]
        d.polygon(dia2, fill=(143, 194, 127, 255))
    return img, (2, 2)

def ibeam(size):
    def f(d, size, fill, extra):
        w = W(size, 2.4) + extra
        d.line(P(size, [(16, 5), (16, 27)]), fill=fill, width=w)
        d.line(P(size, [(11, 5), (21, 5)]), fill=fill, width=w)
        d.line(P(size, [(11, 27), (21, 27)]), fill=fill, width=w)
    return gold_shape(size, f, 1.6), (16, 16)

def crosshair(size):
    def f(d, size, fill, extra):
        w = W(size, 2.2) + extra
        for a, b in [((16, 3), (16, 12)), ((16, 20), (16, 29)), ((3, 16), (12, 16)), ((20, 16), (29, 16))]:
            d.line(P(size, [a, b]), fill=fill, width=w)
        c = P(size, [(16, 16)])[0]; r = size * SS / U * 1.6 + extra / 2
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill)
    return gold_shape(size, f, 1.6), (16, 16)

def arrows(size, kind):
    # flechas dobles / cuádruple
    def head(d, size, tip, ang, fill, extra):
        L, Wd = 6.5, 5.2
        x, y = tip
        bx, by = x - L * math.cos(ang), y - L * math.sin(ang)
        px, py = -math.sin(ang), math.cos(ang)
        pts = P(size, [(x, y), (bx + px * Wd, by + py * Wd), (bx - px * Wd, by - py * Wd)])
        d.polygon(pts, fill=fill)
        if extra: d.line(pts + [pts[0]], fill=fill, width=extra, joint="curve")
    def f(d, size, fill, extra):
        w = W(size, 2.6) + extra
        dirs = {"h": [0, math.pi], "v": [math.pi / 2, -math.pi / 2],
                "d1": [math.pi / 4, -3 * math.pi / 4], "d2": [3 * math.pi / 4, -math.pi / 4],
                "all": [0, math.pi / 2, math.pi, -math.pi / 2]}[kind]
        R = 13 if kind != "all" else 13.5
        for a in dirs:
            tip = (16 + R * math.cos(a), 16 + R * math.sin(a))
            d.line(P(size, [(16, 16), tip]), fill=fill, width=w)
            head(d, size, tip, a, fill, extra)
    return gold_shape(size, f, 1.6), (16, 16)

def forbidden(size):
    img = canvas(size); d = ImageDraw.Draw(img)
    c = P(size, [(16, 16)])[0]; s = size * SS / U
    for r, col, w in [(12.5, DARK, 5.2), (12.5, (200, 70, 58, 255), 2.8)]:
        d.ellipse([c[0] - r * s, c[1] - r * s, c[0] + r * s, c[1] + r * s], outline=col, width=int(w * s))
        d.line(P(size, [(7.5, 7.5), (24.5, 24.5)]), fill=col, width=int(w * s))
    return img, (16, 16)

def spinner(size, frame, n=8, small=False):
    img = canvas(size); d = ImageDraw.Draw(img); s = size * SS / U
    cx, cy, R, r = (16, 16, 10, 3.0) if not small else (24, 24, 5.5, 1.7)
    for i in range(n):
        a = 2 * math.pi * i / n - math.pi / 2
        k = ((i - frame) % n) / n
        col = tuple(int(GOLD[1][j] * (1 - k) + GOLD[3][j] * k) for j in range(3)) + (int(255 * (1 - 0.65 * k)),)
        x, y = (cx + R * math.cos(a)) * s, (cy + R * math.sin(a)) * s
        rr = r * s
        d.ellipse([x - rr - s * 0.7, y - rr - s * 0.7, x + rr + s * 0.7, y + rr + s * 0.7], fill=DARK)
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col)
    return img

def finish(img, size):
    return img.resize((size, size), Image.LANCZOS)

def argb(img):
    out = bytearray()
    for r, g, b, a in img.getdata():
        out += struct.pack("<I", (a << 24) | ((r * a // 255) << 16) | ((g * a // 255) << 8) | (b * a // 255))
    return bytes(out)

def write_cursor(name, frames_fn, nframes=1, delay=0):
    """frames_fn(size, i) -> (img_supermuestreada, hot en cuadrícula 32)"""
    chunks = []
    for size in SIZES:
        for i in range(nframes):
            img, hot = frames_fn(size, i)
            im = finish(img, size)
            hx, hy = [min(size - 1, int(round(h * size / U))) for h in hot]
            hdr = struct.pack("<9I", 36, 0xfffd0002, size, 1, size, size, hx, hy, delay)
            chunks.append((size, hdr + argb(im)))
    ntoc = len(chunks)
    pos = 16 + ntoc * 12
    toc, data = b"", b""
    for size, ch in chunks:
        toc += struct.pack("<3I", 0xfffd0002, size, pos)
        pos += len(ch); data += ch
    with open(os.path.join(OUT, "cursors", name), "wb") as f:
        f.write(b"Xcur" + struct.pack("<3I", 16, 0x10000, ntoc) + toc + data)

def link(target, *names):
    for n in names:
        p = os.path.join(OUT, "cursors", n)
        if os.path.lexists(p): os.remove(p)
        os.symlink(target, p)

os.makedirs(os.path.join(OUT, "cursors"), exist_ok=True)
with open(os.path.join(OUT, "index.theme"), "w") as f:
    f.write("[Icon Theme]\nName=Ancient\nComment=Cursor dorado de ancient (Quickshell, estilo Dota)\nInherits=Adwaita\n")

write_cursor("left_ptr", lambda s, i: arrow(s))
link("left_ptr", "default", "arrow", "top_left_arrow", "context-menu", "copy", "alias", "cell", "help", "question_arrow", "dnd-none", "dnd-move", "dnd-copy", "vertical-text")
write_cursor("pointer", lambda s, i: arrow(s, sparkle=True))
link("pointer", "hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822")
write_cursor("text", lambda s, i: ibeam(s))
link("text", "xterm", "ibeam")
write_cursor("crosshair", lambda s, i: crosshair(s))
link("crosshair", "cross", "tcross", "cross_reverse", "diamond_cross")
write_cursor("not-allowed", lambda s, i: forbidden(s))
link("not-allowed", "no-drop", "crossed_circle", "forbidden", "circle", "03b6e0fcb3499374a867c041f52298f0")
write_cursor("move", lambda s, i: arrows(s, "all"))
link("move", "fleur", "all-scroll", "grab", "grabbing", "closedhand", "openhand", "size_all", "dnd-ask")
write_cursor("ew-resize", lambda s, i: arrows(s, "h"))
link("ew-resize", "sb_h_double_arrow", "col-resize", "e-resize", "w-resize", "h_double_arrow", "size_hor", "split_h", "left_side", "right_side")
write_cursor("ns-resize", lambda s, i: arrows(s, "v"))
link("ns-resize", "sb_v_double_arrow", "row-resize", "n-resize", "s-resize", "v_double_arrow", "size_ver", "split_v", "top_side", "bottom_side")
write_cursor("nwse-resize", lambda s, i: arrows(s, "d1"))
link("nwse-resize", "nw-resize", "se-resize", "bd_double_arrow", "size_fdiag", "top_left_corner", "bottom_right_corner")
write_cursor("nesw-resize", lambda s, i: arrows(s, "d2"))
link("nesw-resize", "ne-resize", "sw-resize", "fd_double_arrow", "size_bdiag", "top_right_corner", "bottom_left_corner")
write_cursor("wait", lambda s, i: (spinner(s, i), (16, 16)), 8, 80)
link("wait", "watch")
def progress(s, i):
    a, _ = arrow(s)
    a.alpha_composite(spinner(s, i, small=True))
    return a, (2, 2)
write_cursor("progress", progress, 8, 80)
link("progress", "left_ptr_watch", "half-busy", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599")
print("ok")
