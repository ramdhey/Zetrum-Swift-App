#!/usr/bin/env python3
"""Ambil foto kendaraan berlisensi bebas dari Wikimedia Commons.

Dijalankan sekali saat menyiapkan aset: python3 Tools/fetchphotos.py
Hasilnya masuk ke Zetrum/Assets.xcassets/Vehicles/veh-<id>.imageset/ dan
daftar lisensinya ditulis ke CREDITS-PHOTOS.md.

Model yang tidak ketemu fotonya dibiarkan kosong — aplikasi otomatis
menggambar siluet kendaraannya sebagai gantinya.
"""
import json, os, re, sys, time, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Zetrum/Assets.xcassets/Vehicles")
UA = "ZetrumDemo/1.0 (aplikasi contoh pengisian EV; pengambilan aset sekali jalan)"
API = "https://commons.wikimedia.org/w/api.php"

# id -> kata kunci pencarian di Commons. Dipisah dari katalog Swift supaya
# nama model bisa dicocokkan dengan nama yang dipakai Commons.
QUERIES = {
  "wuling-air-lite": "Wuling Air ev front view", "wuling-air-lr": "Wuling Air ev rear",
  "wuling-binguo-lr": "Wuling Bingo", "wuling-binguo-pr": "Wuling Bingo",
  "wuling-cloud": "Wuling Cloud EV",
  "hyundai-ioniq5-sr": "Hyundai Ioniq 5", "hyundai-ioniq5-lr": "Hyundai Ioniq 5",
  "hyundai-ioniq6": "Hyundai Ioniq 6",
  "hyundai-kona-sr": "Hyundai Kona Electric SX2", "hyundai-kona-lr": "Hyundai Kona Electric SX2",
  "kia-ev6": "Kia EV6", "kia-ev9": "Kia EV9",
  "byd-atto1": "BYD Seagull", "byd-dolphin-dyn": "BYD Dolphin", "byd-dolphin-prem": "BYD Dolphin",
  "byd-atto3-adv": "BYD Atto 3", "byd-atto3-sup": "BYD Atto 3",
  "byd-seal-prem": "BYD Seal", "byd-seal-perf": "BYD Seal",
  "byd-m6-std": "BYD Song Max EV", "byd-m6-sup": "BYD Song Max EV front",
  "byd-sealion7": "BYD Sealion 7", "denza-d9": "Denza D9",
  "chery-omoda-e5": "Chery Omoda E5", "chery-j6-rwd": "Chery iCar 03", "chery-j6-awd": "Chery iCar 03",
  "jaecoo-j5-ev": "Jaecoo J5",
  "neta-v2": "Neta V", "neta-x": "Neta X",
  "mg4-magnify": "MG MG4 hatchback", "mg4-max": "MG 4 EV", "mg-zs-ev": "MG ZS EV",
  "maxus-mifa9": "Maxus Mifa 9",
  "mini-cooper-se": "Mini Cooper SE J01", "toyota-bz4x": "Toyota bZ4X",
  "lexus-ux300e": "Lexus UX 300e", "nissan-leaf": "Nissan Leaf ZE1",
  "mitsubishi-l100ev": "Mitsubishi Minicab MiEV",
  "dfsk-gelora-e": "DFSK Gelora", "citroen-ec3": "Citroen e-C3",
  "vinfast-vf5": "VinFast VF 5", "vinfast-vf7-eco": "VinFast VF 7", "vinfast-vfe34": "VinFast VF e34",
  "aion-yplus-ex": "Aion Y Plus", "aion-yplus-prem": "Aion Y Plus", "aion-es": "GAC Aion ES sedan",
  "honda-en1": "Honda e:Ny1", "seres-e1": "Seres E1",
  "geely-ex5": "Geely EX5", "xpeng-g6": "Xpeng G6", "aletra-l8s": "Skywell Aletra",
  "bmw-ix1": "BMW iX1", "bmw-i5": "BMW i5", "bmw-i7": "BMW i7",
  "mercedes-eqa": "Mercedes-Benz EQA", "mercedes-eqe": "Mercedes-Benz EQE",
  "mercedes-eqs": "Mercedes-Benz EQS",
  # motor
  "gesits-g1": "Gesits motorcycle", "gesits-raya-g": "Gesits",
  "alva-one": "Alva One electric", "alva-cervo": "Alva Cervo",
  "polytron-fox500": "Polytron Fox electric", "polytron-foxr": "Polytron Fox-R",
  "polytron-foxs": "Polytron Fox-S",
  "volta-401": "Volta electric motorcycle Indonesia", "volta-mandala": "Volta Mandala",
  "united-tx3000": "United electric scooter Indonesia", "united-c2000": "United C2000",
  "smoot-tempur": "Smoot Tempur", "smoot-zuzu": "Smoot Zuzu",
  "selis-emax-li": "Selis E-Max", "selis-emax-lr": "Selis E-Max",
  "viar-q1": "Viar Q1", "davigo-dragon-sli": "Davigo",
  "rakata-s9": "Rakata electric", "exotic-sterrato": "Exotic Sterrato",
  "greentech-vp": "Greentech electric scooter",
  "honda-em1": "Honda EM1 e:", "honda-icon-e": "Honda ICON e:", "honda-cuv-e": "Honda CUV e:",
  "electrum-h3": "Electrum H3", "electrum-h5": "Electrum H5",
  "charged-anoa": "Super Soco", "charged-maleo": "Super Soco CUx",
  "charged-rimau": "Super Soco CPx", "charged-baycat": "Charged Baycat",
  "maka-cavalry": "Maka Cavalry",
}

BAD = ("interior", "interieur", "innenraum", "dashboard", "dash ", "cockpit", "cabin",
       "steering", "engine", "badge", "logo", "wheel", "charging port", "rear light",
       "taillight", "headlight", "seat", "boot", "trunk", "emblem", "cutaway",
       "chassis", "frame", "map", "diagram", "assembly", "instrument")

def api(params):
    """Commons membatasi laju permintaan; kena 429 artinya tunggu, bukan menyerah."""
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    delay = 2.0
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == 5:
                raise
            print("   . kena batas laju, tunggu %.0f detik" % delay)
            time.sleep(delay)
            delay *= 1.8
    raise RuntimeError("batas laju")

def best(term):
    try:
        d = api({"action": "query", "format": "json", "generator": "search",
                 "gsrsearch": 'filetype:bitmap %s' % term, "gsrlimit": 14,
                 "gsrnamespace": 6, "prop": "imageinfo",
                 "iiprop": "url|extmetadata|size", "iiurlwidth": 900})
    except Exception as e:
        print("   ! gagal cari:", e); return None
    pages = d.get("query", {}).get("pages", {})
    if not pages:
        return None
    rows = []
    tokens = [t.lower().strip(":") for t in re.split(r"[\s-]+", term)]
    tokens = [t for t in tokens if len(t) > 1]
    for p in pages.values():
        ii = (p.get("imageinfo") or [None])[0]
        if not ii: continue
        title = p["title"].lower().replace("file:", " ")
        if any(b in title for b in BAD): continue
        if ii.get("width", 0) < 900: continue
        score = sum(1 for t in tokens if t in title)
        if score < max(2, len(tokens) - 1): continue
        # foto lebar lebih cocok untuk kartu
        ratio = ii["width"] / max(1, ii["height"])
        if ratio < 1.15: continue
        rows.append((score + min(ratio, 2.0) / 4, p["title"], ii))
    if not rows:
        return None
    rows.sort(reverse=True, key=lambda r: r[0])
    return rows[0][1], rows[0][2]

def meta(ii, key):
    v = (ii.get("extmetadata") or {}).get(key, {}).get("value", "")
    return re.sub(r"<[^>]+>", "", v).strip()

def save(vid, title, ii):
    folder = os.path.join(OUT, "veh-%s.imageset" % vid)
    os.makedirs(folder, exist_ok=True)
    url = ii["thumburl"].split("?")[0]
    ext = ".png" if url.lower().endswith(".png") else ".jpg"
    name = "veh-%s%s" % (vid, ext)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
    open(os.path.join(folder, name), "wb").write(data)
    json.dump({"images": [{"filename": name, "idiom": "universal", "scale": "2x"}],
               "info": {"author": "zetrum", "version": 1}},
              open(os.path.join(folder, "Contents.json"), "w"), indent=2)
    return name, len(data)

CREDITS = os.path.join(ROOT, "Tools/photo-credits.json")

def load_credits():
    return json.load(open(CREDITS)) if os.path.exists(CREDITS) else {}

def write_credits(db):
    json.dump(db, open(CREDITS, "w"), indent=1, sort_keys=True, ensure_ascii=False)
    lines = ["# Kredit foto kendaraan", "",
             "Semua foto diambil dari Wikimedia Commons dan dipakai sesuai lisensinya",
             "masing-masing. Foto mewakili modelnya secara umum; varian, tahun dan",
             "pasarnya bisa berbeda dari spesifikasi yang ditampilkan aplikasi.",
             "", "Berkas ini dihasilkan oleh `Tools/fetchphotos.py` — jangan disunting tangan.",
             "", "| Model | Berkas Commons | Pemotret | Lisensi |", "| --- | --- | --- | --- |"]
    for vid in sorted(db):
        c = db[vid]
        lines.append("| `%s` | [%s](%s) | %s | %s |"
                     % (vid, c["title"].replace("File:", ""), c["url"], c["artist"], c["license"]))
    open(os.path.join(ROOT, "CREDITS-PHOTOS.md"), "w").write("\n".join(lines) + "\n")

def main():
    args = sys.argv[1:]
    credits_only = "--credits" in args
    only = [a for a in args if not a.startswith("--")]
    os.makedirs(OUT, exist_ok=True)
    json.dump({"info": {"author": "zetrum", "version": 1}},
              open(os.path.join(OUT, "Contents.json"), "w"), indent=2)
    db = load_credits()
    missing = []
    for vid, term in QUERIES.items():
        if only and vid not in only: continue
        folder = os.path.join(OUT, "veh-%s.imageset" % vid)
        have = os.path.isdir(folder) and len(os.listdir(folder)) > 1
        if credits_only and (not have or vid in db): continue
        if not credits_only and have:
            print("=", vid, "(sudah ada)"); continue
        time.sleep(1.2)
        hit = best(term)
        if not hit:
            print("-", vid, "tidak ketemu —", term); missing.append(vid); continue
        title, ii = hit
        if not credits_only:
            try:
                name, size = save(vid, title, ii)
            except Exception as e:
                print("   ! gagal unduh:", e); missing.append(vid); continue
            print("+", vid, "<-", title, "(%.0f KB)" % (size / 1024))
        else:
            print("c", vid, "<-", title)
        db[vid] = {"title": title,
                   "artist": meta(ii, "Artist") or "tidak disebutkan",
                   "license": meta(ii, "LicenseShortName") or "lihat halaman berkas",
                   "url": ii.get("descriptionurl", "")}
        write_credits(db)
        time.sleep(1.2)

    write_credits(db)
    print("\nselesai. tanpa foto:", len(missing))
    if missing: print(" ", ", ".join(missing))

main()
