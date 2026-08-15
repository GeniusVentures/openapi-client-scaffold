// Kitchen-sink demo for the Core UI Foundation (Phase 6).
//
// Renders all 28 widget atoms + ScaffoldMotion + the 3 template-generated
// composites (ScaffoldCard / ScaffoldStateView / ScaffoldSearchBar) in a
// scrollable gallery grouped by wave, with a reduced-motion toggle.
//
// To wire into the example app, add an entry to example/lib/main.dart's
// HomePage list:
//
//   _DemoTile(
//     title: 'Kitchen Sink — Core UI Foundation',
//     subtitle: 'All 28 atoms + ScaffoldMotion + 3 generated composites',
//     builder: (_) => const KitchenSinkDemo(),
//   ),
//
// and `import 'demos/kitchen_sink_demo.dart';` at the top of main.dart.
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/frontend_scaffold.dart';

/// Gallery of every Phase 6 atom and generated composite.
class KitchenSinkDemo extends StatefulWidget {
  const KitchenSinkDemo({super.key});

  @override
  State<KitchenSinkDemo> createState() => _KitchenSinkDemoState();
}

class _KitchenSinkDemoState extends State<KitchenSinkDemo> {
  bool _reducedMotion = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _pressCount = 0;
  num _numericValue = 42;
  int? _selectedSwatch = 0;
  bool _radioValue = false;
  bool? _checkboxValue = false;
  bool _toggleValue = false;
  bool _selectableSelected = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    return Scaffold(
      appBar: AppBar(title: const Text('Core UI Foundation — Kitchen Sink')),
      body: ScaffoldMotion(
        reducedMotion: _reducedMotion,
        child: ListView(
          padding: EdgeInsets.all(dimens.space8),
          children: <Widget>[
            SwitchListTile(
              title: const Text('Reduced motion'),
              subtitle: const Text(
                'Toggles ScaffoldMotion.of(context).reducedMotion for every atom',
              ),
              value: _reducedMotion,
              onChanged: (bool value) =>
                  setState(() => _reducedMotion = value),
            ),

            // -------------------------------------------------------------
            // Wave 0
            // -------------------------------------------------------------
            _waveHeader('Wave 0 — Zero-Dependency Foundations'),
            _section('ScaffoldMotion — durations & curves', _motionInfo()),
            _section(
              'ScaffoldSurface — colored rect',
              ScaffoldSurface(
                color: context.palette.lightGreenPrimary,
                child: const SizedBox(height: 48),
              ),
            ),
            _section(
              'ScaffoldTouchTarget — small icon in 48px box',
              ScaffoldTouchTarget(
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            _section(
              'ScaffoldFocusOutline — text field with focus',
              ScaffoldFocusOutline(
                focusNode: _focusNode,
                child: TextField(
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Tap to focus',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            _section(
              'ScaffoldLiveRegion — screen-reader announcement',
              ScaffoldLiveRegion(
                label: 'Announcement',
                child: Text(
                  'Announcement region',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            _section(
              'ScaffoldOverflowFade — long text',
              const ScaffoldOverflowFade(
                fadeDirection: FadeDirection.right,
                child: SizedBox(
                  width: 220,
                  child: Text(
                    'This is a very long line of text that overflows its '
                    'container and fades at the right edge.',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
            _section(
              'ScaffoldScrollEdgeIndicator — scroll list',
              SizedBox(
                height: 120,
                child: Stack(
                  children: <Widget>[
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: 12,
                      itemBuilder: (BuildContext context, int i) => ListTile(
                        dense: true,
                        title: Text('Scroll row $i'),
                      ),
                    ),
                    ScaffoldScrollEdgeIndicator(
                      scrollController: _scrollController,
                    ),
                  ],
                ),
              ),
            ),
            _section(
              'ScaffoldResponsiveVisibility — breakpoint show/hide',
              const ScaffoldResponsiveVisibility(
                showAt: 760,
                replacement: Text('Narrow viewport (< 760)'),
                child: Text('Visible at width >= 760'),
              ),
            ),
            _section(
              'ScaffoldFormattedValue — number / money / date',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const ScaffoldFormattedValueNumber(value: 1234),
                  const ScaffoldFormattedValueMoney(value: 1234.56),
                  ScaffoldFormattedValueDate(value: DateTime(2026, 8, 11)),
                ],
              ),
            ),
            _section(
              'ScaffoldColorSwatch — 3 colors',
              ScaffoldColorSwatch(
                colors: const <Color>[
                  Color(0xFF00EAAE),
                  Color(0xFF0068EF),
                  Color(0xFFFFC42E),
                ],
                selectedIndex: _selectedSwatch,
                onSelected: (int i) => setState(() => _selectedSwatch = i),
              ),
            ),

            // -------------------------------------------------------------
            // Wave 1
            // -------------------------------------------------------------
            _waveHeader('Wave 1 — Single-Dependency Atoms'),
            _section(
              'ScaffoldSkeleton — animated placeholder',
              const ScaffoldSkeleton(width: 220, height: 24),
            ),
            _section(
              'ScaffoldBadge — dot / count / icon / text',
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ScaffoldBadge(variant: BadgeVariant.dot),
                  ScaffoldBadge(variant: BadgeVariant.count, count: 5),
                  ScaffoldBadge(
                    variant: BadgeVariant.icon,
                    icon: Icons.notifications,
                  ),
                  ScaffoldBadge(variant: BadgeVariant.text, text: 'New'),
                ],
              ),
            ),
            _section(
              'ScaffoldStatusIndicator — 5 colors',
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ScaffoldStatusIndicator(status: StatusVariant.success),
                  ScaffoldStatusIndicator(status: StatusVariant.warning),
                  ScaffoldStatusIndicator(status: StatusVariant.error),
                  ScaffoldStatusIndicator(status: StatusVariant.info),
                  ScaffoldStatusIndicator(status: StatusVariant.neutral),
                ],
              ),
            ),
            _section(
              'ScaffoldSelectionIndicator — radio / checkbox / toggle',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ScaffoldSelectionIndicatorRadio(
                    value: _radioValue,
                    onChanged: (bool v) => setState(() => _radioValue = v),
                  ),
                  ScaffoldSelectionIndicatorCheckbox(
                    value: _checkboxValue,
                    onChanged: (bool? v) => setState(() => _checkboxValue = v),
                  ),
                  ScaffoldSelectionIndicatorToggle(
                    value: _toggleValue,
                    onChanged: (bool v) => setState(() => _toggleValue = v),
                  ),
                ],
              ),
            ),
            _section(
              'ScaffoldImagePlaceholder — loading / failed',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const ScaffoldImagePlaceholderLoading(width: 96, height: 64),
                  ScaffoldImagePlaceholderFailed(
                    width: 96,
                    height: 64,
                    onRetry: () {},
                  ),
                ],
              ),
            ),
            _section(
              'ScaffoldAnimatedDisplay — fade + pulse',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ScaffoldAnimatedDisplayFade(
                    child: _animatedBox(),
                  ),
                  ScaffoldAnimatedDisplayPulse(
                    child: _animatedBox(),
                  ),
                ],
              ),
            ),
            _section(
              'ScaffoldPressable — tap counter',
              ScaffoldPressable(
                onPressed: () => setState(() => _pressCount++),
                child: Text('Tapped $_pressCount times'),
              ),
            ),
            _section(
              'ScaffoldDisabledOverlay — dimmed',
              ScaffoldDisabledOverlay(
                disabled: true,
                child: ScaffoldSurface(
                  padding: EdgeInsets.all(context.dimens.space4),
                  child: const Text('Dimmed content'),
                ),
              ),
            ),
            _section('ScaffoldDragHandle', const ScaffoldDragHandle()),
            _section(
              'ScaffoldResizeHandle — corner',
              const ScaffoldResizeHandle(direction: ResizeDirection.both),
            ),
            _section(
              'ScaffoldNumericInput — 0..100',
              ScaffoldNumericInput(
                value: _numericValue,
                min: 0,
                max: 100,
                onChanged: (num v) => setState(() => _numericValue = v),
              ),
            ),

            // -------------------------------------------------------------
            // Wave 2
            // -------------------------------------------------------------
            _waveHeader('Wave 2 — Multi-Dependency Atoms'),
            _section(
              'ScaffoldSelectableSurface — toggle',
              ScaffoldSelectableSurface(
                selected: _selectableSelected,
                onTap: () =>
                    setState(() => _selectableSelected = !_selectableSelected),
                child: Padding(
                  padding: EdgeInsets.all(context.dimens.space6),
                  child: const Text('Tap to select'),
                ),
              ),
            ),
            _section(
              'ScaffoldDraggable — chip + handle',
              ScaffoldDraggable(
                data: 'draggable-chip',
                dragHandle: true,
                child: ScaffoldSurface(
                  padding: EdgeInsets.all(context.dimens.space4),
                  child: const Text('Long-press to drag'),
                ),
              ),
            ),
            _section(
              'ScaffoldDropTarget — drop zone',
              ScaffoldDropTarget(
                onAccept: (dynamic data) {},
                child: Padding(
                  padding: EdgeInsets.all(context.dimens.space6),
                  child: const Text('Drop zone — drag the chip here'),
                ),
              ),
            ),
            _section(
              'ScaffoldFileInputSurface — tap or drop',
              ScaffoldFileInputSurface(
                // Consumer-supplied picker. The scaffold has no hard
                // file-picker dependency; the demo returns a sample file so
                // the tap-to-pick flow is demonstrable without a native plugin.
                pickFile: () async => File('sample.txt'),
                onFileSelected: (File file) {},
              ),
            ),

            // -------------------------------------------------------------
            // Wave 3
            // -------------------------------------------------------------
            _waveHeader('Wave 3 — Template-Generated Composites'),
            _section(
              'ScaffoldCard — elevated',
              const ScaffoldCard(
                variant: 'elevated',
                header: Text('Elevated card'),
                body: Text('Header / body / actions slots.'),
              ),
            ),
            _section(
              'ScaffoldCard — outlined',
              const ScaffoldCard(
                variant: 'outlined',
                header: Text('Outlined card'),
                body: Text('1px borderSubtle border, transparent background.'),
              ),
            ),
            _section(
              'ScaffoldStateView — loading',
              const ScaffoldStateView(state: 'loading'),
            ),
            _section(
              'ScaffoldStateView — empty',
              const ScaffoldStateView(state: 'empty'),
            ),
            _section(
              'ScaffoldSearchBar — interactive',
              const ScaffoldSearchBar(
                hintText: 'Search atoms...',
                resultCount: 3,
                resultGroups: <SearchResultGroup>[
                  SearchResultGroup(
                    label: 'Atoms',
                    items: <SearchResult>[
                      SearchResult(id: 'surface', title: 'ScaffoldSurface'),
                      SearchResult(id: 'pressable', title: 'ScaffoldPressable'),
                      SearchResult(id: 'skeleton', title: 'ScaffoldSkeleton'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waveHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _section(String title, Widget child) {
    final dimens = context.dimens;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dimens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: dimens.space2),
            child: Text(title, style: textTheme.titleMedium),
          ),
          ScaffoldSurface(
            padding: EdgeInsets.all(dimens.space6),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _motionInfo() {
    return Text(
      'durations: short ${ScaffoldMotionDurations.short.inMilliseconds}ms, '
      'medium ${ScaffoldMotionDurations.medium.inMilliseconds}ms, '
      'long ${ScaffoldMotionDurations.long.inMilliseconds}ms\n'
      'curves: standard (easeInOut), decelerate (easeOut), emphasized',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _animatedBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.palette.blue500,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
