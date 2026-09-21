"""Renders every sprite in the game into ../assets."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel import strip, sheet, Canvas, C
import chars, world

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
os.makedirs(OUT, exist_ok=True)


def p(name):
    return os.path.join(OUT, name)


def write_char(name, s):
    for anim, frames in s.items():
        strip(frames, p("%s_%s.png" % (name, anim)))


write_char("player", chars.anim_set(chars.PLAYER))
write_char("goblin", chars.anim_set(chars.GOBLIN))
write_char("archer", chars.anim_set(chars.ARCHER))
write_char("knight", chars.anim_set(chars.KNIGHT))
write_char("slime", chars.slime_set())
write_char("boss", world.boss_set())

# HP cells - 12px for menus, 6px in the world
strip([world.cell_normal()], p("cell_normal.png"))
strip([world.cell_cracked()], p("cell_cracked.png"))
strip([world.cell_armor()], p("cell_armor.png"))
strip([world.cell_armor_cracked()], p("cell_armor_cracked.png"))
strip([world.cell_empty()], p("cell_empty.png"))
strip([world.cell_poison(0), world.cell_poison(1), world.cell_poison(2)], p("cell_poison.png"))
strip([world.cell_marker()], p("cell_marker.png"))

strip([world.small_normal()], p("scell_normal.png"))
strip([world.small_cracked()], p("scell_cracked.png"))
strip([world.small_armor()], p("scell_armor.png"))
strip([world.small_armor_cracked()], p("scell_armor_cracked.png"))
strip([world.small_empty()], p("scell_empty.png"))
strip([world.small_poison(0), world.small_poison(1)], p("scell_poison.png"))
strip([world.small_marker()], p("scell_marker.png"))

# room tiles, one 8-wide atlas
TILES = [world.floor_tile(0), world.floor_tile(1), world.floor_tile(2), world.floor_tile(3),
         world.wall_face(), world.wall_cap(), world.wall_top(), world.pillar(),
         world.crate(), world.rug(), world.door(False), world.door(True),
         world.torch(0), world.torch(1), world.bones(), world.grass()]
sheet(TILES, 8, p("tiles.png"))

# effects and props
strip([world.slash(0), world.slash(1), world.slash(2)], p("fx_slash.png"))
strip([world.thrust(0), world.thrust(1), world.thrust(2)], p("fx_thrust.png"))
strip([world.slam(0), world.slam(1), world.slam(2)], p("fx_slam.png"))
strip([world.spark()], p("spark.png"))
strip([world.shard()], p("shard.png"))
strip([world.arrow()], p("arrow.png"))
strip([world.orb(0), world.orb(1)], p("orb.png"))
strip([world.shadow()], p("shadow.png"))
strip([world.cursor()], p("cursor.png"))
strip([world.icon_sword()], p("icon_sword.png"))
strip([world.icon_spear()], p("icon_spear.png"))
strip([world.icon_hammer()], p("icon_hammer.png"))
strip([world.icon_axe()], p("icon_axe.png"))
strip([world.icon_dagger()], p("icon_dagger.png"))
strip([world.icon_bow()], p("icon_bow.png"))
strip([world.shrine(0), world.shrine(1)], p("shrine.png"))
strip([world.pedestal()], p("pedestal.png"))
strip([world.app_icon()], p("icon.png"))

print("wrote", len(os.listdir(OUT)), "assets")
