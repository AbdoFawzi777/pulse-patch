import os
import subprocess
import base64
from PIL import Image

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCE_DIR = os.path.join(BASE_DIR, "docs", "design", "source")
BASELINE_DIR = os.path.join(BASE_DIR, "docs", "design", "baseline")
FONTS_DIR = os.path.join(BASE_DIR, "app", "assets", "fonts")
EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

os.makedirs(BASELINE_DIR, exist_ok=True)

def get_font_faces():
    light_path = os.path.join(FONTS_DIR, "Outfit-Light.ttf")
    reg_path = os.path.join(FONTS_DIR, "Outfit-Regular.ttf")
    med_path = os.path.join(FONTS_DIR, "Outfit-Medium.ttf")
    
    css = """<style>
* { box-sizing: border-box; }
"""
    if os.path.exists(light_path):
        with open(light_path, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
            css += f"""@font-face {{
  font-family: 'Outfit';
  font-weight: 300;
  src: url('data:font/truetype;charset=utf-8;base64,{b64}') format('truetype');
}}\n"""
    if os.path.exists(reg_path):
        with open(reg_path, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
            css += f"""@font-face {{
  font-family: 'Outfit';
  font-weight: 400;
  src: url('data:font/truetype;charset=utf-8;base64,{b64}') format('truetype');
}}\n"""
    if os.path.exists(med_path):
        with open(med_path, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("ascii")
            css += f"""@font-face {{
  font-family: 'Outfit';
  font-weight: 500;
  src: url('data:font/truetype;charset=utf-8;base64,{b64}') format('truetype');
}}\n"""
    css += "</style>\n"
    return css

SCREENS = [
    {"source": "Main.dc.html", "names": ["Main.png", "Home.png"], "width": 390, "height": 844},
    {"source": "Live.dc.html", "names": ["Live.png", "Measuring.png"], "width": 390, "height": 844},
    {"source": "Detail.dc.html", "names": ["Detail.png", "Heart Rate.png"], "width": 390, "height": 844},
    {"source": "Insights.dc.html", "names": ["Insights.png", "AI Insights.png"], "width": 390, "height": 844},
    {"source": "Device.dc.html", "names": ["Device.png", "Connect device.png"], "width": 390, "height": 844},
    {"source": "History.dc.html", "names": ["History.png"], "width": 390, "height": 844},
    {"source": "Icon.dc.html", "names": ["Icon.png", "App icon.png"], "width": 1100, "height": 620, "is_icon": True},
]

def render_screens():
    font_css = get_font_faces()
    for sc in SCREENS:
        src_file = os.path.join(SOURCE_DIR, sc["source"])
        if not os.path.exists(src_file):
            print(f"Error: {src_file} does not exist")
            continue
        
        with open(src_file, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Inject local embedded fonts right before </head>
        injected_content = content.replace("</head>", f"{font_css}</head>")
        temp_html = os.path.join(BASELINE_DIR, f"temp_{sc['source']}")
        with open(temp_html, "w", encoding="utf-8") as f:
            f.write(injected_content)
        
        file_url = f"file:///{temp_html.replace(os.sep, '/')}"
        temp_out = os.path.join(BASELINE_DIR, f"temp_render_{sc['names'][0]}")
        
        # Run Edge headless
        cmd = [
            EDGE_PATH,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            f"--window-size={sc['width']},{sc['height']}",
            f"--screenshot={temp_out}",
            file_url
        ]
        
        print(f"Rendering {sc['source']} to {sc['names']} at {sc['width']}x{sc['height']}...")
        proc = subprocess.run(cmd, capture_output=True, text=True)
        
        if os.path.exists(temp_html):
            os.remove(temp_html)
            
        if not os.path.exists(temp_out):
            print(f"Failed to render {sc['source']}. Error: {proc.stderr}")
            continue

        im = Image.open(temp_out).convert("RGBA")
        
        if sc.get("is_icon", False):
            # In Icon.dc.html, the 360x360 icon is inside:
            # padding 48px, top padding 48px + h1 (font 26px line-height 33px + margin-bottom 20px) = 101px
            # Exact bounding rect: (48, 101, 48 + 360, 101 + 360)
            icon_crop = im.crop((48, 101, 48 + 360, 101 + 360))
            for name in sc["names"]:
                dest = os.path.join(BASELINE_DIR, name)
                icon_crop.save(dest)
                print(f"Saved icon baseline: {dest} ({icon_crop.size})")
        else:
            if im.size != (390, 844):
                im = im.resize((390, 844), Image.Resampling.LANCZOS)
            for name in sc["names"]:
                dest = os.path.join(BASELINE_DIR, name)
                im.save(dest)
                print(f"Saved baseline: {dest} ({im.size})")

        if os.path.exists(temp_out):
            os.remove(temp_out)

if __name__ == "__main__":
    render_screens()
