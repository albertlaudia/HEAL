#!/usr/bin/env python3
"""
HEAL — App icon generator.

Generates the missing iOS sizes (76, 152, 167) and the web favicon set
from the master 1024x1024 iOS icon.

Usage: python3 tools/generate-app-icons.py

Requires the PIL library (pip install pillow).
"""
import os
import struct
import sys
import zlib
from pathlib import Path

# Pure-Python PNG writer (no PIL dependency required)
def write_png(path, width, height, rgba_pixels):
    """Write a minimal RGB/RGBA PNG file. rgba_pixels is a bytes object
    of length width*height*4 (RGBA, 0-255 per channel)."""
    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data +
                struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)  # 8-bit RGBA
    # Compress the pixel data, prefixed by a 0 filter byte per scanline.
    raw = b''.join(b'\x00' + rgba_pixels[y*width*4:(y+1)*width*4]
                    for y in range(height))
    idat = zlib.compress(raw, 9)
    with open(path, 'wb') as f:
        f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) +
                chunk(b'IEND', b''))

def read_png(path):
    """Read a PNG and return (width, height, rgba_pixels_bytes).
    Only handles RGB (color type 2) and RGBA (color type 6) — which is
    all we ship."""
    with open(path, 'rb') as f:
        data = f.read()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError(f'Not a PNG: {path}')
    pos = 8
    width = height = bit_depth = color_type = 0
    idat = b''
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        tag = data[pos+4:pos+8]
        body = data[pos+8:pos+8+length]
        pos += 8 + length + 4
        if tag == b'IHDR':
            width, height, bit_depth, color_type = struct.unpack('>IIBB', body[:10])
        elif tag == b'IDAT':
            idat += body
        elif tag == b'IEND':
            break
    if bit_depth != 8:
        raise ValueError(f'Only 8-bit PNGs supported: {path}')
    if color_type not in (2, 6):
        raise ValueError(f'Only RGB/RGBA supported: {path} (color_type={color_type})')
    raw = zlib.decompress(idat)
    bpp = 3 if color_type == 2 else 4
    stride = width * bpp
    pixels = bytearray()
    for y in range(height):
        filt = raw[y*(stride+1)]
        row = bytearray(raw[y*(stride+1)+1 : (y+1)*(stride+1)])
        if filt == 0:
            pass
        elif filt == 1:  # Sub
            for x in range(bpp, stride):
                row[x] = (row[x] + row[x-bpp]) & 0xff
        elif filt == 2:  # Up
            prev = raw[(y-1)*(stride+1)+1 : y*(stride+1)] if y > 0 else bytes(stride)
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 0xff
        elif filt == 3:  # Average
            prev = raw[(y-1)*(stride+1)+1 : y*(stride+1)] if y > 0 else bytes(stride)
            for x in range(stride):
                left = row[x-bpp] if x >= bpp else 0
                row[x] = (row[x] + (left + prev[x]) // 2) & 0xff
        elif filt == 4:  # Paeth
            prev = raw[(y-1)*(stride+1)+1 : y*(stride+1)] if y > 0 else bytes(stride)
            for x in range(stride):
                a = row[x-bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x-bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                row[x] = (row[x] + pr) & 0xff
        else:
            raise ValueError(f'Unknown filter {filt}')
        pixels += row
    if bpp == 3:
        # Convert RGB to RGBA (full alpha)
        out = bytearray(width * height * 4)
        for i in range(width * height):
            out[i*4:i*4+3] = pixels[i*3:i*3+3]
            out[i*4+3] = 255
        return width, height, bytes(out)
    return width, height, bytes(pixels)

def resize_pixels(width, height, src_w, src_h, src_pixels, algo='box'):
    """Simple nearest-neighbor resize. Good enough for square icons
    where a pixelated look is fine (HEAL's flat design)."""
    out = bytearray(width * height * 4)
    for y in range(height):
        sy = (y * src_h) // height
        for x in range(width):
            sx = (x * src_w) // width
            sidx = (sy * src_w + sx) * 4
            didx = (y * width + x) * 4
            out[didx:didx+4] = src_pixels[sidx:sidx+4]
    return bytes(out)

def downscale_box(width, height, src_w, src_h, src_pixels):
    """Box-filter downscale (better than nearest for shrinking)."""
    out = bytearray(width * height * 4)
    for y in range(height):
        sy_start = (y * src_h) // height
        sy_end = ((y + 1) * src_h) // height
        for x in range(width):
            sx_start = (x * src_w) // width
            sx_end = ((x + 1) * src_w) // width
            r = g = b = a = n = 0
            for sy in range(sy_start, sy_end):
                for sx in range(sx_start, sx_end):
                    p = src_pixels[(sy * src_w + sx) * 4:(sy * src_w + sx) * 4 + 4]
                    r += p[0]; g += p[1]; b += p[2]; a += p[3]; n += 1
            if n == 0: n = 1
            didx = (y * width + x) * 4
            out[didx]     = r // n
            out[didx + 1] = g // n
            out[didx + 2] = b // n
            out[didx + 3] = a // n
    return bytes(out)

def main():
    repo = Path(__file__).resolve().parent.parent
    master = repo / "media" / "app-icon" / "ios" / "Icon-App-1024x1024@1x.png"
    if not master.exists():
        print(f'ERROR: master icon not found at {master}')
        sys.exit(1)
    print(f'Reading master from {master.name}...')
    src_w, src_h, src_pixels = read_png(master)
    if src_w != src_h:
        print(f'ERROR: master icon is {src_w}x{src_h}, expected square')
        sys.exit(1)
    if src_w < 1024:
        print(f'WARN: master is only {src_w}x{src_w}; upscaling lower-res masters gives blurry results')

    # ── iOS missing sizes ──
    ios_dir = repo / "media" / "app-icon" / "ios"
    ios_sizes = {
        "Icon-App-76x76@1x.png":       76,
        "Icon-App-76x76@2x.png":      152,
        "Icon-App-83.5x83.5@2x.png":  167,
    }
    print(f'\n── Generating {len(ios_sizes)} missing iOS sizes ──')
    for name, size in sorted(ios_sizes.items()):
        path = ios_dir / name
        if path.exists():
            print(f'  SKIP     {name}  (already exists)')
            continue
        print(f'  CREATE   {name}  ({size}x{size})')
        # For 167, scale from 1024 first
        if size <= 256:
            tmp_w, tmp_h, tmp_pixels = src_w, src_h, src_pixels
        else:
            # Two-step downscale for better quality
            tmp_w, tmp_h, tmp_pixels = 256, 256, downscale_box(256, 256, src_w, src_h, src_pixels)
        pixels = downscale_box(size, size, tmp_w, tmp_h, tmp_pixels)
        write_png(path, size, size, pixels)
        print(f'           wrote {path.relative_to(repo)}')

    # ── Web favicons ──
    web_dir = repo / "web" / "public"
    web_dir.mkdir(parents=True, exist_ok=True)
    web_sizes = {
        "favicon-16x16.png":  16,
        "favicon-32x32.png":  32,
        "apple-touch-icon.png":180,
        "android-chrome-192x192.png":192,
        "android-chrome-512x512.png":512,
    }
    print(f'\n── Generating {len(web_sizes)} web favicon sizes ──')
    for name, size in sorted(web_sizes.items()):
        path = web_dir / name
        if path.exists():
            print(f'  SKIP     {name}  (already exists)')
            continue
        print(f'  CREATE   {name}  ({size}x{size})')
        tmp_w, tmp_h, tmp_pixels = 256, 256, downscale_box(256, 256, src_w, src_h, src_pixels)
        pixels = downscale_box(size, size, tmp_w, tmp_h, tmp_pixels)
        write_png(path, size, size, pixels)
        print(f'           wrote {path.relative_to(repo)}')

    # favicon.ico is just the 32x32 PNG with .ico extension — most browsers
    # accept this. (For full multi-resolution ICO we'd need a proper encoder.)
    ico_path = web_dir / "favicon.ico"
    if not ico_path.exists():
        # Build a single-image 32x32 ICO (header + 1 entry)
        size = 32
        tmp_w, tmp_h, tmp_pixels = 256, 256, downscale_box(256, 256, src_w, src_h, src_pixels)
        pixels = downscale_box(size, size, tmp_w, tmp_h, tmp_pixels)
        # Write the PNG bytes first
        import io
        png_buf = io.BytesIO()
        png_buf.write(b'\x89PNG\r\n\x1a\n')
        # IHDR
        def chunk(tag, data):
            return (struct.pack('>I', len(data)) + tag + data +
                    struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))
        ihdr = struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)
        raw = b''.join(b'\x00' + pixels[y*size*4:(y+1)*size*4] for y in range(size))
        idat = zlib.compress(raw, 9)
        png_bytes = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')
        # ICO header: 6 bytes + 16 bytes per entry + PNG data
        ico = struct.pack('<HHH', 0, 1, 1)  # reserved=0, type=1(icon), count=1
        ico += struct.pack('<BBBBHHII', size, size, 0, 0, 1, 32, len(png_bytes), 22)
        ico += png_bytes
        with open(ico_path, 'wb') as f:
            f.write(ico)
        print(f'  CREATE   favicon.ico  (32x32 PNG-in-ICO)')
    else:
        print(f'  SKIP     favicon.ico  (already exists)')

    print('\nDone. Run `python3 tools/verify-app-icons.py` to confirm.')

if __name__ == '__main__':
    main()
