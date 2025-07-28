from PIL import Image
import os
import io

def compress_image(input_path, target_kb_list=[700, 500, 300]):
    # Load image
    img = Image.open(input_path)

    # Convert to RGB if needed (PNG, etc.)
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")

    base_name, ext = os.path.splitext(input_path)

    for target_kb in target_kb_list:
        # Start with high quality
        quality = 95
        step = 5  # reduce step size

        while True:
            buffer = io.BytesIO()
            img.save(buffer, format="JPEG", quality=quality, optimize=True)
            size_kb = len(buffer.getvalue()) / 1024

            if size_kb <= target_kb or quality <= 5:
                # Save final file
                output_path = f"{base_name}_{target_kb}kb.jpg"
                with open(output_path, "wb") as f:
                    f.write(buffer.getvalue())
                print(f"✅ Saved: {output_path} ({size_kb:.1f} KB, quality={quality})")
                break

            quality -= step  # decrease quality

# Example usage:
compress_image("example.jpg", [700, 500, 300])
