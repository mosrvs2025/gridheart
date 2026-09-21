import sys
from PIL import Image
from pixel import Canvas, C
import chars

sets = [("player", chars.anim_set(chars.PLAYER)), ("goblin", chars.anim_set(chars.GOBLIN)),
        ("archer", chars.anim_set(chars.ARCHER)), ("knight", chars.anim_set(chars.KNIGHT)),
        ("slime", chars.slime_set())]
rows = []
maxw = 0
for name, s in sets:
    fr = s["idle"] + s["run"] + s["attack"] + s["hurt"] + s["death"]
    rows.append(fr); maxw = max(maxw, len(fr))
img = Image.new("RGBA", (maxw * 24, len(rows) * 24), (40, 32, 48, 255))
for r, fr in enumerate(rows):
    for i, f in enumerate(fr):
        img.paste(f.to_image(), (i * 24, r * 24), f.to_image())
img = img.resize((img.width * 5, img.height * 5), Image.NEAREST)
img.save("/tmp/preview.png")
print(img.size)
