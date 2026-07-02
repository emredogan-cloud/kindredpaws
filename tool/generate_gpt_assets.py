#!/usr/bin/env python3
"""KindredPaws asset generation — the previously key-blocked pipeline.

Reads OPENAI_API_KEY from the environment or the project `.env` (tolerant
parser: survives whitespace around `=`, quotes, and CRLF — the loading bug
this sprint diagnosed), then generates the ORIGINAL production assets from
the manifest below via the OpenAI Images API (gpt-image-1), following the
canonical prompt conventions of KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md:
every prompt carries the storybook style suffix; scenes are opaque
full-bleed with an empty pet spot; items/UI are transparent, centered,
child-safe. No prompt references any existing game, brand, or artist.

Usage:
  python3 tool/generate_gpt_assets.py            # generate everything missing
  python3 tool/generate_gpt_assets.py --only scenes|items
  python3 tool/generate_gpt_assets.py --force    # regenerate even if present

Never prints the key.
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

STYLE = (
    "cozy hand-painted children's storybook illustration, soft pastel palette "
    "(cream, peach, warm honey tones), gentle soft shadows, rounded soft "
    "shapes, warm and safe and emotionally tender mood, premium mobile game "
    "quality, NOT scary, NOT violent, child-safe, no text, no watermark"
)

SCENE_RULES = (
    "full-bleed opaque background artwork for a mobile game room, portrait "
    "orientation, an EMPTY open floor spot at the lower-center where a small "
    "pet character will stand (no animals or characters anywhere in the "
    "image), balanced negative space, "
)

ITEM_RULES = (
    "single centered object on a fully transparent background, soft pillowy "
    "sticker style with a subtle soft drop shadow, no scene, no characters, "
)

SCENES = {
    "assets/backgrounds/kitchen_scene.png": (
        SCENE_RULES + "a tiny warm cottage kitchen: honey-wood counters and "
        "open shelves with jars and bowls, a small hanging copper pot, a "
        "round window with soft morning light, a little empty food bowl "
        "waiting by the lower-center floor, potted herbs, " + STYLE
    ),
    "assets/backgrounds/bedroom_scene.png": (
        SCENE_RULES + "a snug attic bedroom at night: a round knitted pet "
        "bed on a soft rug at the lower-center, warm fairy lights along a "
        "sloped beam, a crescent moon through a small round window, a "
        "night-lamp glow, drifting dream sparkles, " + STYLE
    ),
    "assets/backgrounds/wardrobe_scene.png": (
        SCENE_RULES + "a cozy dress-up corner: an open honey-wood wardrobe "
        "with tiny hats and bandanas on little hangers, a friendly "
        "standing mirror, a plush pouf, petal-soft morning light, an empty "
        "soft rug spot at the lower-center, " + STYLE
    ),
    "assets/backgrounds/grocery_scene.png": (
        SCENE_RULES + "a tiny cozy neighbourhood grocery interior: warm "
        "wooden shelves with baskets of fruit and jars, a small counter "
        "with a woven basket, a striped awning inside over the shelf, "
        "soft daylight, an empty floor spot at the lower-center, " + STYLE
    ),
}

ITEMS = {
    # foods
    "food_kibble_bowl": "a rounded ceramic pet bowl filled with star-shaped kibble",
    "food_apple": "a shiny crisp red-blush apple with one green leaf",
    "food_carrot": "a plump garden carrot with soft leafy top",
    "food_chicken_bites": "a small plate of golden bite-size chicken pieces",
    "food_salmon_snack": "a cute stylized salmon fillet snack on a leaf plate",
    "food_berry_treat": "a tiny bowl of plump blueberries with a sparkle",
    "food_honey_biscuit": "a golden round biscuit with a honey drizzle heart",
    # toys
    "toy_bouncy_ball": "a bouncy rubber ball with pastel star pattern",
    "toy_tug_rope": "a soft knotted tug rope in pastel colours",
    "toy_feather_wand": "a toy wand with soft pastel feathers and a tiny bell",
    "toy_squeaky_duck": "a cheerful yellow rubber duck bath toy",
    "toy_puzzle_box": "a wooden puzzle snack box with rounded holes and a paw motif",
    "toy_plush_star": "a squishy plush star cushion toy with a stitched smile",
    # care supplies
    "care_vitamin_chew": "a small jar of star-shaped vitamin chew treats",
    "care_soothing_balm": "a tiny pastel jar of soothing balm with a lavender sprig",
    "care_warm_broth": "a steaming little cup of golden broth with hearts of steam",
    # cosmetics
    "wear_bobble_hat": "a tiny knitted bobble hat, cream and peach stripes",
    "wear_flower_crown": "a delicate flower crown of pastel daisies",
    "wear_cozy_beanie": "a tiny cozy beanie in warm honey colour",
    "wear_bell_collar": "a soft pet collar with a tiny golden bell",
    "wear_star_charm": "a pastel pet collar with a small star charm",
    "wear_heart_bandana": "a soft pet bandana with a little heart print",
    "wear_sunbeam_bandana": "a radiant golden-yellow pet bandana with a tiny sun embroidery",
    "wear_moonlight_cap": "a dreamy midnight-blue tiny nightcap with a crescent moon",
    # décor — Cozy Corners (GE-3): Starry Night set
    "decor_star_lamp": "a small bedside lamp shaped like a smiling golden star on a wooden base",
    "decor_moon_tapestry": "a soft hanging wall tapestry of a sleepy crescent moon and tiny stars",
    "decor_dream_mobile": "a gentle hanging baby mobile of pastel clouds and stars on strings",
    # décor — Sunny Meadow set
    "decor_sunflower_pot": "a cheerful terracotta pot with one big smiling sunflower",
    "decor_bee_house": "a tiny wooden bee house with a round door and a friendly bee",
    "decor_picnic_gnome": "a small garden gnome with a mushroom hat holding a picnic basket",
    # décor — singles
    "decor_family_frame": "a warm wooden picture frame with a heart doodle portrait",
    "decor_book_nook": "a tiny stack of pastel storybooks with a star bookmark",
    "decor_snuggle_rug": "a round braided rug in cream and peach swirls",
    "decor_herb_jars": "three little glass jars of green kitchen herbs on a tiny tray",
    "decor_recipe_board": "a small wooden kitchen chalkboard with a chalk heart and spoon",
    "decor_duck_parade": "three tiny rubber ducks in a row, each a different pastel colour",
    "decor_cloud_nightlight": "a soft glowing cloud-shaped nightlight with a sleepy face",
    "decor_wildflower_jar": "a small glass jar holding fresh pastel wildflowers",
}


def load_key() -> str:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if key:
        return key
    env_file = ROOT / ".env"
    if env_file.exists():
        for raw in env_file.read_text().splitlines():
            line = raw.strip().lstrip("﻿")
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, _, value = line.partition("=")
            # Tolerant: whitespace around '=', optional quotes (the .env in
            # this repo had `OPENAI_API_KEY ="..."` — a stray space that
            # breaks shell-sourcing and strict dotenv parsers).
            if name.strip() == "OPENAI_API_KEY":
                return value.strip().strip('"').strip("'")
    print("OPENAI_API_KEY not found in environment or .env", file=sys.stderr)
    sys.exit(2)


def generate(key: str, prompt: str, out: Path, size: str, transparent: bool):
    body = {
        "model": "gpt-image-1",
        "prompt": prompt,
        "size": size,
        "quality": "high" if not transparent else "medium",
        "n": 1,
    }
    if transparent:
        body["background"] = "transparent"
        body["output_format"] = "png"
    req = urllib.request.Request(
        "https://api.openai.com/v1/images/generations",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                data = json.loads(resp.read())
            img = base64.b64decode(data["data"][0]["b64_json"])
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(img)
            return len(img)
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:300]
            if e.code in (429, 500, 502, 503) and attempt < 3:
                wait = 15 * (attempt + 1)
                print(f"  retry {attempt+1} in {wait}s ({e.code})", flush=True)
                time.sleep(wait)
                continue
            raise RuntimeError(f"HTTP {e.code}: {detail}") from e
    raise RuntimeError("unreachable")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=["scenes", "items"])
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    key = load_key()
    jobs = []
    if args.only in (None, "scenes"):
        for rel, prompt in SCENES.items():
            jobs.append((ROOT / rel, prompt, "1024x1536", False))
    if args.only in (None, "items"):
        for name, desc in ITEMS.items():
            jobs.append(
                (
                    ROOT / f"assets/items/{name}.png",
                    ITEM_RULES + desc + ", " + STYLE,
                    "1024x1024",
                    True,
                )
            )

    done = skipped = failed = 0
    for out, prompt, size, transparent in jobs:
        if out.exists() and not args.force:
            skipped += 1
            continue
        print(f"generating {out.relative_to(ROOT)} ...", flush=True)
        try:
            n = generate(key, prompt, out, size, transparent)
            print(f"  ok ({n//1024} KB)", flush=True)
            done += 1
        except Exception as e:  # noqa: BLE001 — report and continue
            print(f"  FAILED: {e}", flush=True)
            failed += 1
    print(f"done={done} skipped={skipped} failed={failed}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
