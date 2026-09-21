"""Tiny pixel-art drawing toolkit used to author GRIDHEART's sprites.

Everything is drawn on integer pixel grids with an explicit palette, then
given a hard 1px outline, so the whole set shares one handmade look.
"""
import math
from PIL import Image

T = None  # transparent


class C:
    OUT    = (30, 23, 38)
    OUT_S  = (58, 45, 66)

    SKIN   = (247, 206, 164); SKIN_D = (206, 150, 112); SKIN_L = (255, 234, 204)
    HAIR   = (236, 174, 88);  HAIR_D = (168, 104, 52)
    TUNIC  = (112, 186, 136); TUNIC_D = (58, 122, 94);  TUNIC_L = (168, 220, 170)
    PANTS  = (92, 84, 122);   PANTS_D = (56, 50, 84)
    LEATH  = (158, 106, 66);  LEATH_D = (102, 62, 44)
    STEEL  = (208, 216, 234); STEEL_D = (134, 146, 174); STEEL_K = (86, 94, 120)
    GOLD   = (246, 202, 106); GOLD_D = (190, 140, 62)

    SLIME  = (128, 208, 152); SLIME_D = (74, 152, 106); SLIME_L = (196, 240, 198)
    GOB    = (146, 190, 98);  GOB_D  = (92, 134, 62)
    RED    = (202, 92, 88);   RED_D  = (142, 56, 62)
    BONE   = (240, 234, 212); BONE_D = (176, 166, 146)
    PURP   = (152, 112, 192); PURP_D = (98, 70, 134)
    DUSK   = (120, 100, 156); DUSK_D = (76, 62, 104)

    FLOOR  = (98, 86, 102);   FLOOR_L = (116, 103, 120); FLOOR_D = (80, 70, 86)
    WALL   = (76, 62, 80);    WALL_L = (99, 81, 101);    WALL_D = (52, 42, 56)
    WALLTOP = (58, 47, 62)
    CREAM  = (246, 228, 192); CREAM_D = (206, 182, 146); CREAM_L = (255, 245, 222)
    RUST   = (176, 104, 72)
    EMBER  = (248, 176, 88)
    VENOM  = (132, 206, 108); VENOM_D = (74, 146, 68)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[T] * w for _ in range(h)]

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if c is T or 0 <= x < self.w and 0 <= y < self.h:
            if 0 <= x < self.w and 0 <= y < self.h:
                self.p[y][x] = c

    def get(self, x, y):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[y][x]
        return T

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.set(x, y, c)

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                dx = (x - cx) / max(rx, 0.001)
                dy = (y - cy) / max(ry, 0.001)
                if dx * dx + dy * dy <= 1.05:
                    self.set(x, y, c)

    def blob(self, cx, cy, rx, ry, c):
        """Slightly squarer than an ellipse - reads better at small sizes."""
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                dx = abs(x - cx) / max(rx, 0.001)
                dy = abs(y - cy) / max(ry, 0.001)
                if dx ** 2.4 + dy ** 2.4 <= 1.02:
                    self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0)))
        for i in range(n + 1):
            t = i / max(n, 1)
            self.set(round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), c)

    def replace(self, a, b):
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] == a:
                    self.p[y][x] = b

    def outline(self, c=C.OUT):
        """Wrap the silhouette in a 1px dark border (4-neighbourhood + corners)."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] is not T:
                    continue
                touching = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = self.get(x + dx, y + dy)
                    if n is not T and n != c:
                        touching = True
                        break
                if touching:
                    add.append((x, y))
        for x, y in add:
            self.p[y][x] = c

    def shade_bottom(self, src, dst):
        """Darken the lowest pixel of each column of a given colour."""
        for x in range(self.w):
            run = [y for y in range(self.h) if self.p[y][x] == src]
            if run:
                self.p[run[-1]][x] = dst

    def copy(self):
        n = Canvas(self.w, self.h)
        n.p = [row[:] for row in self.p]
        return n

    def paste(self, other, ox=0, oy=0):
        for y in range(other.h):
            for x in range(other.w):
                c = other.p[y][x]
                if c is not T:
                    self.set(x + ox, y + oy, c)

    def offset(self, dx, dy):
        n = Canvas(self.w, self.h)
        n.paste(self, dx, dy)
        return n

    def flip(self):
        n = Canvas(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                n.p[y][self.w - 1 - x] = self.p[y][x]
        return n

    def to_image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        px = img.load()
        for y in range(self.h):
            for x in range(self.w):
                c = self.p[y][x]
                if c is not T:
                    px[x, y] = c if len(c) == 4 else (c[0], c[1], c[2], 255)
        return img


def strip(frames, path):
    """Write a horizontal sprite strip; frame size is inferred from height."""
    w, h = frames[0].w, frames[0].h
    img = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        img.paste(f.to_image(), (i * w, 0))
    img.save(path)
    return path


def sheet(tiles, cols, path):
    w, h = tiles[0].w, tiles[0].h
    rows = math.ceil(len(tiles) / cols)
    img = Image.new("RGBA", (w * cols, h * rows), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        img.paste(t.to_image(), ((i % cols) * w, (i // cols) * h))
    img.save(path)
    return path
