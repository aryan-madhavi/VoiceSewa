# Localization Workflow: Adding New Strings
This guide explains how to add new text to the app and make it available in the Dart code.

## 1. The Workflow Loop

1. **Add Key** → Add the new string to `app_en.arb`.
2. **Translate** → Add the same key to `app_hi.arb`, `app_mr.arb`, etc.
3. **Generate** → Run the terminal command to build Dart code.
4. **Use** → Call the new string in your Flutter widgets.

---

## 2. Step-by-Step Guide

### Step 1: Add to English (The Master File)

Open `lib/l10n/app_en.arb`. Add a new line inside the JSON structure.

* **Key:** Must be camelCase (e.g., `myNewButton`).
* **Value:** The English text.

```json
{
  "existingKey": "Existing Value",
  "myNewButton": "Click Me"  // <--- ADD THIS (Don't forget the comma on the line before!)
}

```

### Step 2: Add Translations

Open the other language files (`app_hi.arb`, `app_mr.arb`, `app_gu.arb`). Add the **exact same key** with the translated value.

**Example (`app_hi.arb`):**

```json
{
  "existingKey": "मौजूदा मूल्य",
  "myNewButton": "यहाँ क्लिक करें" // <--- Hindi Translation
}

```

> **Note:** If you forget to add the key to other languages, the app will still run, but it will fallback to English for that specific text.

### Step 3: Run the Generator

Open your terminal and run the following command. This converts your JSON keys into Dart variables. The code always checks `l10n.yaml` file which redirects to file `l10n_en.arb` and to current directory `l10n`, yaml path `../../l10n.yaml` 

```bash
flutter gen-l10n

```

*If you see no errors, the code generation was successful.*

### Step 4: How to Use in Dart Code

You can now access the string using `context.loc` (if you set up the extension) or the standard method.

**Using with Extension** (Recommended, Extension is already being setup, path `../extension/context_extension.dart`)**:**

```dart
Text(context.loc.myNewButton)

```

**Using the Standard Way** (Without Extension)**:**

```dart
Text(AppLocalizations.of(context)!.myNewButton)

```

---

## 3. Handling Variables (Advanced)

If you need a string like *"Hello, Sankalp"*, where the name changes:

**1. In `app_en.arb`:**

```json
"welcomeUser": "Hello, {userName}",
"@welcomeUser": {
  "placeholders": {
    "userName": {
      "type": "String"
    }
  }
}

```

**2. In `app_hi.arb`:**

```json
"welcomeUser": "नमस्ते, {userName}"

```

**3. In Dart:**

```dart
Text(context.loc.welcomeUser("Sankalp"));

```
