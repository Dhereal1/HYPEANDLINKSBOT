#!/usr/bin/env python3
"""
Convert SVG to ICO file with multiple sizes - Fixed version
Properly creates multi-size ICO files
"""
from PIL import Image, ImageDraw
import re
import sys
import struct

def parse_svg_path(path_data):
    """Parse SVG path data into drawable commands
    Handles M (move to), L (line to), and Z (close path) commands
    """
    points = []
    current_x, current_y = 0, 0
    
    # Remove all path commands and split by spaces/commas
    # Pattern to match: M, L, Z followed by optional coordinates
    tokens = re.split(r'[MLZ]', path_data.upper())
    
    # Extract coordinates from the path string
    # The path format is: Mx,y Lx,y Lx,y ... Z
    # We'll extract all coordinate pairs
    coord_pattern = r'([-]?\d+\.?\d*)'
    all_coords = re.findall(coord_pattern, path_data)
    
    # Parse coordinates in pairs (x, y)
    for i in range(0, len(all_coords), 2):
        if i + 1 < len(all_coords):
            x = float(all_coords[i])
            y = float(all_coords[i + 1])
            points.append((x, y))
    
    return points

def render_svg_to_image(size, svg_path, pixel_perfect=True):
    """Render SVG to PIL Image at specified size with pixel-perfect rendering"""
    with open(svg_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()
    
    # Extract viewBox
    viewbox_match = re.search(r'viewBox="([^"]*)"', svg_content)
    if viewbox_match:
        viewbox = [float(x) for x in viewbox_match.group(1).split()]
        svg_width = viewbox[2] - viewbox[0]
        svg_height = viewbox[3] - viewbox[1]
    else:
        width_match = re.search(r'width="(\d+)"', svg_content)
        height_match = re.search(r'height="(\d+)"', svg_content)
        svg_width = float(width_match.group(1)) if width_match else 30
        svg_height = float(height_match.group(1)) if height_match else 30
    
    # Extract path data and fill color from path element
    path_match = re.search(r'<path[^>]*d="([^"]*)"', svg_content)
    if not path_match:
        raise ValueError("No path found in SVG")
    
    path_data = path_match.group(1)
    
    # Extract fill color from the path element specifically (not from SVG root)
    path_element = re.search(r'<path[^>]*>', svg_content)
    if path_element:
        fill_match = re.search(r'fill="([^"]*)"', path_element.group(0))
        fill_color = fill_match.group(1) if fill_match else "black"
    else:
        fill_color = "black"
    
    # Convert color name to RGB
    color_map = {
        "white": (255, 255, 255),
        "black": (0, 0, 0),
        "none": None
    }
    fill_rgb = color_map.get(fill_color.lower(), (0, 0, 0))
    
    # For pixel-perfect rendering at small sizes, render at much higher resolution
    # For larger sizes, use smooth anti-aliasing
    if pixel_perfect:
        if size <= 16:
            # For very small sizes, render at 64x (1024x1024) for maximum precision
            # This ensures perfect pixel alignment when scaled down
            render_size = size * 64
            use_nearest_neighbor = True
        elif size <= 32:
            # For small sizes, render at 32x for precision
            render_size = size * 32
            use_nearest_neighbor = True
        elif size <= 48:
            # For medium-small sizes, render at 16x
            render_size = size * 16
            use_nearest_neighbor = True
        elif size <= 64:
            # For medium sizes, render at 8x with smooth scaling
            render_size = size * 8
            use_nearest_neighbor = False
        else:
            # For larger sizes, render at 16x with smooth scaling for maximum smoothness
            render_size = size * 16
            use_nearest_neighbor = False
    else:
        render_size = size
        use_nearest_neighbor = False
    
    # Create image with transparency at render size
    img = Image.new('RGBA', (render_size, render_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Parse path and draw
    points = parse_svg_path(path_data)
    if points:
        # Scale points to render size
        scale_x = render_size / svg_width
        scale_y = render_size / svg_height
        
        # For pixel-perfect rendering, use precise coordinate calculation
        # and ensure perfect alignment to pixel grid
        if pixel_perfect:
            # Use precise rounding with proper pixel alignment
            scaled_points = []
            for x, y in points:
                # Calculate precise position
                px = x * scale_x
                py = y * scale_y
                # Round to nearest pixel center
                scaled_points.append((int(round(px)), int(round(py))))
        else:
            # Use rounding for larger sizes (allows smooth curves)
            scaled_points = [(int(round(x * scale_x)), int(round(y * scale_y))) for x, y in points]
        
        # Draw polygon (assuming closed path)
        if fill_rgb:
            if len(fill_rgb) == 3:
                fill_rgba = fill_rgb + (255,)
            else:
                fill_rgba = fill_rgb
            
            # Ensure polygon is closed (add first point at end if not already there)
            if len(scaled_points) > 2:
                if scaled_points[0] != scaled_points[-1]:
                    scaled_points.append(scaled_points[0])
                
                # Draw the polygon with integer coordinates
                draw.polygon(scaled_points, fill=fill_rgba)
    
    # Scale down with appropriate resampling
    if render_size != size:
        if use_nearest_neighbor:
            # Use nearest-neighbor for small sizes to preserve pixel-perfect edges
            img = img.resize((size, size), Image.Resampling.NEAREST)
        else:
            # Use LANCZOS for larger sizes to get smooth, anti-aliased lines
            # LANCZOS provides the best quality for downscaling with smooth edges
            img = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Optional: Apply slight sharpening to enhance edge definition
            # This helps maintain crispness while keeping smoothness
            from PIL import ImageFilter
            img = img.filter(ImageFilter.UnsharpMask(radius=0.5, percent=100, threshold=3))
    
    return img

def create_multi_size_ico(images, output_path):
    """
    Create a proper multi-size ICO file
    ICO format structure:
    - ICONDIR header (6 bytes)
    - ICONDIRENTRY[] (16 bytes each)
    - Image data for each size
    """
    # ICO file header
    ico_data = bytearray()
    
    # ICONDIR structure
    ico_data.extend(struct.pack('<HHH', 0, 1, len(images)))  # Reserved, Type (1=ICO), Count
    
    # Calculate offsets
    offset = 6 + (16 * len(images))  # Header + directory entries
    
    # Convert each image to PNG and store metadata
    image_data_list = []
    for img in images:
        # Convert to RGBA if needed
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Save as PNG bytes
        import io
        png_bytes = io.BytesIO()
        img.save(png_bytes, format='PNG')
        png_data = png_bytes.getvalue()
        
        image_data_list.append(png_data)
        
        # ICONDIRENTRY structure
        width = img.width if img.width < 256 else 0
        height = img.height if img.height < 256 else 0
        ico_data.extend(struct.pack('<BBBBHHII',
            width,           # Width (0 = 256)
            height,          # Height (0 = 256)
            0,               # Color palette (0 = no palette)
            0,               # Reserved
            1,               # Color planes
            32,              # Bits per pixel (32 = RGBA)
            len(png_data),   # Size of image data
            offset           # Offset to image data
        ))
        
        offset += len(png_data)
    
    # Append all image data
    for png_data in image_data_list:
        ico_data.extend(png_data)
    
    # Write to file
    with open(output_path, 'wb') as f:
        f.write(ico_data)

def svg_to_ico(svg_path, ico_path, sizes=None):
    """Convert SVG file to ICO file with multiple sizes"""
    if sizes is None:
        sizes = [16, 32, 48, 64, 128, 256]
    
    # Convert SVG to images for each size
    images = []
    for size in sizes:
        img = render_svg_to_image(size, svg_path)
        images.append(img)
    
    # Create multi-size ICO file
    create_multi_size_ico(images, ico_path)
    
    # Verify
    try:
        verify_img = Image.open(ico_path)
        print(f"✓ Successfully created {ico_path}")
        print(f"  File size: {len(open(ico_path, 'rb').read())} bytes")
        print(f"  Contains {len(images)} icon sizes: {sizes}")
    except Exception as e:
        print(f"Warning: Could not verify ICO file: {e}")
        print(f"Created {ico_path} with sizes: {sizes}")

if __name__ == "__main__":
    svg_file = "xp7k.svg"
    ico_file = "xp7k.ico"
    
    if len(sys.argv) > 1:
        svg_file = sys.argv[1]
    if len(sys.argv) > 2:
        ico_file = sys.argv[2]
    
    svg_to_ico(svg_file, ico_file)
    print(f"✓ Converted {svg_file} → {ico_file}")

