# voicesewa_worker

Multilingual Voice-Assisted Job Connection Platform for Blue-Collar Services (Worker-Side)

# FlutterFire CLI Setup and Usage

## Installation

### Prerequisites: Firebase CLI

1. **Install Node.js** (via `nvm` recommended).

2. **Install Firebase CLI** globally:

   ```bash
   npm install -g firebase-tools
   ```

3. **Log in to Firebase**:

   ```bash
   firebase login
   ```

4. **Verify Firebase Projects**:

   ```bash
   firebase projects:list
   ```

### Install FlutterFire CLI

**Install the FlutterFire CLI globally:**

```bash
dart pub global activate flutterfire_cli
```

---

## Usage

**Configure Firebase for Your Project:**

   Run in your project root:

   ```bash
   flutterfire configure
   ```

   Follow the prompts to select your Firebase project, platforms, and apps. This generates `firebase_options.dart` with the required config for initializing Firebase.
