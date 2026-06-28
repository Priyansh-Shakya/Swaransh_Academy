# 🚀 New Project Setup

## 1. Change Flutter package name

Edit `pubspec.yaml`:

```yaml
name: your_project_name
```

Example:

```yaml
name: tokenx
```

Then run:

```bash
flutter pub get
```

---

## 2. Install rename (once per machine)

```bash
dart pub global activate rename
```

---

## 3. Change app display name

```bash
rename setAppName -v "TokenX"
```

Verify:

```bash
rename getAppName
```

---

## 4. Change bundle/package identifier

```bash
rename setBundleId -v com.priyansh.tokenx
```

Verify:

```bash
rename getBundleId
```

---

## 5. Clean & Run

```bash
flutter clean
flutter pub get
flutter run
```
