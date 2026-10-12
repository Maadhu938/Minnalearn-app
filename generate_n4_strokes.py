import urllib.request
import re
import json
import xml.etree.ElementTree as ET
import math
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

n4_characters = list(dict.fromkeys(list(
    '験試貸借終始開閉集別思知引押落拾止歩走起持待送使作考教習勉強研究音楽歌画写真旅世界特急便利不親切好意味理飯肉鳥牛物語朝昼夜夕方洗運動転通降着去院館堂屋場室工質問題答宿顔頭心病薬死医者体声配番号員都市町'
)))

print(f"Total N4 Characters to process: {len(n4_characters)}")

def parse_svg_path_to_points(d_str):
    # Regex to extract commands and coordinate tokens
    # e.g. M16.49,17.62 c0.76,0.76,1.25,1.82,1.24,3.38
    tokens = re.findall(r'([a-df-z]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)', d_str, re.IGNORECASE)
    
    commands = []
    i = 0
    current_cmd = ''
    while i < len(tokens):
        t = tokens[i]
        if t.isalpha():
            current_cmd = t
            i += 1
        else:
            # Number belonging to current command
            nums = []
            while i < len(tokens) and not tokens[i].isalpha():
                nums.append(float(tokens[i]))
                i += 1
            commands.append((current_cmd, nums))

    cur_x, cur_y = 0.0, 0.0
    start_x, start_y = 0.0, 0.0
    points = []

    for cmd, nums in commands:
        if cmd == 'M':
            cur_x, cur_y = nums[0], nums[1]
            start_x, start_y = cur_x, cur_y
            points.append((cur_x, cur_y))
        elif cmd == 'm':
            cur_x += nums[0]
            cur_y += nums[1]
            start_x, start_y = cur_x, cur_y
            points.append((cur_x, cur_y))
        elif cmd == 'C':
            # Absolute cubic bezier: x1, y1, x2, y2, x, y
            for k in range(0, len(nums), 6):
                p0 = (cur_x, cur_y)
                p1 = (nums[k], nums[k+1])
                p2 = (nums[k+2], nums[k+3])
                p3 = (nums[k+4], nums[k+5])
                # Sample 4 points along curve
                for step in [0.25, 0.5, 0.75, 1.0]:
                    t = step
                    bx = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
                    by = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
                    points.append((bx, by))
                cur_x, cur_y = p3[0], p3[1]
        elif cmd == 'c':
            # Relative cubic bezier
            for k in range(0, len(nums), 6):
                p0 = (cur_x, cur_y)
                p1 = (cur_x + nums[k], cur_y + nums[k+1])
                p2 = (cur_x + nums[k+2], cur_y + nums[k+3])
                p3 = (cur_x + nums[k+4], cur_y + nums[k+5])
                for step in [0.25, 0.5, 0.75, 1.0]:
                    t = step
                    bx = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
                    by = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
                    points.append((bx, by))
                cur_x, cur_y = p3[0], p3[1]
        elif cmd == 'S':
            for k in range(0, len(nums), 4):
                p0 = (cur_x, cur_y)
                p2 = (nums[k], nums[k+1])
                p3 = (nums[k+2], nums[k+3])
                p1 = (cur_x, cur_y) # Approximate reflection
                for step in [0.33, 0.66, 1.0]:
                    t = step
                    bx = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
                    by = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
                    points.append((bx, by))
                cur_x, cur_y = p3[0], p3[1]
        elif cmd == 's':
            for k in range(0, len(nums), 4):
                p0 = (cur_x, cur_y)
                p2 = (cur_x + nums[k], cur_y + nums[k+1])
                p3 = (cur_x + nums[k+2], cur_y + nums[k+3])
                p1 = (cur_x, cur_y)
                for step in [0.33, 0.66, 1.0]:
                    t = step
                    bx = (1-t)**3 * p0[0] + 3*(1-t)**2*t * p1[0] + 3*(1-t)*t**2 * p2[0] + t**3 * p3[0]
                    by = (1-t)**3 * p0[1] + 3*(1-t)**2*t * p1[1] + 3*(1-t)*t**2 * p2[1] + t**3 * p3[1]
                    points.append((bx, by))
                cur_x, cur_y = p3[0], p3[1]
        elif cmd == 'L':
            for k in range(0, len(nums), 2):
                cur_x, cur_y = nums[k], nums[k+1]
                points.append((cur_x, cur_y))
        elif cmd == 'l':
            for k in range(0, len(nums), 2):
                cur_x += nums[k]
                cur_y += nums[k+1]
                points.append((cur_x, cur_y))
        elif cmd == 'H':
            for x in nums:
                cur_x = x
                points.append((cur_x, cur_y))
        elif cmd == 'h':
            for dx in nums:
                cur_x += dx
                points.append((cur_x, cur_y))
        elif cmd == 'V':
            for y in nums:
                cur_y = y
                points.append((cur_x, cur_y))
        elif cmd == 'v':
            for dy in nums:
                cur_y += dy
                points.append((cur_x, cur_y))

    # Reduce points count to maximum 8 points to keep smooth performance
    if len(points) > 8:
        indices = [int(i * (len(points)-1) / 6.0) for i in range(7)]
        points = [points[idx] for idx in indices]

    # Normalize by 109.0
    normalized = [(round(p[0] / 109.0, 3), round(p[1] / 109.0, 3)) for p in points]
    return normalized

def determine_description(pts):
    if len(pts) < 2:
        return 'Stroke'
    p_start = pts[0]
    p_end = pts[-1]
    dx = p_end[0] - p_start[0]
    dy = p_end[1] - p_start[1]
    if len(pts) >= 3:
        p_mid = pts[len(pts)//2]
        idx = p_mid[0] - p_start[0]
        idy = p_mid[1] - p_start[1]
        fdx = p_end[0] - p_mid[0]
        fdy = p_end[1] - p_mid[1]
        if idx > 0.12 and abs(idy) < idx * 0.75 and fdy > 0.12:
            return 'Horizontal then Down (折)'
        if idy > 0.12 and abs(idx) < idy * 0.75 and fdx > 0.10:
            return 'Vertical bend right (乚)'
        if idx < -0.08 and idy > 0.08 and fdx > 0.08:
            return 'Slant down-left then turn (ㄑ)'
        if idy > 0.20 and fdy < -0.03 and abs(fdx) < 0.12:
            return 'Vertical with Hook (亅)'
    if abs(dy) < 0.08:
        return 'Horizontal (Left → Right)'
    if abs(dx) < 0.08 and dy > 0:
        return 'Vertical (Top → Bottom)'
    if dx < 0 and dy > 0:
        return 'Slant down-left (撇)'
    if dx > 0 and dy > 0:
        return 'Slant down-right (捺)'
    return 'Stroke'

results = {}

for char in n4_characters:
    hex_code = format(ord(char), '05x')
    url = f'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/{hex_code}.svg'
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        content = urllib.request.urlopen(req, timeout=10).read().decode('utf-8')
        root = ET.fromstring(content)
        
        paths = root.findall('.//{http://www.w3.org/2000/svg}path')
        texts = root.findall('.//{http://www.w3.org/2000/svg}text')
        
        strokes = []
        for i, p in enumerate(paths):
            d = p.attrib.get('d', '')
            pts = parse_svg_path_to_points(d)
            if not pts:
                continue
            
            # Number position from text transform matrix(1 0 0 1 x y)
            num_pos = (round(pts[0][0] - 0.05, 3), round(pts[0][1] - 0.02, 3))
            if i < len(texts):
                t_tr = texts[i].attrib.get('transform', '')
                m = re.search(r'matrix\(\s*1\s+0\s+0\s+1\s+([\d.-]+)\s+([\d.-]+)\s*\)', t_tr)
                if m:
                    num_pos = (round(float(m.group(1)) / 109.0, 3), round(float(m.group(2)) / 109.0, 3))
            
            desc = determine_description(pts)
            strokes.append({
                'order': i + 1,
                'start': pts[0],
                'end': pts[-1],
                'points': pts,
                'numberPosition': num_pos,
                'description': desc
            })
            
        results[char] = {
            'character': char,
            'strokeCount': len(strokes),
            'strokes': strokes
        }
        print(f"Loaded char #{len(results)}: {char} ({len(strokes)} strokes)")
    except Exception as e:
        print(f"Failed {char}: {e}")

# Save JSON intermediate
with open('n4_strokes.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"Successfully processed {len(results)} Kanji characters! Generating Dart file...")

dart_lines = [
    "import 'package:flutter/material.dart';",
    "import 'kanji_stroke_dictionary.dart';",
    "",
    "/// Authentic stroke order dataset for JLPT N4 Kanji characters.",
    "/// Parsed from KanjiVG open calligraphy specifications.",
    "class N4KanjiStrokeData {",
    "  static final Map<String, KanjiStrokeData> database = {",
]

for char, data in results.items():
    dart_lines.append(f"    '{char}': const KanjiStrokeData(")
    dart_lines.append(f"      character: '{char}',")
    dart_lines.append(f"      strokeCount: {data['strokeCount']},")
    dart_lines.append("      strokeOrderTip: 'Follow standard stroke order: top to bottom, left to right.',")
    dart_lines.append("      strokes: [")
    for s in data['strokes']:
        start = f"Offset({s['start'][0]}, {s['start'][1]})"
        end = f"Offset({s['end'][0]}, {s['end'][1]})"
        pts = ", ".join(f"Offset({p[0]}, {p[1]})" for p in s['points'])
        num_pos = f"Offset({s['numberPosition'][0]}, {s['numberPosition'][1]})"
        desc = s['description'].replace("'", "\\'")
        dart_lines.append("        KanjiStroke(")
        dart_lines.append(f"          order: {s['order']},")
        dart_lines.append(f"          start: {start},")
        dart_lines.append(f"          end: {end},")
        dart_lines.append(f"          points: [{pts}],")
        dart_lines.append(f"          numberPosition: {num_pos},")
        dart_lines.append(f"          description: '{desc}',")
        dart_lines.append("        ),")
    dart_lines.append("      ],")
    dart_lines.append("    ),")
    dart_lines.append("")

dart_lines.append("  };")
dart_lines.append("}")
dart_lines.append("")

output_path = 'flutter_minnalearn/lib/data/n4_kanji_stroke_data.dart'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(dart_lines))

print(f"Wrote N4 stroke data to {output_path} successfully!")

