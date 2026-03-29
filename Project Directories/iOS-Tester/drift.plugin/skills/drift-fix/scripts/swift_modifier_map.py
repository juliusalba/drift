#!/usr/bin/env python3
"""Drift SwiftUI Modifier Map — Maps visual properties to SwiftUI modifiers."""

import json
import re

MODIFIER_MAP = {
    "color": {
        "foreground": '.foregroundColor(Color(hex: "{value}"))',
        "background": '.background(Color(hex: "{value}"))',
        "tint": '.tint(Color(hex: "{value}"))',
        "accent": '.accentColor(Color(hex: "{value}"))',
    },
    "spacing": {
        "padding_all": ".padding({value})",
        "padding_horizontal": ".padding(.horizontal, {value})",
        "padding_vertical": ".padding(.vertical, {value})",
        "padding_top": ".padding(.top, {value})",
        "padding_bottom": ".padding(.bottom, {value})",
        "padding_leading": ".padding(.leading, {value})",
        "padding_trailing": ".padding(.trailing, {value})",
        "stack_spacing": "spacing: {value}",
    },
    "typography": {
        "system_font": ".font(.system(size: {size}, weight: .{weight}))",
        "custom_font": '.font(.custom("{name}", size: {size}))',
        "text_color": '.foregroundColor(Color(hex: "{value}"))',
    },
    "layout": {
        "frame_width": ".frame(width: {value})",
        "frame_height": ".frame(height: {value})",
        "frame_both": ".frame(width: {width}, height: {height})",
        "max_width": ".frame(maxWidth: .infinity)",
        "alignment": "alignment: .{value}",
    },
    "shape": {
        "corner_radius": ".clipShape(RoundedRectangle(cornerRadius: {value}))",
        "circle": ".clipShape(Circle())",
        "border": '.overlay(RoundedRectangle(cornerRadius: {radius}).stroke(Color(hex: "{color}"), lineWidth: {width}))',
    },
    "shadow": {
        "drop_shadow": '.shadow(color: Color(hex: "{color}").opacity({opacity}), radius: {radius}, x: {x}, y: {y})',
    },
    "opacity": {
        "opacity": ".opacity({value})",
    },
}


def get_modifier(category: str, subcategory: str, **kwargs) -> str | None:
    """Get the SwiftUI modifier string for a given visual property."""
    template = MODIFIER_MAP.get(category, {}).get(subcategory)
    if not template:
        return None
    return template.format(**kwargs)


def suggest_fix(discrepancy: dict) -> dict:
    """Suggest a SwiftUI modifier fix for a discrepancy."""
    d_type = discrepancy.get('type', '')
    expected = discrepancy.get('expected', '')

    suggestions = []

    if d_type == 'color':
        for sub in ['foreground', 'background', 'tint']:
            mod = get_modifier('color', sub, value=expected)
            if mod:
                suggestions.append({'modifier': mod, 'subcategory': sub})

    elif d_type == 'spacing':
        match = re.search(r'(\d+)', expected)
        if match:
            val = match.group(1)
            for sub in ['padding_all', 'padding_horizontal', 'padding_vertical']:
                mod = get_modifier('spacing', sub, value=val)
                if mod:
                    suggestions.append({'modifier': mod, 'subcategory': sub})

    elif d_type == 'typography':
        size_match = re.search(r'(\d+)', expected)
        weight_match = re.search(r'(regular|medium|semibold|bold|heavy|light|thin|ultraLight|black)', expected, re.I)
        if size_match:
            size = size_match.group(1)
            weight = weight_match.group(1).lower() if weight_match else 'regular'
            mod = get_modifier('typography', 'system_font', size=size, weight=weight)
            if mod:
                suggestions.append({'modifier': mod, 'subcategory': 'system_font'})

    return {
        'discrepancy': discrepancy,
        'suggestions': suggestions,
        'auto_fixable': len(suggestions) > 0 and discrepancy.get('confidence', 0) >= 0.7,
    }


def main():
    print(json.dumps(MODIFIER_MAP, indent=2))


if __name__ == '__main__':
    main()
