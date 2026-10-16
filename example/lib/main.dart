import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';
import 'package:frontend_scaffold/theme/presets/midnight_theme.dart';

import 'demos/action_button_demo.dart';
import 'demos/animations_demo.dart';
import 'demos/bottom_drawer_demo.dart';
import 'demos/chart_demo.dart';
import 'demos/chart_range_selector_demo.dart';
import 'demos/chart_scrubber_demo.dart';
import 'demos/code_block_demo.dart';
import 'demos/light_syntax_tokenizer_demo.dart';
import 'demos/loading_demo.dart';
import 'demos/markdown_to_spans_demo.dart';
import 'demos/media_card_demo.dart';
import 'demos/media_controls_demo.dart';
import 'demos/page_chrome_demo.dart';
import 'demos/responsive_grid_demo.dart';
import 'demos/selection_actions_demo.dart';
import 'demos/streaming_rich_text_demo.dart';
import 'demos/string_button_demo.dart';
import 'demos/text_entry_field_demo.dart';
import 'demos/toast_demo.dart';
import 'demos/tracer_demo.dart';
import 'demos/wallet_connect_sheet_demo.dart';
import 'demos/kitchen_sink_demo.dart';
import 'demos/chip_demo.dart';
import 'demos/composer_demo.dart';
import 'demos/disclosure_demo.dart';
import 'demos/trace_list_demo.dart';

void main() {
  runApp(const ScaffoldExampleApp());
}

/// Demo app for the `frontend_scaffold` widget library.
///
/// Registers [scaffoldThemeExtensions] on both light and dark themes. The
/// "Theme overrides" toggle on the home page rebuilds the app with an
/// overridden [ScaffoldPalette] to demonstrate the ThemeExtension path. The
/// "Midnight preset" toggle swaps the defaults for the opt-in `midnightTheme`
/// preset, in either brightness, and composes with the other two toggles.
class ScaffoldExampleApp extends StatefulWidget {
  const ScaffoldExampleApp({super.key});

  @override
  State<ScaffoldExampleApp> createState() => _ScaffoldExampleAppState();
}

class _ScaffoldExampleAppState extends State<ScaffoldExampleApp> {
  bool _useOverridePalette = false;
  bool _useLightTheme = false;
  bool _useMidnight = false;

  /// Brightness mode currently in effect — dark by default, light when the
  /// "Light mode" toggle is on. Exposed so both themes are inspectable.
  ThemeMode get _themeMode => _useLightTheme ? ThemeMode.light : ThemeMode.dark;

  /// The palette for the given [brightness] — light-mode uses
  /// [ScaffoldPalette.lightPalette], dark-mode uses [ScaffoldPalette.defaultPalette].
  /// The orange "Theme overrides" swap is applied on top of whichever base.
  ScaffoldPalette _paletteFor(Brightness brightness) {
    final ScaffoldPalette base = brightness == Brightness.light
        ? ScaffoldPalette.lightPalette
        : ScaffoldPalette.defaultPalette;
    return _applyOverride(base);
  }

  /// The orange "Theme overrides" swap, shared by the default and midnight
  /// paths. Returns [base] unchanged when the toggle is off.
  ScaffoldPalette _applyOverride(ScaffoldPalette base) {
    if (!_useOverridePalette) {
      return base;
    }
    return base.copyWith(
      lightGreenPrimary: Colors.orange,
      lightGreenSecondary: Colors.deepOrange,
      blue500: Colors.orangeAccent,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    if (_useMidnight) {
      return _buildMidnightTheme(brightness);
    }
    final ScaffoldPalette palette = _paletteFor(brightness);
    // Align the ColorScheme's onX slots with the palette's text colors so
    // M3 composites (SwitchListTile, ListTile, ElevatedButton text, etc.)
    // resolve palette.textPrimary/textSecondary instead of fromSeed's
    // brightness-derived onSurface (#DEE4DF on dark), which reads as dim
    // grey against the palette's near-black surface.
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: palette.lightGreenPrimary,
      brightness: brightness,
    ).copyWith(
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        palette,
        ScaffoldDimens.defaultDimens,
      ],
    );
  }

  /// The midnight preset for [brightness]. With "Theme overrides" on, the
  /// registered [ScaffoldPalette] is replaced by its orange copy and every
  /// other extension is kept.
  ThemeData _buildMidnightTheme(Brightness brightness) {
    final ThemeData theme = midnightTheme(brightness);
    if (!_useOverridePalette) {
      return theme;
    }
    return theme.copyWith(
      extensions: [
        for (final extension in theme.extensions.values)
          if (extension is ScaffoldPalette)
            _applyOverride(extension)
          else
            extension,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'frontend_scaffold demo',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: HomePage(
        overrideEnabled: _useOverridePalette,
        onOverrideChanged: (value) {
          setState(() => _useOverridePalette = value);
        },
        lightTheme: _useLightTheme,
        onLightThemeChanged: (value) {
          setState(() => _useLightTheme = value);
        },
        midnight: _useMidnight,
        onMidnightChanged: (value) {
          setState(() => _useMidnight = value);
        },
      ),
    );
  }
}

/// Menu page listing all widget demos.
class HomePage extends StatelessWidget {
  final bool overrideEnabled;
  final ValueChanged<bool> onOverrideChanged;
  final bool lightTheme;
  final ValueChanged<bool> onLightThemeChanged;
  final bool midnight;
  final ValueChanged<bool> onMidnightChanged;

  const HomePage({
    super.key,
    required this.overrideEnabled,
    required this.onOverrideChanged,
    required this.lightTheme,
    required this.onLightThemeChanged,
    required this.midnight,
    required this.onMidnightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('frontend_scaffold demos')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Theme overrides'),
            subtitle: const Text(
              'Swap lightGreenPrimary/lightGreenSecondary to orange via '
              'ScaffoldPalette.copyWith — demonstrates ThemeExtension override',
            ),
            value: overrideEnabled,
            onChanged: onOverrideChanged,
          ),
          SwitchListTile(
            title: const Text('Light mode'),
            subtitle: const Text(
              'Toggle between the dark and light ThemeData (see both '
              'backgrounds/surfaces)',
            ),
            value: lightTheme,
            onChanged: onLightThemeChanged,
          ),
          SwitchListTile(
            title: const Text('Midnight preset'),
            subtitle: const Text(
              'Opt-in preset (deep import, one call per brightness); off '
              'shows the defaults',
            ),
            value: midnight,
            onChanged: onMidnightChanged,
          ),
          const Divider(),
          _DemoTile(
            title: 'ActionButton',
            subtitle: 'Enabled, disabled, and rotate-animation states',
            builder: (_) => const ActionButtonDemo(),
          ),
          _DemoTile(
            title: 'StringButton',
            subtitle: 'Keypad-style button that emits its string value',
            builder: (_) => const StringButtonDemo(),
          ),
          _DemoTile(
            title: 'TextEntryFieldWidget',
            subtitle: 'TextFormField driven by TextFormFieldLogic',
            builder: (_) => const TextEntryFieldDemo(),
          ),
          _DemoTile(
            title: 'Loading',
            subtitle: 'Flickr two-dot loading indicator',
            builder: (_) => const LoadingDemo(),
          ),
          _DemoTile(
            title: 'Toast',
            subtitle: 'ToastManager — every ToastType + onClose counter',
            builder: (_) => const ToastDemo(),
          ),
          _DemoTile(
            title: 'BottomDrawer / ResponsiveDrawer',
            subtitle: 'Modal bottom sheet / right-side dialog',
            builder: (_) => const BottomDrawerDemo(),
          ),
          _DemoTile(
            title: 'Animations',
            subtitle: 'CheckmarkAnimation + XAnimation',
            builder: (_) => const AnimationsDemo(),
          ),
          _DemoTile(
            title: 'AppScreenView / DesktopBodyContainer',
            subtitle: 'Page chrome primitives',
            builder: (_) => const PageChromeDemo(),
          ),
          _DemoTile(
            title: 'ResponsiveGrid',
            subtitle: 'Column count adapts to width / breakpoints',
            builder: (_) => const ResponsiveGridDemo(),
          ),
          _DemoTile(
            title: 'Tracer — Core UI Foundation',
            subtitle: 'Motion → Surface → TouchTarget → FocusOutline slice',
            builder: (_) => const TracerDemo(),
          ),
          _DemoTile(
            title: 'Kitchen Sink — Core UI Foundation',
            subtitle: 'All 28 atoms + ScaffoldMotion + 3 generated composites',
            builder: (_) => const KitchenSinkDemo(),
          ),
          _DemoTile(
            title: 'Media card',
            subtitle: 'Aspect ratios, typed badge slots, metadataRow',
            builder: (_) => const MediaCardDemo(),
          ),
          _DemoTile(
            title: 'Media controls',
            subtitle: 'Play/pause, seekbar with buffered, mute, fullscreen',
            builder: (_) => const MediaControlsDemo(),
          ),
          _DemoTile(
            title: 'Wallet connect sheet',
            subtitle: 'Reown session sheet — disconnected + connected states',
            builder: (_) => const WalletConnectSheetDemo(),
          ),
          _DemoTile(
            title: 'Chip / ChipGroup',
            subtitle: 'Pill pressable atom + selection group',
            builder: (_) => const ScaffoldChipDemo(),
          ),
          _DemoTile(
            title: 'Composer',
            subtitle: 'Text composition area with badge/action slots',
            builder: (_) => const ScaffoldComposerDemo(),
          ),
          _DemoTile(
            title: 'Disclosure',
            subtitle: 'Expand/collapse row with AnimatedSize + reduced-motion',
            builder: (_) => const ScaffoldDisclosureDemo(),
          ),
          _DemoTile(
            title: 'Trace list',
            subtitle: 'Ordered disclosure items + optional group header',
            builder: (_) => const ScaffoldTraceListDemo(),
          ),
          _DemoTile(
            title: 'Streaming rich text',
            subtitle: 'Incremental typed-span rendering + citations + action slots',
            builder: (_) => const ScaffoldStreamingRichTextDemo(),
          ),
          _DemoTile(
            title: 'Code block',
            subtitle: 'Syntax-highlighted code + line numbers + copy + streamed lines',
            builder: (_) => const ScaffoldCodeBlockDemo(),
          ),
          _DemoTile(
            title: 'Selection actions',
            subtitle: 'Anchored toolbar on text selection (consumer-built actions)',
            builder: (_) => const ScaffoldSelectionActionsDemo(),
          ),
          _DemoTile(
            title: 'Markdown to spans',
            subtitle: 'Markdown parser -> typed-span mapper (D-03 support part)',
            builder: (_) => const ScaffoldMarkdownToSpansDemo(),
          ),
          _DemoTile(
            title: 'Light syntax tokenizer',
            subtitle: 'Regex-based syntax highlighting (D-04 support part)',
            builder: (_) => const ScaffoldLightSyntaxTokenizerDemo(),
          ),
          _DemoTile(
            title: 'Chart',
            subtitle: 'Framed + axis-free + formatter + empty state',
            builder: (_) => const ChartDemo(),
          ),
          _DemoTile(
            title: 'Chart Scrubber',
            subtitle: 'Scrub selection + keyboard + PointerExit + live region',
            builder: (_) => const ChartScrubberDemo(),
          ),
          _DemoTile(
            title: 'Chart Range Selector',
            subtitle: 'Drag-range selection + consumer-policy zoom (D-09/D-10)',
            builder: (_) => const ChartRangeSelectorDemo(),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: builder),
      ),
    );
  }
}
