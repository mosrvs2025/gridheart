"""Small chiptune-ish SFX, synthesised so the prototype ships with no samples."""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
os.makedirs(OUT, exist_ok=True)


def env(i, n, a=0.01, d=0.5, s=0.4, r=0.4):
    t = i / float(n)
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s) * (t - a) / d
    if t > 1.0 - r:
        return s * max(0.0, (1.0 - t) / r)
    return s


def square(ph):
    return 1.0 if (ph % 1.0) < 0.5 else -1.0


def saw(ph):
    return (ph % 1.0) * 2.0 - 1.0


def render(dur, fn, vol=0.5):
    n = int(SR * dur)
    buf = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        v, ph, lp = fn(i, n, ph, lp)
        buf.append(max(-1.0, min(1.0, v * vol)))
    return buf


def save(name, buf):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in buf))


def noise_hit(dur, f0, f1, cut=0.35, vol=0.6, tone=0.0):
    def fn(i, n, ph, lp):
        t = i / float(n)
        f = f0 + (f1 - f0) * t
        ph += f / SR
        nz = random.uniform(-1, 1)
        lp += (nz - lp) * cut
        v = lp * (1.0 - tone) + square(ph) * tone
        return v * env(i, n, 0.005, 0.25, 0.25, 0.7), ph, lp
    return render(dur, fn, vol)


def blip(dur, f0, f1, wave_fn=square, vol=0.4, a=0.01, r=0.5):
    def fn(i, n, ph, lp):
        t = i / float(n)
        f = f0 * pow(f1 / f0, t)
        ph += f / SR
        return wave_fn(ph) * env(i, n, a, 0.3, 0.55, r), ph, lp
    return render(dur, fn, vol)


def mix(*bufs):
    n = max(len(b) for b in bufs)
    out = [0.0] * n
    for b in bufs:
        for i, s in enumerate(b):
            out[i] += s
    return [max(-1.0, min(1.0, s)) for s in out]


random.seed(7)
save("swing_light", noise_hit(0.16, 900, 2600, 0.5, 0.35))
save("swing_heavy", noise_hit(0.26, 300, 900, 0.28, 0.5))
save("thrust", noise_hit(0.14, 1800, 600, 0.6, 0.35))
save("hit_cell", mix(blip(0.07, 900, 1500, square, 0.3), noise_hit(0.06, 2000, 900, 0.7, 0.25)))
save("cell_break", mix(noise_hit(0.22, 1400, 200, 0.45, 0.5), blip(0.16, 500, 120, saw, 0.25)))
save("armor_clang", mix(blip(0.3, 1700, 1500, square, 0.22, 0.002, 0.8),
                        blip(0.3, 2600, 2300, square, 0.14, 0.002, 0.8),
                        noise_hit(0.12, 3000, 1200, 0.8, 0.3)))
save("pierce", blip(0.18, 2400, 700, saw, 0.3))
save("dash", noise_hit(0.2, 400, 1800, 0.35, 0.3))
save("hurt", mix(blip(0.26, 420, 120, saw, 0.4), noise_hit(0.16, 700, 200, 0.4, 0.3)))
save("enemy_die", mix(blip(0.34, 700, 90, saw, 0.35), noise_hit(0.3, 1200, 150, 0.3, 0.4)))
save("boss_hurt", mix(blip(0.4, 260, 90, saw, 0.45), noise_hit(0.35, 600, 120, 0.2, 0.4)))
save("boss_die", mix(blip(0.9, 300, 50, saw, 0.5), noise_hit(0.9, 900, 80, 0.12, 0.5)))
save("shoot", blip(0.12, 1600, 500, square, 0.25))
save("arrow_hit", noise_hit(0.1, 1600, 600, 0.6, 0.3))
save("poison_tick", mix(blip(0.18, 300, 520, square, 0.18), noise_hit(0.14, 500, 200, 0.5, 0.15)))
save("pickup", mix(blip(0.1, 880, 880, square, 0.28), blip(0.22, 1320, 1320, square, 0.24)))
save("ui_move", blip(0.05, 700, 900, square, 0.18))
save("ui_confirm", mix(blip(0.09, 660, 660, square, 0.24), blip(0.2, 990, 990, square, 0.2)))
save("ui_back", blip(0.1, 520, 330, square, 0.22))
save("door", mix(noise_hit(0.5, 200, 90, 0.12, 0.4), blip(0.4, 160, 110, saw, 0.2)))
save("place", mix(blip(0.08, 520, 780, square, 0.26), blip(0.16, 1040, 1040, square, 0.2)))
save("heal", mix(blip(0.14, 660, 990, square, 0.24), blip(0.3, 1320, 1580, square, 0.22)))
save("room_clear", mix(blip(0.12, 523, 523, square, 0.22), blip(0.26, 659, 659, square, 0.2),
                       blip(0.44, 784, 784, square, 0.2), blip(0.7, 1046, 1046, square, 0.18)))
save("victory", mix(blip(0.2, 523, 523, square, 0.2), blip(0.4, 784, 784, square, 0.2),
                    blip(0.7, 1046, 1046, square, 0.2), blip(1.1, 1318, 1318, square, 0.18)))
save("step", noise_hit(0.05, 500, 300, 0.5, 0.12))
print("sfx:", len(os.listdir(OUT)))
