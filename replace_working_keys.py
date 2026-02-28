"""
replace_working_keys.py

Replaces all context.loc.keyName calls (where keyName EXISTS in app_en.arb)
with the actual hardcoded string value from the ARB.

Example:
    Text(context.loc.accept)  -->  Text("Accept")

Usage:
    python replace_working_keys.py

Place this in your Flutter project root (same level as pubspec.yaml).

⚠️  A backup of every modified file is saved as filename.dart.bak
    before any changes are made.
"""

import json
import os
import re
import shutil

# ── Config ────────────────────────────────────────────────────────────────────
ARB_PATH    = "lib/l10n/app_en.arb"
LIB_DIR     = "lib"
DRY_RUN     = False   # Set True to preview changes without writing anything
# ─────────────────────────────────────────────────────────────────────────────

# Load ARB
with open(ARB_PATH, encoding="utf-8") as f:
    arb = json.load(f)

valid_keys = {
    k: v for k, v in arb.items()
    if not k.startswith("@") and k != "@@locale"
}
print(f"✅ Loaded {len(valid_keys)} valid keys from {ARB_PATH}")

# Pattern matches context.loc.keyName  (not followed by `(` — those are method calls)
LOC_PATTERN = re.compile(r'context\.loc\.([a-zA-Z_][a-zA-Z0-9_]*)')

total_files_changed = 0
total_replacements  = 0
skipped_keys        = set()

for root, dirs, files in os.walk(LIB_DIR):
    dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'generated']]
    for fname in files:
        if not fname.endswith(".dart"):
            continue

        fpath = os.path.join(root, fname)
        with open(fpath, encoding="utf-8", errors="ignore") as f:
            original = f.read()

        file_replacements = 0

        def replacer(match):
            global file_replacements, total_replacements
            key = match.group(1)

            if key not in valid_keys:
                skipped_keys.add(key)
                return match.group(0)  # leave broken ones untouched

            value = valid_keys[key]

            # Escape any single quotes in the value for Dart string safety
            escaped = value.replace("'", "\\'")
            file_replacements += 1
            total_replacements += 1
            return f"'{escaped}'"

        new_content = LOC_PATTERN.sub(replacer, original)

        if new_content != original and file_replacements > 0:
            total_files_changed += 1
            print(f"  {'[DRY RUN] ' if DRY_RUN else ''}Modified ({file_replacements} replacements): {fpath}")

            if not DRY_RUN:
                # Backup original
                shutil.copy2(fpath, fpath + ".bak")
                with open(fpath, "w", encoding="utf-8") as f:
                    f.write(new_content)

# ── Summary ───────────────────────────────────────────────────────────────────
print(f"\n📊 Summary")
print(f"   Files modified     : {total_files_changed}")
print(f"   Total replacements : {total_replacements}")

if skipped_keys:
    print(f"\n⚠️  Skipped {len(skipped_keys)} broken keys (not in ARB) — left untouched:")
    for k in sorted(skipped_keys):
        print(f"     context.loc.{k}")

if DRY_RUN:
    print("\n⚠️  DRY RUN — no files were changed. Set DRY_RUN = False to apply.")
else:
    print("\n✅ Done! Original files backed up as *.dart.bak")
    print("   To undo all changes run:")
    print("   find lib/ -name '*.dart.bak' | while read f; do mv \"$f\" \"${f%.bak}\"; done")