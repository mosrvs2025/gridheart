"""Character sprites: one small humanoid rig, posed per animation frame."""
from pixel import Canvas, C, T

W = H = 24
BASE = 21          # feet baseline
CX = 12


def _legs(cv, cfg, phase, bob):
    """phase: 0 idle, 1 left fwd, 2 pass, 3 right fwd."""
    lo, ro = 0, 0
    if phase == 1:
        lo, ro = -1, 1
    elif phase == 3:
        lo, ro = 1, -1
    for x0, off in ((9, lo), (13, ro)):
        top = BASE - 3 + bob
        cv.rect(x0, top, x0 + 2, BASE - 1 + min(0, off), cfg["pants"])
        cv.rect(x0, BASE - 1 + min(0, off), x0 + 2, BASE + min(0, off), cfg["boot"])
        cv.set(x0, BASE + min(0, off), cfg["boot_d"])


def _torso(cv, cfg, bob):
    cy = 15 + bob
    cv.blob(CX, cy, 3.6, 3, cfg["cloth"])
    cv.hline(9, 15, cy + 3, cfg["cloth_d"])        # hem shadow
    cv.hline(9, 15, cy + 2, cfg["belt"])           # belt
    cv.set(CX, cy + 2, cfg["belt_l"])
    cv.rect(9, cy - 3, 10, cy, cfg["cloth_l"])     # lit side
    cv.set(9, cy - 3, cfg["cloth"])


def _arm(cv, cfg, x, ytop, length, raised=False):
    if raised:
        cv.rect(x, ytop - 2, x + 1, ytop + length - 4, cfg["cloth"])
        cv.rect(x, ytop + length - 3, x + 1, ytop + length - 2, cfg["skin"])
    else:
        cv.rect(x, ytop, x + 1, ytop + length - 2, cfg["cloth"])
        cv.rect(x, ytop + length - 1, x + 1, ytop + length - 1, cfg["skin"])


def _head(cv, cfg, bob, blink=False):
    cy = 8 + bob
    cv.blob(CX, cy, 4, 4, cfg["skin"])
    cv.rect(8, cy - 1, 9, cy + 2, cfg["skin_d"])       # shaded cheek
    cv.hline(9, 15, cy + 4, cfg["skin_d"])
    if cfg.get("ears"):                                # goblin-style points
        cv.rect(6, cy, 7, cy + 1, cfg["skin"])
        cv.rect(17, cy, 18, cy + 1, cfg["skin"])
        cv.set(6, cy + 1, cfg["skin_d"])
        cv.set(18, cy + 1, cfg["skin_d"])
    style = cfg.get("hair_style", "mop")
    if style == "mop":
        cv.blob(CX, cy - 2, 4, 3, cfg["hair"])
        cv.hline(8, 16, cy - 5, cfg["hair"])
        cv.rect(8, cy - 1, 8, cy + 1, cfg["hair"])     # sideburn
        cv.rect(16, cy - 1, 16, cy + 1, cfg["hair"])
        cv.hline(9, 14, cy - 1, cfg["hair_d"])         # fringe shadow
        cv.rect(11, cy - 5, 12, cy - 5, cfg["hair"])
    elif style == "hood":
        cv.blob(CX, cy - 1, 5, 4, cfg["hair"])
        cv.blob(CX, cy + 1, 3, 2, T)
        cv.blob(CX, cy + 1, 3, 2, cfg["skin"])
        cv.hline(8, 16, cy - 4, cfg["hair_d"])
        cv.rect(7, cy, 7, cy + 3, cfg["hair"])
        cv.rect(17, cy, 17, cy + 3, cfg["hair"])
    elif style == "helm":
        cv.blob(CX, cy - 1, 5, 4, cfg["hair"])
        cv.hline(8, 16, cy + 1, cfg["hair_d"])
        cv.rect(8, cy + 2, 16, cy + 4, cfg["hair"])
        cv.rect(9, cy + 1, 15, cy + 2, C.OUT)          # visor slit
        cv.rect(11, cy - 7, 13, cy - 4, cfg["plume"])  # crest
        cv.vline(CX + 1, cy - 7, cy - 4, cfg["plume_d"])
        cv.hline(8, 16, cy - 2, cfg["hair_l"])
        return
    if not blink:
        cv.rect(10, cy + 1, 10, cy + 2, C.OUT)
        cv.rect(14, cy + 1, 14, cy + 2, C.OUT)
        cv.set(10, cy + 1, cfg.get("eye", C.OUT))
        cv.set(14, cy + 1, cfg.get("eye", C.OUT))
    else:
        cv.set(10, cy + 2, C.OUT)
        cv.set(14, cy + 2, C.OUT)
    if cfg.get("fangs"):
        cv.set(11, cy + 4, C.CREAM)
        cv.set(13, cy + 4, C.CREAM)


def humanoid(cfg, pose):
    cv = Canvas(W, H)
    bob = pose.get("bob", 0)
    _legs(cv, cfg, pose.get("phase", 0), pose.get("leg_bob", 0))
    _torso(cv, cfg, bob)
    back = pose.get("arm_back", 0)
    _arm(cv, cfg, 7, 13 + bob + back, 4)
    _head(cv, cfg, bob, pose.get("blink", False))
    front = pose.get("arm_front", 0)
    _arm(cv, cfg, 16, 13 + bob + front, 4, pose.get("raised", False))
    if cfg.get("prop"):
        cfg["prop"](cv, cfg, pose, bob)
    cv.outline()
    return cv


PLAYER = dict(
    skin=C.SKIN, skin_d=C.SKIN_D, hair=C.HAIR, hair_d=C.HAIR_D,
    cloth=C.TUNIC, cloth_d=C.TUNIC_D, cloth_l=C.TUNIC_L,
    pants=C.PANTS, boot=C.LEATH, boot_d=C.LEATH_D,
    belt=C.LEATH_D, belt_l=C.GOLD, hair_style="mop",
)

GOBLIN = dict(
    skin=C.GOB, skin_d=C.GOB_D, hair=C.RED_D, hair_d=C.RED_D,
    cloth=C.RED, cloth_d=C.RED_D, cloth_l=(226, 128, 116),
    pants=C.LEATH_D, boot=C.LEATH_D, boot_d=C.OUT,
    belt=C.LEATH, belt_l=C.GOLD, hair_style="mop", ears=True, fangs=True,
    eye=(250, 226, 120),
)

ARCHER = dict(
    skin=C.SKIN, skin_d=C.SKIN_D, hair=C.DUSK, hair_d=C.DUSK_D,
    cloth=C.DUSK, cloth_d=C.DUSK_D, cloth_l=(156, 136, 196),
    pants=C.DUSK_D, boot=C.LEATH_D, boot_d=C.OUT,
    belt=C.LEATH, belt_l=C.GOLD, hair_style="hood", eye=(250, 226, 120),
)


def _shield(cv, cfg, pose, bob):
    y = 12 + bob + pose.get("arm_front", 0)
    cv.rect(15, y, 18, y + 6, C.STEEL_D)
    cv.rect(16, y + 1, 17, y + 5, C.STEEL)
    cv.rect(16, y + 2, 17, y + 3, C.GOLD)
    cv.hline(15, 18, y + 6, C.STEEL_K)


KNIGHT = dict(
    skin=C.STEEL, skin_d=C.STEEL_D, hair=C.STEEL_D, hair_d=C.STEEL_K,
    hair_l=C.STEEL, plume=C.RED, plume_d=C.RED_D,
    cloth=C.STEEL_D, cloth_d=C.STEEL_K, cloth_l=C.STEEL,
    pants=C.STEEL_K, boot=C.STEEL_K, boot_d=C.OUT,
    belt=C.GOLD_D, belt_l=C.GOLD, hair_style="helm", prop=_shield,
)


def anim_set(cfg):
    """Returns {name: [Canvas, ...]} for one humanoid."""
    idle = [humanoid(cfg, dict(bob=0)), humanoid(cfg, dict(bob=-1, blink=False)),
            humanoid(cfg, dict(bob=0)), humanoid(cfg, dict(bob=0, blink=True))]
    run = [humanoid(cfg, dict(bob=-1, phase=1, arm_front=1, arm_back=-1)),
           humanoid(cfg, dict(bob=0, phase=2)),
           humanoid(cfg, dict(bob=-1, phase=3, arm_front=-1, arm_back=1)),
           humanoid(cfg, dict(bob=0, phase=2))]
    attack = [humanoid(cfg, dict(bob=0, arm_front=-3, raised=True)),
              humanoid(cfg, dict(bob=-1, arm_front=2, phase=1)),
              humanoid(cfg, dict(bob=0, arm_front=1))]
    hurt = [humanoid(cfg, dict(bob=1, arm_front=-2, arm_back=-2, phase=2))]
    death = []
    base = humanoid(cfg, dict(bob=1, arm_front=-2, arm_back=-2))
    for i, (sq, fade) in enumerate(((0, 0), (1, 0), (3, 1), (5, 1))):
        f = Canvas(W, H)
        for y in range(H):
            for x in range(W):
                c = base.get(x, y)
                if c is T:
                    continue
                ny = BASE - int((BASE - y) * (1 - sq * 0.18))
                if fade and (x + ny + i) % (4 - fade) == 0:
                    continue
                f.set(x, ny, c)
        death.append(f)
    return dict(idle=idle, run=run, attack=attack, hurt=hurt, death=death)


def slime_set():
    def body(squash, wob):
        cv = Canvas(W, H)
        rx = 7 + squash
        ry = 6 - squash
        cy = BASE - ry + 1
        cv.blob(CX, cy, rx, ry, C.SLIME)
        cv.blob(CX - 2, cy - 1, rx - 3, ry - 2, C.SLIME_L)
        cv.hline(CX - rx + 1, CX + rx - 1, cy + ry - 1, C.SLIME_D)
        cv.rect(CX - 5, cy - 3 + wob, CX - 4, cy - 1 + wob, C.OUT)
        cv.rect(CX + 3, cy - 3 + wob, CX + 4, cy - 1 + wob, C.OUT)
        cv.set(CX - 5, cy - 3 + wob, C.CREAM)
        cv.set(CX + 3, cy - 3 + wob, C.CREAM)
        cv.rect(CX - 1, cy + 1 + wob, CX + 1, cy + 1 + wob, C.SLIME_D)
        cv.set(CX - 4, cy - 5, C.SLIME_L)          # sheen
        cv.set(CX - 3, cy - 5, C.SLIME_L)
        cv.outline()
        return cv

    idle = [body(0, 0), body(1, 0), body(0, 0), body(-1, 1)]
    hop = [body(2, 0), body(-2, 0).offset(0, -3), body(-1, 1).offset(0, -5), body(1, 0)]
    attack = [body(2, 1), body(-2, 1).offset(0, -2), body(3, 0)]
    hurt = [body(3, 1)]
    death = []
    for i in range(4):
        f = Canvas(W, H)
        b = body(2 + i, 0)
        for y in range(H):
            for x in range(W):
                c = b.get(x, y)
                if c is T or (x * 3 + y * 2 + i * 5) % (5 - i) == 0:
                    continue
                f.set(x, min(BASE, y + i), c)
        death.append(f)
    return dict(idle=idle, run=hop, attack=attack, hurt=hurt, death=death)
