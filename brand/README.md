# PriceCheck — Brand assets & Flutter integration

Everything the app needs to replace the default Flutter icon, splash, and in-app
Material placeholder with the **PriceCheck** brand: a price-tag-with-checkmark mark
in the app's emerald (`#1f7a52`).

> The mark deliberately echoes the `Icons.sell_outlined` tag already used in
> `kiosk_bar.dart` — same idea, now an ownable logo with a checkmark for "Check".

---

## What's in this folder

```
brand/
├─ appicon/appicon_master_1024.png        ← MASTER. 1024², opaque, square (OS masks corners)
├─ android/
│  ├─ ic_launcher_foreground.png          ← adaptive foreground, transparent, ~25% safe padding
│  └─ ic_launcher_background.png          ← adaptive background (emerald gradient)
├─ splash/
│  ├─ splash_logo_light.png               ← emerald mark, for the paper splash bg
│  └─ splash_logo_dark.png                ← white mark, for the dark splash bg
├─ inapp/
│  ├─ mark.png  ·  2.0x/mark.png  ·  3.0x/mark.png   ← rounded mark, PNG fallback for the top bar
├─ svg/
│  ├─ pricecheck-mark.svg                 ← full-colour self-contained mark (rounded square)
│  ├─ pricecheck-glyph-mono.svg           ← single-colour glyph, currentColor-able (use in top bar)
│  └─ product-placeholder.svg             ← branded "no image" placeholder for result_screen.dart
└─ flutter_config/
   ├─ flutter_launcher_icons.yaml
   └─ flutter_native_splash.yaml
```

---

## 1 · App launcher icon  (highest priority)

1. Copy the icon source into the app:
   `assets/brand/appicon/appicon_master_1024.png`
   plus the two `assets/brand/android/ic_launcher_*.png`.
2. Add the dev dependency and the config (merge `flutter_launcher_icons.yaml` into `pubspec.yaml`,
   or keep it as a standalone file):
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   ```
3. Generate:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```
   This regenerates every size in `ios/Runner/Assets.xcassets/AppIcon.appiconset`
   and the Android `mipmap-*` folders (legacy + adaptive). The master is **opaque
   with no alpha** so it passes App Store validation.

## 2 · Splash / launch screen

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.1
```
Copy `assets/brand/splash/*`, merge `flutter_native_splash.yaml`, then:
```bash
dart run flutter_native_splash:create
```
Light = paper `#FAF8F3`, dark = ink `#15211B`, centered mark, `fullscreen: true`
(no status/nav chrome during launch — correct for a kiosk).

## 3 · In-app brand mark  (top bar + idle hero)

Use the **SVG** so it's razor-sharp at any size (the idle-screen hero is large).
```yaml
dependencies:
  flutter_svg: ^2.0.10
```
Replace the black square + `Icons.sell_outlined` in `kiosk_bar.dart` (≈ lines 51–69):
```dart
// top bar — colored, self-contained mark
SvgPicture.asset('assets/brand/svg/pricecheck-mark.svg', width: 42, height: 42)

// …or tint a mono glyph to sit in any container:
SvgPicture.asset(
  'assets/brand/svg/pricecheck-glyph-mono.svg',
  width: 24, height: 24,
  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
)
```
The large idle-screen hero: same `pricecheck-mark.svg` at a big size.
PNG fallback (`assets/brand/inapp/mark.png` with its `2.0x`/`3.0x` variants) is provided
if you'd rather not add `flutter_svg`.

**Product placeholder** (items with no photo, `result_screen.dart`) — swap the generic
`Icons.*` box for the branded tile:
```dart
SvgPicture.asset('assets/brand/svg/product-placeholder.svg', fit: BoxFit.cover)
```

## 4 · Fonts — bundle them for offline reliability

⚠️ I can generate artwork but **not the font files themselves** — they're licensed
`.ttf`s you download once. `google_fonts` fetches them over the network on first run
(`app_theme.dart:67–82`); on an offline/air-gapped kiosk that falls back to system
fonts. Fix: bundle the `.ttf`s and `google_fonts` will prefer the local copies (no
code change needed beyond shipping the files + the pubspec entry).

Get the files (both are open-licensed — SIL OFL):
- **Schibsted Grotesk** — https://fonts.google.com/specimen/Schibsted+Grotesk
- **IBM Plex Mono** — https://fonts.google.com/specimen/IBM+Plex+Mono

Drop them in `assets/fonts/` and register:
```yaml
flutter:
  assets:
    - assets/brand/        # icons, splash, svgs, placeholder
  fonts:
    - family: Schibsted Grotesk
      fonts:
        - { asset: assets/fonts/SchibstedGrotesk-Regular.ttf,    weight: 400 }
        - { asset: assets/fonts/SchibstedGrotesk-Medium.ttf,     weight: 500 }
        - { asset: assets/fonts/SchibstedGrotesk-SemiBold.ttf,   weight: 600 }
        - { asset: assets/fonts/SchibstedGrotesk-Bold.ttf,       weight: 700 }
        - { asset: assets/fonts/SchibstedGrotesk-ExtraBold.ttf,  weight: 800 }
    - family: IBM Plex Mono
      fonts:
        - { asset: assets/fonts/IBMPlexMono-Regular.ttf,  weight: 400 }
        - { asset: assets/fonts/IBMPlexMono-Medium.ttf,   weight: 500 }
        - { asset: assets/fonts/IBMPlexMono-SemiBold.ttf, weight: 600 }
```
`google_fonts` automatically uses a bundled family of the same name, so
`GoogleFonts.schibstedGrotesk()` / `.ibmPlexMono()` keep working — just offline-safe.
(If you'd rather drop `google_fonts` entirely, set `fontFamily: 'Schibsted Grotesk'`
in `ThemeData` and reference families directly.)

---

## Brand reference
| Token | Value |
|---|---|
| Emerald (accent / mark) | `#1f7a52` (gradient `#2a9065 → #176343`) |
| Paper (light bg / splash) | `#FAF8F3` |
| Ink (dark bg / splash) | `#15211B` |
| Mark | Price tag + checkmark, ~60% optical size, rounded-square lockup radius 22% |

Open `brand_sheet.html` for a visual contact sheet of every asset.
