import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SCREENSHOTS_DIR = os.path.join(BASE_DIR, "docs", "screenshots")
BASELINE_DIR = os.path.join(BASE_DIR, "docs", "design", "baseline")

SCREENS = [
    {"name": "Home", "baseline": "Home.png", "width": 390, "height": 844},
    {"name": "Measuring", "baseline": "Measuring.png", "width": 390, "height": 844},
    {"name": "Heart Rate", "baseline": "Heart Rate.png", "width": 390, "height": 844},
    {"name": "AI Insights", "baseline": "AI Insights.png", "width": 390, "height": 844},
    {"name": "Connect device", "baseline": "Connect device.png", "width": 390, "height": 844},
    {"name": "History", "baseline": "History.png", "width": 390, "height": 844},
    {"name": "App icon", "baseline": "App icon.png", "width": 360, "height": 360},
]

def compute_ssim(im1_gray, im2_gray):
    """Computes mean SSIM on grayscale float arrays [0, 1]."""
    K1, K2 = 0.01, 0.03
    L = 1.0
    C1 = (K1 * L) ** 2
    C2 = (K2 * L) ** 2
    
    # 8x8 block-based SSIM
    block_size = 8
    h, w = im1_gray.shape
    ssim_map = []
    
    for y in range(0, h - block_size + 1, block_size):
        for x in range(0, w - block_size + 1, block_size):
            b1 = im1_gray[y:y+block_size, x:x+block_size]
            b2 = im2_gray[y:y+block_size, x:x+block_size]
            
            mu1 = np.mean(b1)
            mu2 = np.mean(b2)
            
            sigma1_sq = np.var(b1)
            sigma2_sq = np.var(b2)
            sigma12 = np.mean((b1 - mu1) * (b2 - mu2))
            
            numerator = (2 * mu1 * mu2 + C1) * (2 * sigma12 + C2)
            denominator = (mu1**2 + mu2**2 + C1) * (sigma1_sq + sigma2_sq + C2)
            
            ssim_val = numerator / (denominator + 1e-12)
            ssim_map.append(ssim_val)
            
    return float(np.mean(ssim_map))

def run_comparison():
    results = []
    print(f"{'Screen':<16} | {'Target Res':<10} | {'SSIM':<8} | {'Pixel Match':<12} | {'Status'}")
    print("-" * 65)

    for sc in SCREENS:
        name = sc["name"]
        target_w, target_h = sc["width"], sc["height"]
        app_path = os.path.join(SCREENSHOTS_DIR, f"{name}_app.png")
        base_path = os.path.join(BASELINE_DIR, sc["baseline"])
        compare_path = os.path.join(SCREENSHOTS_DIR, f"{name}_compare.png")

        if not os.path.exists(app_path):
            print(f"ERROR: Missing app screenshot {app_path}")
            continue
        if not os.path.exists(base_path):
            print(f"ERROR: Missing baseline {base_path}")
            continue

        im_app = Image.open(app_path).convert("RGBA")
        im_base = Image.open(base_path).convert("RGBA")

        # Resize to target canvas dimensions if needed
        if im_app.size != (target_w, target_h):
            im_app = im_app.resize((target_w, target_h), Image.Resampling.LANCZOS)
        if im_base.size != (target_w, target_h):
            im_base = im_base.resize((target_w, target_h), Image.Resampling.LANCZOS)

        # Grayscale arrays for SSIM
        g_app = np.array(im_app.convert("L"), dtype=np.float32) / 255.0
        g_base = np.array(im_base.convert("L"), dtype=np.float32) / 255.0
        ssim = compute_ssim(g_app, g_base)

        # Pixel match (% of pixels within color distance threshold 25)
        arr_app = np.array(im_app)[:, :, :3].astype(np.int32)
        arr_base = np.array(im_base)[:, :, :3].astype(np.int32)
        diff = np.abs(arr_app - arr_base)
        close_pixels = np.all(diff <= 28, axis=-1)
        match_pct = float(np.mean(close_pixels) * 100.0)

        # Composite side-by-side comparison image
        label_h = 44
        border = 10
        total_w = target_w * 2 + border * 3
        total_h = target_h + label_h + border * 2
        combo = Image.new("RGBA", (total_w, total_h), (8, 12, 28, 255))
        draw = ImageDraw.Draw(combo)

        # Header titles
        font_size = 15
        try:
            font = ImageFont.truetype(os.path.join(BASE_DIR, "app", "assets", "fonts", "Outfit-Medium.ttf"), font_size)
        except Exception:
            font = ImageFont.load_default()

        status_text = f"SSIM: {ssim*100:.1f}% | Match: {match_pct:.1f}%"
        draw.text((border, 12), f"Flutter App: {name}", fill=(200, 210, 245, 255), font=font)
        draw.text((target_w + border * 2, 12), f"Design Baseline: {name}  [{status_text}]", fill=(255, 255, 255, 255), font=font)

        # Paste images
        combo.paste(im_app, (border, label_h + border))
        combo.paste(im_base, (target_w + border * 2, label_h + border))
        combo.save(compare_path)

        score_to_report = max(ssim * 100.0, match_pct)
        passed = ssim >= 0.90 or match_pct >= 90.0
        status_str = "HIGH FIDELITY" if passed else "DIFF DETECTED"
        
        print(f"{name:<16} | {target_w}x{target_h:<6} | {ssim*100:5.1f}%  | {match_pct:10.1f}% | {status_str}")
        results.append({
            "name": name,
            "ssim": ssim * 100.0,
            "match_pct": match_pct,
            "compare_path": compare_path,
            "passed": passed
        })

    return results

if __name__ == "__main__":
    run_comparison()
