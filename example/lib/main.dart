import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

import 'demos/action_button_demo.dart';
import 'demos/animations_demo.dart';
import 'demos/bottom_drawer_demo.dart';
import 'demos/loading_demo.dart';
import 'demos/page_chrome_demo.dart';
import 'demos/responsive_grid_demo.dart';
import 'demos/string_button_demo.dart';
import 'demos/text_entry_field_demo.dart';
import 'demos/toast_demo.dart';
import 'demos/tracer_demo.dart';
import 'demos/kitchen_sink_demo.dart';

void main() {
  runApp(const ScaffoldExampleApp());
}

/// Demo app for the `frontend_scaffold` widget library.
///
/// Registers [scaffoldThemeExtensions] on both light and dark themes. The
/// "Theme overrides" toggle on the home page rebuilds the app with an
/// overridden [ScaffoldPalette] to demonstrate the ThemeExtension path.
class ScaffoldExampleApp extends StatefulWidget {
  const ScaffoldExampleApp({super.key});

  @override
  State<ScaffoldExampleApp> createState() => _ScaffoldExampleAppState();
}

class _ScaffoldExampleAppState extends State<ScaffoldExampleApp> {
  bool _useOverridePalette = false;
  bool _useLightTheme = false;

  /// Brightness mode currently in effect — dark by default, light when the
  /// "Light mode" toggle is on. Exposed so both themes are inspectable.
  ThemeMode get _themeMode => _useLightTheme ? ThemeMode.light : ThemeMode.dark;

  /// The palette currently in effect — the default, or an orange override
  /// when "Theme overrides" is toggled on.
  ScaffoldPalette get _activePalette {
    if (!_useOverridePalette) {
      return ScaffoldPalette.defaultPalette;
    }
    return ScaffoldPalette.defaultPalette.copyWith(
      lightGreenPrimary: Colors.orange,
      lightGreenSecondary: Colors.deepOrange,
      blue500: Colors.orangeAccent,
    );
  }

  List<ThemeExtension<dynamic>> get _extensions => <ThemeExtension<dynamic>>[
        _activePalette,
        ScaffoldDimens.defaultDimens,
      ];

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _activePalette.lightGreenPrimary,
        brightness: brightness,
      ),
      extensions: _extensions,
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

  const HomePage({
    super.key,
    required this.overrideEnabled,
    required this.onOverrideChanged,
    required this.lightTheme,
    required this.onLightThemeChanged,
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
