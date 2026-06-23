from PIL import Image
import os

ASSETS = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
ASSETS = os.path.normpath(ASSETS)

logo_path = os.path.join(ASSETS, "logo.png")
img = Image.open(logo_path)
orig_size = os.path.getsize(logo_path)
print(f"Original: {img.size}, {orig_size} bytes")

img_2x = img.resize((726, 112), Image.LANCZOS)
logo_webp = os.path.join(ASSETS, "logo.webp")
img_2x.save(logo_webp, "WEBP", quality=82)
size_2x = os.path.getsize(logo_webp)
print(f"logo.webp (2x): {img_2x.size}, {size_2x} bytes")

img_1x = img.resize((363, 56), Image.LANCZOS)
logo_363 = os.path.join(ASSETS, "logo-363.webp")
img_1x.save(logo_363, "WEBP", quality=82)
size_1x = os.path.getsize(logo_363)
print(f"logo-363.webp (1x): {img_1x.size}, {size_1x} bytes")

print(f"Saved vs original: {orig_size - size_2x - size_1x} bytes")

splash_png = os.path.join(ASSETS, "splash-screen.png")
splash = Image.open(splash_png)
splash_orig = os.path.getsize(splash_png)
splash_webp = os.path.join(ASSETS, "splash-screen.webp")
splash.save(splash_webp, "WEBP", quality=78)
splash_new = os.path.getsize(splash_webp)
print(f"splash-screen.webp: {splash.size}, {splash_new} bytes (was {splash_orig})")
