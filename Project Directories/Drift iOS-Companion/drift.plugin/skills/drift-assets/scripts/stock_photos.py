"""
Drift Stock Photo Sourcer

Downloads free stock photos from Unsplash and Pexels using their official APIs,
processes them with image effects, and exports to Xcode asset catalogs.

Credentials are read from:
  1. Environment variables: UNSPLASH_ACCESS_KEY, PEXELS_API_KEY
  2. Drift credentials file: /tmp/drift_credentials.env (written by DriftBar)
  3. CLI arguments: --unsplash-key, --pexels-key

Usage:
    python3 stock_photos.py search "warm coffee lifestyle" --source unsplash --count 5
    python3 stock_photos.py download <url> --output /path/to/image.jpg
    python3 stock_photos.py export <image> --xcassets /path/to/Assets.xcassets --name hero_image --preset moody
    python3 stock_photos.py pipeline "mountain landscape" --xcassets ./Assets.xcassets --name hero --preset hero
"""

import argparse
import json
import os
import sys
import tempfile
import urllib.request
import urllib.parse
from pathlib import Path

# Import effects engine
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)
from image_effects import apply_pipeline, export_for_ios, PRESETS, EFFECTS

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow is required. Install with: pip3 install Pillow")
    sys.exit(1)


# ─── Credential Loading ─────────────────────────────────────────────

def load_credentials() -> dict:
    """Load API credentials from env vars or drift credentials file."""
    creds = {
        "unsplash": os.environ.get("UNSPLASH_ACCESS_KEY", ""),
        "pexels": os.environ.get("PEXELS_API_KEY", ""),
        "figma": os.environ.get("FIGMA_PERSONAL_TOKEN", ""),
    }

    # Try drift credentials file (written by DriftBar Keychain export, 0600 perms)
    env_file = os.path.join(tempfile.gettempdir(), "drift_credentials.env")
    if os.path.exists(env_file):
        try:
            with open(env_file) as f:
                for line in f:
                    line = line.strip()
                    if '=' in line and not line.startswith('#'):
                        key, val = line.split('=', 1)
                        if key == "UNSPLASH_ACCESS_KEY" and not creds["unsplash"]:
                            creds["unsplash"] = val
                        elif key == "PEXELS_API_KEY" and not creds["pexels"]:
                            creds["pexels"] = val
                        elif key == "FIGMA_PERSONAL_TOKEN" and not creds["figma"]:
                            creds["figma"] = val
        except (IOError, ValueError):
            pass

    return creds


CREDS = load_credentials()


# ─── Unsplash API ───────────────────────────────────────────────────

def search_unsplash(query: str, count: int = 5, orientation: str = "portrait") -> list:
    """Search Unsplash using the official API."""
    access_key = CREDS.get("unsplash", "")

    if not access_key:
        print("WARNING: No Unsplash API key found. Set UNSPLASH_ACCESS_KEY or configure in DriftBar settings.")
        print("  Get a free key at: https://unsplash.com/developers")
        # Fall back to source URLs (limited, no metadata)
        return _unsplash_source_fallback(query, count, orientation)

    params = urllib.parse.urlencode({
        "query": query,
        "per_page": count,
        "orientation": orientation,
    })
    url = f"https://api.unsplash.com/search/photos?{params}"

    req = urllib.request.Request(url, headers={
        "Authorization": f"Client-ID {access_key}",
        "Accept-Version": "v1",
    })

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())

        results = []
        for photo in data.get("results", []):
            results.append({
                "id": photo["id"],
                "url_full": photo["urls"]["full"],
                "url_regular": photo["urls"]["regular"],
                "url_small": photo["urls"]["small"],
                "download_url": photo["links"]["download"],
                "width": photo["width"],
                "height": photo["height"],
                "description": photo.get("description") or photo.get("alt_description", ""),
                "photographer": photo["user"]["name"],
                "photographer_url": photo["user"]["links"]["html"],
                "source": "unsplash",
                "license": "Unsplash License (free for commercial use)",
                "attribution": f"Photo by {photo['user']['name']} on Unsplash",
            })
        return results

    except Exception as e:
        print(f"Unsplash API error: {e}")
        return _unsplash_source_fallback(query, count, orientation)


def _unsplash_source_fallback(query: str, count: int, orientation: str) -> list:
    """Fallback to Unsplash Source URLs when no API key is available."""
    size = "1080x1920" if orientation == "portrait" else "1920x1080"
    urls = []
    for i in range(count):
        encoded = urllib.parse.quote(query)
        urls.append({
            "url_regular": f"https://source.unsplash.com/{size}/?{encoded}&sig={i}",
            "source": "unsplash_source",
            "license": "Unsplash License",
            "note": "Limited results without API key. Configure key in DriftBar for better results.",
        })
    return urls


# ─── Pexels API ─────────────────────────────────────────────────────

def search_pexels(query: str, count: int = 5, orientation: str = "portrait") -> list:
    """Search Pexels using the official API."""
    api_key = CREDS.get("pexels", "")

    if not api_key:
        print("WARNING: No Pexels API key found. Set PEXELS_API_KEY or configure in DriftBar settings.")
        print("  Get a free key at: https://www.pexels.com/api/new/")
        return []

    params = urllib.parse.urlencode({
        "query": query,
        "per_page": count,
        "orientation": orientation,
    })
    url = f"https://api.pexels.com/v1/search?{params}"

    req = urllib.request.Request(url, headers={
        "Authorization": api_key,
    })

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())

        results = []
        for photo in data.get("photos", []):
            results.append({
                "id": photo["id"],
                "url_full": photo["src"]["original"],
                "url_regular": photo["src"]["large2x"],
                "url_small": photo["src"]["medium"],
                "width": photo["width"],
                "height": photo["height"],
                "description": photo.get("alt", ""),
                "photographer": photo["photographer"],
                "photographer_url": photo["photographer_url"],
                "source": "pexels",
                "license": "Pexels License (free for commercial use)",
                "attribution": f"Photo by {photo['photographer']} on Pexels",
            })
        return results

    except Exception as e:
        print(f"Pexels API error: {e}")
        return []


# ─── Download ────────────────────────────────────────────────────────

def download_image(url: str, output_path: str, source: str = "unsplash") -> str:
    """Download an image from URL with proper attribution headers."""
    # Validate output path is within expected directories
    abs_path = os.path.abspath(output_path)
    parent = os.path.dirname(abs_path)
    os.makedirs(parent, exist_ok=True)

    headers = {
        "User-Agent": "Drift-iOS-Companion/0.2 (design-compliance-tool)",
    }

    # Add auth headers for API download URLs
    if "unsplash.com" in url and CREDS.get("unsplash"):
        headers["Authorization"] = f"Client-ID {CREDS['unsplash']}"
    elif "pexels.com" in url and CREDS.get("pexels"):
        headers["Authorization"] = CREDS["pexels"]

    req = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            data = response.read()
            with open(output_path, 'wb') as f:
                f.write(data)
            size_mb = len(data) / (1024 * 1024)
            print(f"Downloaded {size_mb:.1f}MB to {output_path}")
            return output_path
    except Exception as e:
        print(f"Download failed: {e}")
        return ""


# ─── Xcode Asset Catalog Export ──────────────────────────────────────

def export_to_xcassets(
    image_path: str,
    xcassets_dir: str,
    asset_name: str,
    preset: str = None,
    effects: list = None,
):
    """Process an image and export to Xcode asset catalog."""
    img = Image.open(image_path)
    if img.mode not in ('RGB', 'RGBA'):
        img = img.convert('RGB')
    print(f"Loaded {image_path} ({img.size[0]}x{img.size[1]})")

    steps = []
    if preset and preset in PRESETS:
        steps.extend(PRESETS[preset])
        print(f"Applying preset: {preset}")
    if effects:
        for e in effects:
            if isinstance(e, dict):
                name = e.get("name", "")
                params = {k: v for k, v in e.items() if k != "name"}
                steps.append((name, params))
            elif isinstance(e, str) and e in EFFECTS:
                steps.append((e, {}))

    if steps:
        img = apply_pipeline(img, steps)

    imageset_dir = os.path.join(xcassets_dir, f"{asset_name}.imageset")
    export_for_ios(img, imageset_dir, asset_name)
    print(f"Exported to {imageset_dir}")
    return imageset_dir


# ─── Attribution ─────────────────────────────────────────────────────

def save_attribution(output_dir: str, photos: list):
    """Save attribution info for used photos (good practice for free licenses)."""
    attr_path = os.path.join(output_dir, "PHOTO_CREDITS.md")
    lines = ["# Photo Credits\n", "Photos used under free licenses.\n"]
    for p in photos:
        attribution = p.get("attribution", f"Photo from {p.get('source', 'unknown')}")
        url = p.get("photographer_url", "")
        lines.append(f"- {attribution}")
        if url:
            lines.append(f"  {url}")
        lines.append("")
    with open(attr_path, 'w') as f:
        f.write("\n".join(lines))
    print(f"Attribution saved to {attr_path}")


# ─── CLI ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Drift Stock Photo Sourcer")
    parser.add_argument("--unsplash-key", help="Unsplash Access Key (overrides env/config)")
    parser.add_argument("--pexels-key", help="Pexels API Key (overrides env/config)")

    sub = parser.add_subparsers(dest="command")

    # Search
    search_p = sub.add_parser("search", help="Search for stock photos")
    search_p.add_argument("query", help="Search query")
    search_p.add_argument("--source", choices=["unsplash", "pexels", "all"], default="all")
    search_p.add_argument("--count", type=int, default=5)
    search_p.add_argument("--orientation", choices=["portrait", "landscape"], default="portrait")

    # Download
    dl_p = sub.add_parser("download", help="Download a photo")
    dl_p.add_argument("url", help="Image URL")
    dl_p.add_argument("--output", required=True, help="Output path")

    # Export
    export_p = sub.add_parser("export", help="Process and export to Xcode assets")
    export_p.add_argument("image", help="Input image path")
    export_p.add_argument("--xcassets", required=True, help="Path to .xcassets directory")
    export_p.add_argument("--name", required=True, help="Asset name")
    export_p.add_argument("--preset", help="Effect preset name")

    # Pipeline
    pipe_p = sub.add_parser("pipeline", help="Search → Download → Process → Export")
    pipe_p.add_argument("query", help="Search query")
    pipe_p.add_argument("--xcassets", required=True, help="Path to .xcassets directory")
    pipe_p.add_argument("--name", required=True, help="Asset name")
    pipe_p.add_argument("--preset", default="hero", help="Effect preset")
    pipe_p.add_argument("--orientation", choices=["portrait", "landscape"], default="portrait")
    pipe_p.add_argument("--source", choices=["unsplash", "pexels"], default="unsplash")

    # Status
    sub.add_parser("status", help="Check API key status")

    args = parser.parse_args()

    # Override credentials from CLI
    if hasattr(args, 'unsplash_key') and args.unsplash_key:
        CREDS["unsplash"] = args.unsplash_key
    if hasattr(args, 'pexels_key') and args.pexels_key:
        CREDS["pexels"] = args.pexels_key

    if args.command == "status":
        print("API Key Status:")
        print(f"  Unsplash: {'✓ configured' if CREDS.get('unsplash') else '✗ not set'}")
        print(f"  Pexels:   {'✓ configured' if CREDS.get('pexels') else '✗ not set'}")
        print(f"  Figma:    {'✓ configured' if CREDS.get('figma') else '✗ not set'}")
        print()
        if not any(CREDS.values()):
            print("Configure keys in DriftBar settings or set environment variables:")
            print("  export UNSPLASH_ACCESS_KEY=your_key")
            print("  export PEXELS_API_KEY=your_key")

    elif args.command == "search":
        results = []
        if args.source in ("unsplash", "all"):
            results.extend(search_unsplash(args.query, args.count, args.orientation))
        if args.source in ("pexels", "all"):
            results.extend(search_pexels(args.query, args.count, args.orientation))

        if not results:
            print("No results found. Check your API keys with: python3 stock_photos.py status")
        else:
            print(json.dumps(results, indent=2))
            print(f"\n{len(results)} results found.")

    elif args.command == "download":
        download_image(args.url, args.output)

    elif args.command == "export":
        export_to_xcassets(args.image, args.xcassets, args.name, preset=args.preset)

    elif args.command == "pipeline":
        # Search
        if args.source == "pexels":
            photos = search_pexels(args.query, count=3, orientation=args.orientation)
        else:
            photos = search_unsplash(args.query, count=3, orientation=args.orientation)

        if not photos:
            print("No photos found. Check API keys with: python3 stock_photos.py status")
            return

        # Pick the best result (first one)
        photo = photos[0]
        url = photo.get("url_regular") or photo.get("url_full", "")
        if not url:
            print("No download URL available.")
            return

        print(f"Selected: {photo.get('description', 'No description')}")
        if photo.get("attribution"):
            print(f"Credit: {photo['attribution']}")

        # Download
        tmp_path = os.path.join(tempfile.gettempdir(), f"drift_asset_{args.name}.jpg")
        result = download_image(url, tmp_path, source=args.source)
        if not result:
            return

        # Process and export
        export_to_xcassets(tmp_path, args.xcassets, args.name, preset=args.preset)

        # Save attribution
        save_attribution(os.path.dirname(args.xcassets), [photo])

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
