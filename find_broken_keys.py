"""
find_broken_keys.py

Scans all Dart files in your lib/ folder and finds every
context.loc.keyName call where keyName is NOT in your app_en.arb.

Usage:
    python find_broken_keys.py

Make sure this script is in your Flutter project root
(same level as pubspec.yaml), and app_en.arb is at lib/l10n/app_en.arb
"""

import json
import os
import re

# ── Config ────────────────────────────────────────────────────────────────────
ARB_PATH  = "lib/l10n/app_en.arb"
LIB_DIR   = "lib"
OUTPUT    = "broken_keys_report.txt"
# ─────────────────────────────────────────────────────────────────────────────

# Load valid keys from ARB
with open(ARB_PATH, encoding="utf-8") as f:
    arb = json.load(f)

valid_keys = set(k for k in arb if not k.startswith("@") and k != "@@locale")
print(f"✅ Loaded {len(valid_keys)} valid keys from {ARB_PATH}")

# Pattern: context.loc.someKey  OR  AppLocalizations.of(context)!.someKey
# Also catches: context.loc.someKey( for method-style
LOC_PATTERN = re.compile(
    r'context\.loc\.([a-zA-Z_][a-zA-Z0-9_]*)'
)

# Scan all dart files
broken = {}   # key -> list of (file, line_number, line_content)
all_used = set()

for root, dirs, files in os.walk(LIB_DIR):
    # Skip generated files
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'generated']]
    for fname in files:
        if not fname.endswith(".dart"):
            continue
        fpath = os.path.join(root, fname)
        with open(fpath, encoding="utf-8", errors="ignore") as f:
            for lineno, line in enumerate(f, 1):
                matches = LOC_PATTERN.findall(line)
                for key in matches:
                    all_used.add(key)
                    if key not in valid_keys:
                        if key not in broken:
                            broken[key] = []
                        broken[key].append((fpath, lineno, line.strip()))

# ── Report ────────────────────────────────────────────────────────────────────
print(f"\n📊 Summary")
print(f"   Total unique keys used in code : {len(all_used)}")
print(f"   Keys found in ARB              : {len(all_used & valid_keys)}")
print(f"   BROKEN (missing from ARB)      : {len(broken)}")

if not broken:
    print("\n🎉 No broken keys found! Everything matches.")
else:
    print(f"\n❌ {len(broken)} broken keys:\n")
    lines = []
    lines.append(f"BROKEN KEYS REPORT — {len(broken)} missing from app_en.arb\n")
    lines.append("=" * 70 + "\n\n")

    for key in sorted(broken.keys()):
        occurrences = broken[key]
        print(f"  ✗ context.loc.{key}  ({len(occurrences)} occurrence(s))")
        lines.append(f"KEY: context.loc.{key}  [{len(occurrences)} occurrence(s)]\n")
        for fpath, lineno, content in occurrences:
            lines.append(f"  {fpath}:{lineno}\n")
            lines.append(f"    {content}\n")
        lines.append("\n")

    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"\n📄 Full report saved to: {OUTPUT}")
    print(f"\n💡 For each broken key, either:")
    print(f"   1. Add the key + value manually to lib/l10n/app_en.arb")
    print(f"   2. Replace context.loc.keyName with a hardcoded string in your Dart file")