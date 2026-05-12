from PIL import Image
import os

img = Image.open("logo.png")
orig_size = os.path.getsize("logo.png")
print(f"Original: {img.size}, {orig_size} bytes")

img_2x = img.resize((726, 112), Image.LANCZOS)
img_2x.save("logo.webp", "WEBP", quality=82)
size_2x = os.path.getsize("logo.webp")
print(f"logo.webp (2x): {img_2x.size}, {size_2x} bytes")

img_1x = img.resize((363, 56), Image.LANCZOS)
img_1x.save("logo-363.webp", "WEBP", quality=82)
size_1x = os.path.getsize("logo-363.webp")
print(f"logo-363.webp (1x): {img_1x.size}, {size_1x} bytes")

print(f"Saved vs original: {orig_size - size_2x - size_1x} bytes")

splash = Image.open("splash-screen.png")
splash_orig = os.path.getsize("splash-screen.png")
splash.save("splash-screen.webp", "WEBP", quality=78)
splash_new = os.path.getsize("splash-screen.webp")
print(f"splash-screen.webp: {splash.size}, {splash_new} bytes (was {splash_orig})")
