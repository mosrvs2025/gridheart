"""HP-grid cell tiles, room tiles, effects and the boss."""
import math
from pixel import Canvas, C, T

CELL = 12
TILE = 16


# ---------------------------------------------------------------- HP cells
def _cell_base(face, light, dark, border):
    cv = Canvas(CELL, CELL)
    cv.rect(1, 1, 10, 10, face)
    cv.rect(0, 2, 0, 9, border)
    cv.rect(11, 2, 11, 9, border)
    cv.rect(2, 0, 9, 0, border)
    cv.rect(2, 11, 9, 11, border)
    for x, y in ((1, 1), (10, 1), (1, 10), (10, 10)):
        cv.set(x, y, border)
    cv.rect(2, 2, 8, 2, light)
    cv.rect(2, 3, 2, 8, light)
    cv.rect(3, 9, 9, 9, dark)
    cv.rect(9, 3, 9, 9, dark)
    return cv


def cell_normal():
    cv = _cell_base(C.CREAM, C.CREAM_L, C.CREAM_D, C.OUT)
    cv.set(4, 4, C.CREAM_L)
    cv.set(5, 4, C.CREAM_L)
    return cv


def cell_cracked():
    cv = cell_normal()
    cv.line(4, 2, 5, 5, C.CREAM_D)
    cv.line(5, 5, 3, 7, C.CREAM_D)
    cv.line(5, 5, 8, 8, C.CREAM_D)
    cv.set(5, 5, C.OUT_S)
    cv.set(4, 3, C.OUT_S)
    return cv


def cell_armor():
    cv = _cell_base(C.STEEL_D, C.STEEL, C.STEEL_K, C.OUT)
    cv.line(3, 7, 5, 4, C.STEEL)
    cv.line(5, 4, 8, 7, C.STEEL)
    cv.line(3, 8, 5, 5, C.STEEL_K)
    cv.line(5, 5, 8, 8, C.STEEL_K)
    for x, y in ((2, 2), (9, 2), (2, 9), (9, 9)):
        cv.set(x, y, C.GOLD_D)
    return cv


def cell_armor_cracked():
    cv = cell_armor()
    cv.line(6, 1, 5, 5, C.OUT_S)
    cv.line(5, 5, 7, 9, C.OUT_S)
    cv.set(4, 4, C.STEEL_K)
    return cv


def cell_empty():
    cv = Canvas(CELL, CELL)
    cv.rect(1, 1, 10, 10, (44, 35, 52))
    cv.rect(0, 2, 0, 9, C.OUT)
    cv.rect(11, 2, 11, 9, C.OUT)
    cv.rect(2, 0, 9, 0, C.OUT)
    cv.rect(2, 11, 9, 11, C.OUT)
    for x, y in ((1, 1), (10, 1), (1, 10), (10, 10)):
        cv.set(x, y, C.OUT)
    cv.rect(2, 2, 8, 2, (32, 25, 40))
    cv.rect(2, 3, 2, 8, (32, 25, 40))
    cv.rect(3, 9, 9, 9, (58, 47, 68))
    cv.rect(9, 3, 9, 9, (58, 47, 68))
    return cv


def cell_poison(frame):
    """Overlay drawn on top of a cell."""
    cv = Canvas(CELL, CELL)
    cv.rect(1, 1, 10, 10, C.VENOM_D)
    drip = ((3, 3), (7, 4), (5, 7), (8, 8), (2, 6))
    for i, (x, y) in enumerate(drip):
        if (i + frame) % 3:
            cv.set(x, (y + frame) % 9 + 1, C.VENOM)
            cv.set(x + 1, (y + frame) % 9 + 1, C.VENOM)
    cv.set(4, 2 + frame % 2, C.SLIME_L)
    cv.set(8, 6 - frame % 2, C.SLIME_L)
    return cv


def cell_marker():
    """Placement / damage-preview frame."""
    cv = Canvas(CELL, CELL)
    for x in range(1, 11):
        if x % 2:
            cv.set(x, 0, C.CREAM_L)
            cv.set(x, 11, C.CREAM_L)
    for y in range(1, 11):
        if y % 2:
            cv.set(0, y, C.CREAM_L)
            cv.set(11, y, C.CREAM_L)
    for x, y in ((0, 0), (11, 0), (0, 11), (11, 11)):
        cv.set(x, y, C.CREAM_L)
    return cv


# ---------------------------------------------------------------- room tiles
def floor_tile(v):
    cv = Canvas(TILE, TILE)
    cv.rect(0, 0, 15, 15, C.FLOOR)
    cv.hline(0, 15, 0, C.FLOOR_L)
    cv.vline(0, 0, 15, C.FLOOR_L)
    cv.hline(0, 15, 15, C.FLOOR_D)
    cv.vline(15, 0, 15, C.FLOOR_D)
    rnd = [(3, 4), (9, 2), (12, 9), (5, 11), (7, 7), (2, 13), (13, 5), (10, 13)]
    for i, (x, y) in enumerate(rnd):
        if (i * 7 + v * 5) % 4 == 0:
            cv.set(x, y, C.FLOOR_D)
            cv.set(x + 1, y, C.FLOOR_D)
        elif (i * 3 + v) % 5 == 0:
            cv.set(x, y, C.FLOOR_L)
    if v == 3:
        cv.line(2, 12, 6, 8, C.FLOOR_D)
        cv.line(6, 8, 9, 9, C.FLOOR_D)
    if v == 2:
        cv.rect(5, 5, 7, 6, C.FLOOR_D)
        cv.set(5, 5, C.FLOOR)
    return cv


def wall_top():
    cv = Canvas(TILE, TILE)
    cv.rect(0, 0, 15, 15, C.WALLTOP)
    for x in range(0, 16, 4):
        cv.vline(x, 0, 15, (50, 40, 54))
    cv.hline(0, 15, 7, (50, 40, 54))
    return cv


def wall_face():
    cv = Canvas(TILE, TILE)
    cv.rect(0, 0, 15, 15, C.WALL)
    cv.hline(0, 15, 0, C.WALL_L)
    for bx, by in ((0, 2), (8, 2), (4, 7), (12, 7), (0, 12), (8, 12)):
        cv.rect(bx, by, bx + 7, by + 4, C.WALL)
        cv.hline(bx, bx + 7, by, C.WALL_L)
        cv.hline(bx, bx + 7, by + 4, C.WALL_D)
        cv.vline(bx, by, by + 4, C.WALL_D)
    cv.hline(0, 15, 15, C.WALL_D)
    return cv


def wall_cap():
    """Top lip of a wall - the bit that catches the light."""
    cv = wall_face()
    cv.rect(0, 0, 15, 3, C.WALLTOP)
    cv.hline(0, 15, 3, (42, 34, 46))
    cv.hline(0, 15, 4, C.WALL_L)
    return cv


def pillar():
    cv = Canvas(TILE, TILE)
    cv.rect(3, 3, 12, 13, C.WALL)
    cv.vline(4, 4, 12, C.WALL_L)
    cv.vline(5, 4, 12, C.WALL_L)
    cv.vline(11, 4, 12, C.WALL_D)
    cv.rect(2, 1, 13, 3, C.WALL_L)
    cv.hline(2, 13, 0, C.WALLTOP)
    cv.hline(2, 13, 1, C.WALLTOP)
    cv.rect(2, 13, 13, 15, C.WALL_L)
    cv.hline(2, 13, 15, C.WALL_D)
    cv.hline(3, 12, 8, C.WALL_D)
    cv.outline()
    return cv


def crate():
    cv = Canvas(TILE, TILE)
    cv.rect(2, 3, 13, 14, C.LEATH_D)
    cv.rect(3, 4, 12, 13, C.LEATH)
    cv.line(3, 4, 12, 13, C.LEATH_D)
    cv.line(12, 4, 3, 13, C.LEATH_D)
    cv.hline(3, 12, 4, (188, 132, 88))
    cv.outline()
    return cv


def rug():
    cv = Canvas(TILE, TILE)
    cv.rect(0, 0, 15, 15, C.RED_D)
    cv.rect(2, 2, 13, 13, C.RED)
    cv.rect(5, 5, 10, 10, C.GOLD_D)
    cv.rect(6, 6, 9, 9, C.RED)
    return cv


def door(open_):
    cv = Canvas(TILE, TILE)
    if open_:
        cv.rect(0, 0, 15, 15, (30, 24, 34))
        cv.rect(1, 0, 14, 3, C.WALL_D)
        cv.rect(2, 0, 13, 1, C.WALL)
        for x in range(2, 14, 3):
            cv.vline(x, 4, 6, (44, 36, 48))
    else:
        cv.rect(0, 0, 15, 15, C.LEATH_D)
        for x in range(1, 15, 4):
            cv.vline(x, 1, 14, C.LEATH)
        cv.hline(0, 15, 3, C.STEEL_K)
        cv.hline(0, 15, 11, C.STEEL_K)
        cv.rect(7, 7, 9, 9, C.GOLD_D)
    return cv


def torch(frame):
    cv = Canvas(TILE, TILE)
    cv.rect(6, 7, 9, 15, C.LEATH_D)
    cv.vline(7, 7, 15, C.LEATH)
    cv.rect(5, 6, 10, 7, C.STEEL_K)
    f = frame % 2
    cv.blob(7.5, 4 - f, 3, 3.5 - f * 0.5, C.RUST)
    cv.blob(7.5, 4 - f, 2, 2.5 - f * 0.5, C.EMBER)
    cv.blob(7.5, 4.5 - f, 1, 1.5, C.CREAM_L)
    return cv


def bones():
    cv = Canvas(TILE, TILE)
    cv.ellipse(6, 10, 2.5, 2, C.BONE)
    cv.set(5, 10, C.OUT)
    cv.set(7, 10, C.OUT)
    cv.line(9, 12, 13, 9, C.BONE)
    cv.set(9, 12, C.BONE_D)
    cv.line(10, 13, 13, 11, C.BONE_D)
    cv.outline()
    return cv


def grass():
    cv = Canvas(TILE, TILE)
    for x, h, c in ((4, 4, C.SLIME_D), (6, 6, C.SLIME), (8, 5, C.SLIME_D), (10, 3, C.SLIME)):
        cv.vline(x, 15 - h, 15, c)
        cv.set(x + 1, 15 - h, c)
    return cv


# ---------------------------------------------------------------- effects
def slash(frame):
    """A filled crescent that widens and thins as the swing follows through."""
    cv = Canvas(40, 40)
    cx, cy = 6, 20
    spread = (1.0, 1.5, 1.9)[frame]
    start = (-0.78, -0.72, -0.62)[frame]
    r_out = (22, 25, 27)[frame]
    width = (7, 5, 2)[frame]
    for y in range(40):
        for x in range(40):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if not (r_out - width <= d <= r_out):
                continue
            a = math.atan2(dy, dx)
            if not (start <= a <= start + spread):
                continue
            edge = d > r_out - 2 or a < start + 0.12 or a > start + spread - 0.12
            cv.set(x, y, C.CREAM_L if edge else C.CREAM)
    for y in range(40):
        for x in range(40):
            if cv.get(x, y) == C.CREAM and cv.get(x, y + 1) is T:
                cv.set(x, y, C.CREAM_D)
    return cv


def thrust(frame):
    cv = Canvas(40, 20)
    length = (12, 26, 20)[frame]
    for x in range(4, 4 + length):
        cv.set(x, 10, C.CREAM_L)
        if x < 4 + length - 4:
            cv.set(x, 9, C.CREAM_D)
            cv.set(x, 11, C.CREAM_D)
    cv.set(4 + length, 10, C.CREAM_L)
    cv.set(4 + length - 1, 9, C.CREAM_L)
    cv.set(4 + length - 1, 11, C.CREAM_L)
    return cv


def slam(frame):
    cv = Canvas(40, 40)
    r = (6, 13, 18)[frame]
    for i in range(72):
        a = i / 72.0 * math.tau
        cv.set(20 + math.cos(a) * r, 20 + math.sin(a) * r * 0.62, C.CREAM_L)
        if frame:
            cv.set(20 + math.cos(a) * (r - 2), 20 + math.sin(a) * (r - 2) * 0.62, C.GOLD)
    return cv


def spark():
    cv = Canvas(4, 4)
    cv.rect(1, 0, 2, 3, C.CREAM_L)
    cv.rect(0, 1, 3, 2, C.CREAM_L)
    cv.rect(1, 1, 2, 2, (255, 255, 255))
    return cv


def shard():
    cv = Canvas(6, 6)
    cv.rect(1, 1, 4, 4, C.CREAM)
    cv.rect(1, 1, 2, 2, C.CREAM_L)
    cv.set(4, 4, C.CREAM_D)
    cv.outline()
    return cv


def arrow():
    cv = Canvas(14, 6)
    cv.hline(2, 10, 3, C.LEATH_D)
    cv.hline(3, 10, 2, C.LEATH)
    cv.rect(10, 1, 12, 4, C.STEEL)
    cv.set(13, 2, C.STEEL)
    cv.set(13, 3, C.STEEL)
    cv.rect(0, 1, 2, 1, C.CREAM)
    cv.rect(0, 4, 2, 4, C.CREAM)
    cv.outline()
    return cv


def orb(frame):
    cv = Canvas(14, 14)
    r = 4 + frame % 2
    cv.blob(7, 7, r, r, C.PURP_D)
    cv.blob(7, 7, r - 1.5, r - 1.5, C.PURP)
    cv.set(5, 5, C.CREAM_L)
    cv.set(6, 5, C.CREAM_L)
    cv.outline()
    return cv


def shadow():
    cv = Canvas(20, 8)
    cv.ellipse(10, 4, 9, 3.4, (24, 18, 30))
    return cv


def cursor():
    cv = Canvas(12, 12)
    for i in (0, 1, 2):
        cv.set(6, i, C.CREAM_L); cv.set(6, 11 - i, C.CREAM_L)
        cv.set(i, 6, C.CREAM_L); cv.set(11 - i, 6, C.CREAM_L)
    cv.set(6, 6, C.RED)
    return cv


# ---------------------------------------------------------------- weapon icons
def icon_sword():
    cv = Canvas(16, 16)
    cv.line(4, 12, 12, 3, C.STEEL)
    cv.line(5, 12, 13, 3, C.STEEL_D)
    cv.set(13, 2, C.STEEL)
    cv.line(2, 11, 6, 15, C.GOLD_D)
    cv.rect(2, 12, 4, 14, C.LEATH)
    cv.set(3, 13, C.GOLD)
    cv.outline()
    return cv


def icon_spear():
    cv = Canvas(16, 16)
    cv.line(2, 14, 11, 5, C.LEATH)
    cv.line(3, 14, 12, 5, C.LEATH_D)
    cv.line(11, 6, 13, 2, C.STEEL)
    cv.line(12, 6, 13, 3, C.STEEL_D)
    cv.set(13, 1, C.STEEL)
    cv.set(10, 6, C.STEEL_D)
    cv.rect(9, 6, 11, 7, C.GOLD_D)
    cv.outline()
    return cv


def icon_hammer():
    cv = Canvas(16, 16)
    cv.line(3, 14, 9, 7, C.LEATH)
    cv.line(4, 14, 10, 7, C.LEATH_D)
    cv.rect(8, 2, 14, 7, C.STEEL_D)
    cv.rect(9, 3, 13, 6, C.STEEL)
    cv.rect(9, 3, 10, 4, C.STEEL)
    cv.hline(8, 14, 7, C.STEEL_K)
    cv.outline()
    return cv


# ---------------------------------------------------------------- boss
BW = 48


def boss_frame(bob=0, arms=0, broken=False, crack=0):
    """The Hollow Sovereign - tall, angular, armour over a hollow core."""
    cv = Canvas(BW, BW)
    cx = 24
    # tattered cape behind everything
    for y in range(18 + bob, 46):
        t = (y - 18 - bob) / 28.0
        half = int(7 + t * 11)
        if y > 38 and (y + bob) % 3 == 0:
            half -= 2
        cv.hline(cx - half, cx + half, y, C.PURP_D)
    for y in range(40, 46):
        for x in range(cx - 18, cx + 19):
            if (x * 3 + y * 5) % 7 < 2:
                cv.set(x, y, T)
    for x in range(cx - 14, cx + 15, 5):
        cv.vline(x, 26 + bob, 42, (86, 60, 118))
    # plate skirt
    for y in range(34 + bob, 44 + bob):
        half = int(6 + (y - 34 - bob) * 0.7)
        cv.hline(cx - half, cx + half, y, C.STEEL_K)
        if (y - bob) % 3 == 0:
            cv.hline(cx - half, cx + half, y, C.STEEL_D)
    # breastplate, narrow waist to wide chest
    for y in range(20 + bob, 35 + bob):
        t = (y - 20 - bob) / 15.0
        half = int(9 - t * 4)
        cv.hline(cx - half, cx + half, y, C.STEEL_D)
        cv.set(cx - half, y, C.STEEL)
        cv.set(cx + half, y, C.STEEL_K)
    cv.vline(cx - 6, 21 + bob, 30 + bob, C.STEEL)
    # hollow core
    cv.blob(cx, 26 + bob, 3.4, 3.4, (36, 28, 44))
    cv.blob(cx, 26 + bob, 2.2, 2.2, C.PURP)
    cv.blob(cx, 26 + bob, 1, 1, C.CREAM_L)
    # angular pauldrons
    for side in (-1, 1):
        if broken and side > 0:
            for i in range(4):
                cv.hline(cx + 10 + i, cx + 13, 21 + bob + i, C.STEEL_K)
            cv.set(cx + 12, 20 + bob, C.OUT)
        else:
            for i in range(7):
                w = 8 - i
                x0 = cx + side * 8
                cv.hline(min(x0, x0 + side * w), max(x0, x0 + side * w), 18 + bob + i, C.STEEL_D)
            for i in range(3):
                x0 = cx + side * 9
                cv.hline(min(x0, x0 + side * (6 - i)), max(x0, x0 + side * (6 - i)), 18 + bob + i, C.STEEL)
            cv.hline(cx + side * 8, cx + side * 14, 25 + bob, C.STEEL_K)
    # arms
    for side in (-1, 1):
        ax = cx + side * 15
        cv.rect(min(ax, ax + side * 2), 25 + bob + arms, max(ax, ax + side * 2), 33 + bob + arms, C.STEEL_K)
        cv.rect(min(ax, ax + side * 3), 33 + bob + arms, max(ax, ax + side * 3), 36 + bob + arms, C.STEEL_D)
        cv.set(ax + side, 34 + bob + arms, C.STEEL)
    # gorget and helm
    cv.hline(cx - 5, cx + 5, 19 + bob, C.STEEL_K)
    for y in range(9 + bob, 20 + bob):
        t = abs(y - (14 + bob)) / 6.0
        half = int(5 - t * 2)
        cv.hline(cx - half, cx + half, y, C.STEEL_D)
    cv.vline(cx - 3, 11 + bob, 17 + bob, C.STEEL)
    cv.rect(cx - 4, 13 + bob, cx + 4, 15 + bob, (34, 26, 42))
    cv.rect(cx - 4, 13 + bob, cx - 2, 14 + bob, C.EMBER)
    cv.rect(cx + 2, 13 + bob, cx + 4, 14 + bob, C.EMBER)
    for x in range(cx - 3, cx + 4, 2):
        cv.vline(x, 16 + bob, 18 + bob, C.STEEL_K)
    # crown
    cv.hline(cx - 6, cx + 6, 8 + bob, C.GOLD_D)
    cv.hline(cx - 6, cx + 6, 7 + bob, C.GOLD)
    for i, x in enumerate(range(cx - 6, cx + 7, 3)):
        h = 5 if i % 2 == 0 else 3
        cv.vline(x, 7 + bob - h, 7 + bob, C.GOLD)
        cv.set(x, 7 + bob - h, C.CREAM_L)
        cv.set(x, 6 + bob - h + 1, C.GOLD_D) if h > 3 else None
    if crack:
        cv.line(cx + 3, 21 + bob, cx, 29 + bob, C.OUT)
        cv.line(cx, 29 + bob, cx + 4, 34 + bob, C.OUT)
        if crack > 1:
            cv.line(cx - 7, 23 + bob, cx - 3, 33 + bob, C.OUT)
            cv.line(cx - 4, 12 + bob, cx - 2, 18 + bob, C.OUT)
    cv.outline()
    return cv


def boss_set():
    idle = [boss_frame(0), boss_frame(-1), boss_frame(0), boss_frame(1)]
    attack = [boss_frame(-1, arms=-3), boss_frame(1, arms=3), boss_frame(0, arms=1)]
    hurt = [boss_frame(1, arms=1, crack=1)]
    broken = [boss_frame(0, broken=True, crack=1), boss_frame(-1, broken=True, crack=1),
              boss_frame(0, broken=True, crack=2), boss_frame(1, broken=True, crack=2)]
    death = []
    src = boss_frame(1, crack=2, broken=True)
    for i in range(6):
        f = Canvas(BW, BW)
        for y in range(BW):
            for x in range(BW):
                c = src.get(x, y)
                if c is T or (x * 5 + y * 3 + i * 7) % max(2, 7 - i) == 0:
                    continue
                f.set(x, min(BW - 1, y + i // 2), c)
        death.append(f)
    return dict(idle=idle, run=idle, attack=attack, hurt=hurt, death=death, broken=broken)


# ------------------------------------------------- small (in-world) HP cells
SMALL = 6


def _small_base(face, light, dark):
    cv = Canvas(SMALL, SMALL)
    cv.rect(0, 0, 5, 5, C.OUT)
    cv.rect(1, 1, 4, 4, face)
    cv.rect(1, 1, 3, 1, light)
    cv.set(1, 2, light)
    cv.rect(2, 4, 4, 4, dark)
    cv.set(4, 3, dark)
    return cv


def small_normal():
    return _small_base(C.CREAM, C.CREAM_L, C.CREAM_D)


def small_cracked():
    cv = small_normal()
    cv.set(2, 2, C.CREAM_D)
    cv.set(3, 3, C.OUT_S)
    return cv


def small_armor():
    cv = _small_base(C.STEEL_D, C.STEEL, C.STEEL_K)
    cv.set(2, 2, C.STEEL)
    cv.set(3, 2, C.STEEL_K)
    return cv


def small_armor_cracked():
    cv = small_armor()
    cv.set(3, 1, C.OUT_S)
    cv.set(2, 3, C.OUT_S)
    return cv


def small_empty():
    cv = Canvas(SMALL, SMALL)
    cv.rect(0, 0, 5, 5, C.OUT)
    cv.rect(1, 1, 4, 4, (46, 36, 54))
    cv.rect(1, 1, 3, 1, (34, 27, 42))
    return cv


def small_poison(frame):
    cv = Canvas(SMALL, SMALL)
    cv.rect(1, 1, 4, 4, C.VENOM_D)
    cv.set(1 + frame % 2, 1, C.VENOM)
    cv.set(3, 2 + frame % 2, C.VENOM)
    cv.set(2, 3, C.SLIME_L)
    return cv


def small_marker():
    cv = Canvas(SMALL, SMALL)
    for i in (0, 2, 4, 5):
        cv.set(i, 0, C.CREAM_L)
        cv.set(i, 5, C.CREAM_L)
        cv.set(0, i, C.CREAM_L)
        cv.set(5, i, C.CREAM_L)
    return cv


def icon_axe():
    cv = Canvas(16, 16)
    cv.line(3, 14, 11, 4, C.LEATH)
    cv.line(4, 14, 12, 4, C.LEATH_D)
    for i in range(7):
        cv.hline(8 - i // 3, 13 - i, 3 + i, C.STEEL_D)
    cv.line(9, 3, 13, 8, C.STEEL)
    cv.line(8, 4, 12, 9, C.STEEL)
    cv.outline()
    return cv


def icon_dagger():
    cv = Canvas(16, 16)
    cv.line(6, 11, 12, 4, C.STEEL)
    cv.line(7, 11, 12, 5, C.STEEL_D)
    cv.set(13, 3, C.STEEL)
    cv.line(4, 11, 8, 15, C.GOLD_D)
    cv.rect(4, 12, 5, 14, C.LEATH)
    cv.outline()
    return cv


def icon_bow():
    cv = Canvas(16, 16)
    for y in range(2, 14):
        t = (y - 8) / 6.0
        cv.set(10 - int(3 * (1 - t * t)), y, C.LEATH)
        cv.set(11 - int(3 * (1 - t * t)), y, C.LEATH_D)
    cv.line(10, 2, 10, 13, C.CREAM_D)
    cv.line(3, 8, 10, 8, C.STEEL)
    cv.set(2, 8, C.STEEL)
    cv.outline()
    return cv


def shrine(frame):
    cv = Canvas(TILE * 2, TILE * 2)
    cv.rect(8, 20, 23, 30, C.WALL)
    cv.rect(9, 21, 22, 29, C.WALL_L)
    cv.hline(8, 23, 30, C.WALL_D)
    cv.rect(11, 10, 20, 21, C.STEEL_K)
    cv.rect(12, 11, 19, 20, C.STEEL_D)
    f = frame % 2
    cv.blob(15.5, 15 - f, 4, 4.5, C.CREAM)
    cv.blob(15.5, 15 - f, 2.5, 3, C.CREAM_L)
    cv.set(14, 13 - f, (255, 255, 255))
    cv.outline()
    return cv


def pedestal():
    cv = Canvas(TILE, TILE)
    cv.rect(3, 6, 12, 14, C.WALL)
    cv.rect(4, 7, 11, 13, C.WALL_L)
    cv.rect(2, 4, 13, 6, C.WALL_L)
    cv.hline(2, 13, 4, C.WALLTOP)
    cv.hline(3, 12, 14, C.WALL_D)
    cv.outline()
    return cv


def app_icon():
    cv = Canvas(64, 64)
    cv.rect(0, 0, 63, 63, (40, 32, 48))
    for gy in range(3):
        for gx in range(3):
            t = cell_normal() if (gx + gy) % 3 else cell_armor()
            if gx == 2 and gy == 0:
                t = cell_empty()
            for y in range(12):
                for x in range(12):
                    c = t.get(x, y)
                    if c is None:
                        continue
                    for sy in range(2):
                        for sx in range(2):
                            cv.set(10 + gx * 16 + x * 2 + sx, 10 + gy * 16 + y * 2 + sy, c)
    return cv
