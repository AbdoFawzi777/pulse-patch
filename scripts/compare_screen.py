import sys
import os
import argparse
import math
from PIL import Image, ImageDraw, ImageFont, ImageChops

def compare(screen_name):
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    app_img_path = os.path.join(base_dir, "docs", "screenshots", f"{screen_name}_app.png")
    ref_img_path = os.path.join(base_dir, "docs", "design", f"{screen_name}.png")
    compare_out_path = os.path.join(base_dir, "docs", "screenshots", f"{screen_name}_compare.png")

    if not os.path.exists(app_img_path):
        print(f"Error: App image not found: {app_img_path}")
        return False
    if not os.path.exists(ref_img_path):
        print(f"Error: Reference image not found: {ref_img_path}")
        return False

    app_img = Image.open(app_img_path).convert("RGBA")
    ref_img = Image.open(ref_img_path).convert("RGBA")

    # Target logical size 390x844 (or app size)
    target_w, target_h = 390, 844
    if screen_name == "App icon":
        target_w, target_h = 360, 360
        # If ref is presentation canvas (2200x1240), crop the 360x360 icon @2x (96, 188, 816, 908)
        if ref_img.width > 1000:
            ref_img = ref_img.crop((96, 188, 96 + 720, 188 + 720))

    app_resized = app_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    ref_resized = ref_img.resize((target_w, target_h), Image.Resampling.LANCZOS)

    # Compute difference
    diff = ImageChops.difference(app_resized, ref_resized)
    stat = [c for c in diff.split()]
    # RGB channels
    r_diff = list(stat[0].getdata())
    g_diff = list(stat[1].getdata())
    b_diff = list(stat[2].getdata())
    total_pixels = len(r_diff)

    sum_sq = 0
    close_pixels = 0
    threshold = 25 # tolerance per channel

    for i in range(total_pixels):
        dr = r_diff[i]
        dg = g_diff[i]
        db = b_diff[i]
        sum_sq += (dr*dr + dg*dg + db*db) / 3.0
        if dr <= threshold and dg <= threshold and db <= threshold:
            close_pixels += 1

    rmse = math.sqrt(sum_sq / total_pixels)
    match_pct = (close_pixels / total_pixels) * 100.0

    # Create side-by-side comparison image
    label_h = 40
    combo_w = target_w * 2 + 20
    combo_h = target_h + label_h + 20
    combo = Image.new("RGBA", (combo_w, combo_h), (10, 15, 30, 255))
    draw = ImageDraw.Draw(combo)

    # Labels
    draw.text((20, 12), f"Flutter App ({screen_name})", fill=(255, 255, 255, 255))
    draw.text((target_w + 30, 12), f"Design Reference ({screen_name})", fill=(255, 255, 255, 255))

    # Paste images
    combo.paste(app_resized, (10, label_h + 10))
    combo.paste(ref_resized, (target_w + 20, label_h + 10))

    os.makedirs(os.path.dirname(compare_out_path), exist_ok=True)
    combo.save(compare_out_path)

    print(f"Comparison saved to: {compare_out_path}")
    print(f"RMSE: {rmse:.2f} | Match (% within tol): {match_pct:.2f}%")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--screen", required=True, help="Name of screen, e.g. Home, Measuring, Heart Rate, AI Insights, Connect device, History, App icon")
    args = parser.parse_args()
    compare(args.screen)
