# frontend_scaffold demo gallery

A runnable gallery for the [`frontend_scaffold`](../) widget library. Each
screen exercises one widget family against the real theme extensions, so it
doubles as a visual check when changing a widget or a design token.

## Run

```bash
cd example
flutter pub get
flutter run -d macos     # or: -d chrome
```

Committed platform scaffolding covers **macOS and web** only. For any other
target, run `flutter create --platforms=<platform> .` first.

The app depends on the parent package by relative path (`path: ../` in
`pubspec.yaml`), so it always builds the working-tree version of `lib/` — no
reinstall needed after editing a widget.

## What's in it

The home screen lists every demo, plus two live controls at the top for
toggling **theme overrides** and **light/dark mode** — useful for confirming a
widget reads its tokens from `Theme.of(context)` rather than hardcoding values.

| Demo | Covers |
|---|---|
| `action_button_demo` | `ActionButton` |
| `string_button_demo` | `StringButton` |
| `text_entry_field_demo` | `TextEntryFieldWidget` |
| `media_card_demo` | `MediaCard` |
| `media_controls_demo` | `MediaControls`, `ScaffoldSlider` |
| `responsive_grid_demo` | `ResponsiveGrid`, breakpoints |
| `page_chrome_demo` | `AppScreenView`, `DesktopBodyContainer` |
| `bottom_drawer_demo` | Bottom drawer + `SlidingDrawerButton` |
| `wallet_connect_sheet_demo` | `WalletConnectSheet` |
| `animations_demo` | `ScaffoldAnimatedDisplay*`, `ScaffoldMotion` |
| `loading_demo` | `Loading` |
| `toast_demo` | `showToast` and the toast stack |
| `tracer_demo` | Tracer animation |
| `kitchen_sink_demo` | Many atoms on one screen |

## Note

This package is `publish_to: 'none'` and is not part of the published surface —
it exists for manual verification. Automated coverage lives in the parent's
`test/` directory (214 tests); the example app itself has no test suite.
