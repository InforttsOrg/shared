#!/usr/bin/env python3
"""
Infortts 3D Icon Engine - Automatic Background Removal, Normalization & Centering
Ensures all 3D generated icons are exact 1:1 512x512 with 0 noise and dead-center placement.
"""

import sys
import os
import argparse
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import label, binary_fill_holes

try:
    from rembg import remove, new_session
    REMBG_AVAILABLE = True
except ImportError:
    REMBG_AVAILABLE = False


def clean_and_center_3d_icon(input_path, output_path, target_size=512, inner_size=430):
    """
    Takes an input image (raw 3D generation), isolates the 3D subject with clean alpha,
    and places it dead-center in a target_size x target_size transparent canvas.
    """
    im = Image.open(input_path).convert('RGBA')

    # 1. AI background removal if available
    if REMBG_AVAILABLE:
        try:
            with open(input_path, 'rb') as f:
                no_bg_bytes = remove(f.read())
            import io
            im = Image.open(io.BytesIO(no_bg_bytes)).convert('RGBA')
        except Exception as e:
            print(f"[Warning] rembg failed, falling back to heuristic: {e}")

    arr = np.array(im)
    r = arr[:, :, 0].astype(float)
    g = arr[:, :, 1].astype(float)
    b = arr[:, :, 2].astype(float)
    a = arr[:, :, 3].astype(float)

    brightness = (r + g + b) / 3.0
    max_c = np.maximum(np.maximum(r, g), b)
    min_c = np.minimum(np.minimum(r, g), b)
    saturation = max_c - min_c

    # Strip any residual white/grey dither noise or low-alpha spray
    is_noise = ((brightness > 125) & (saturation < 25)) | (a < 30)
    is_subject = (~is_noise) & (a >= 40)

    # Fill small holes in subject and keep primary connected components
    is_subject_filled = binary_fill_holes(is_subject)
    labeled, num_features = label(is_subject_filled)

    if num_features > 0:
        sizes = [np.sum(labeled == i) for i in range(1, num_features + 1)]
        main_label = np.argmax(sizes) + 1
        main_size = sizes[main_label - 1]
        keep_mask = np.zeros_like(is_subject_filled)
        for i, s in enumerate(sizes):
            if s >= main_size * 0.02:
                keep_mask |= (labeled == (i + 1))
    else:
        keep_mask = is_subject

    # Antialiased soft mask
    mask_im = Image.fromarray((keep_mask * 255).astype(np.uint8))
    mask_im = mask_im.filter(ImageFilter.GaussianBlur(0.6))
    soft_mask = np.array(mask_im).astype(float) / 255.0

    new_a = (a * soft_mask).astype(np.uint8)
    arr[:, :, 3] = new_a
    cleaned_im = Image.fromarray(arr)

    # Find exact bounding box of the cleaned 3D icon
    y_idx, x_idx = np.where(arr[:, :, 3] > 20)
    if len(y_idx) == 0:
        raise ValueError(f"No subject detected in {input_path}")

    ymin, ymax = y_idx.min(), y_idx.max()
    xmin, xmax = x_idx.min(), x_idx.max()

    cropped = cleaned_im.crop((xmin, ymin, xmax + 1, ymax + 1))
    cw, ch = cropped.size

    # Fit within inner_size x inner_size preserving exact aspect ratio
    scale = min(inner_size / cw, inner_size / ch)
    nw = max(1, int(cw * scale))
    nh = max(1, int(ch * scale))

    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)

    # Paste at dead center
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    px = (target_size - nw) // 2
    py = (target_size - nh) // 2
    canvas.paste(resized, (px, py), resized)

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    canvas.save(output_path, 'PNG')
    
    # Also save webp version
    webp_path = os.path.splitext(output_path)[0] + '.webp'
    canvas.save(webp_path, 'WEBP')

    print(f"[Icon Engine] Successfully processed {output_path} ({nw}x{nh} centered at {px},{py})")
    return output_path


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Process raw 3D icon into 1:1 512x512 transparent PNG")
    parser.add_argument("input", help="Path to input image")
    parser.add_argument("output", help="Path to output PNG")
    args = parser.parse_args()

    clean_and_center_3d_icon(args.input, args.output)
