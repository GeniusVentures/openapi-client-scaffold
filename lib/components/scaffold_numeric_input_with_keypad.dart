import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_live_region.dart';
import 'package:frontend_scaffold/components/scaffold_numeric_input.dart';
import 'package:frontend_scaffold/components/scaffold_touch_target.dart';

/// Default semantic label of the composable's tappable value display.
const String kScaffoldNumericKeypadValueTapLabel = 'Edit value';

/// Default semantic label of the keypad's decimal-point key.
const String kScaffoldKeypadDecimalLabel = 'decimal point';

/// Default semantic label of the keypad's digit keys ('digit 7').
String scaffoldKeypadDigitLabel(String digit) => 'digit $digit';

/// Opt-in tappable-number composable over [ScaffoldNumericInput]
/// (SCF-POS-02: touch keypad — numeric/decimal, clear/backspace, 48px+
/// targets, spoken values).
///
/// Both entry paths are first-class and coexist: the +/- steppers keep
/// stepping, and tapping the value display opens a keypad popover for
/// direct entry. This widget adds NO bounds logic of its own — the
/// stepper path clamps inside [ScaffoldNumericInput] exactly as before,
/// and the keypad path clamps once at the sheet's Apply commit edge
/// (see [showScaffoldNumericKeypad]) before the single
/// [ScaffoldNumericInputWithKeypad.onChanged] delivery.
///
/// Opt-in means opt-in: [ScaffoldNumericInput] without
/// [ScaffoldNumericInput.onValueTap] renders the legacy widget tree, so
/// consumers that never adopt this composable see no change.
class ScaffoldNumericInputWithKeypad extends StatefulWidget {
  /// Creates a [ScaffoldNumericInputWithKeypad].
  const ScaffoldNumericInputWithKeypad({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 1,
    this.decimalPlaces = 0,
    this.prefix,
    this.suffix,
    this.disabled = false,
    this.error,
    this.sheetTitle,
    this.applyLabel = 'Apply',
    this.clearLabel = 'Clear',
    this.backspaceLabel = 'Backspace',
    this.valueTapLabel = kScaffoldNumericKeypadValueTapLabel,
  });

  /// Current numeric value.
  final num value;

  /// Called with the next value — a stepper step or a keypad Apply
  /// (already clamped to [min]/[max] and quantized to [decimalPlaces]
  /// by the path that produced it).
  final ValueChanged<num> onChanged;

  /// Lower bound shared by both entry paths.
  final num min;

  /// Upper bound shared by both entry paths.
  final num max;

  /// Amount added/subtracted per stepper button press.
  final num step;

  /// Decimal places shown in the formatted value and enforced by the
  /// keypad (the decimal key renders only when this is positive).
  final int decimalPlaces;

  /// Optional text prepended to the value.
  final String? prefix;

  /// Optional text appended to the value.
  final String? suffix;

  /// When true, blocks both entry paths via [ScaffoldNumericInput].
  final bool disabled;

  /// When non-null, tints the value text.
  final String? error;

  /// Optional title rendered above the keypad sheet's draft.
  final String? sheetTitle;

  /// Label of the sheet's Apply action.
  final String applyLabel;

  /// Label of the sheet's Clear action.
  final String clearLabel;

  /// Semantic label of the sheet's backspace key.
  final String backspaceLabel;

  /// Semantic label of the tappable value display.
  final String valueTapLabel;

  @override
  State<ScaffoldNumericInputWithKeypad> createState() =>
      _ScaffoldNumericInputWithKeypadState();
}

class _ScaffoldNumericInputWithKeypadState
    extends State<ScaffoldNumericInputWithKeypad> {
  Future<void> _openKeypad() async {
    final num? committed = await showScaffoldNumericKeypad(
      context,
      initialValue: widget.value,
      min: widget.min,
      max: widget.max,
      decimalPlaces: widget.decimalPlaces,
      sheetTitle: widget.sheetTitle,
      applyLabel: widget.applyLabel,
      clearLabel: widget.clearLabel,
      backspaceLabel: widget.backspaceLabel,
    );
    if (!mounted || committed == null) {
      return;
    }
    widget.onChanged(committed);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldNumericInput(
      value: widget.value,
      onChanged: widget.onChanged,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      decimalPlaces: widget.decimalPlaces,
      prefix: widget.prefix,
      suffix: widget.suffix,
      disabled: widget.disabled,
      error: widget.error,
      onValueTap: _openKeypad,
      valueTapLabel: widget.valueTapLabel,
    );
  }
}

/// Opens the numeric keypad popover; pops the committed value, or null
/// when dismissed (barrier tap / back).
///
/// The sheet drafts raw digit text through the pure [ScaffoldKeypadEntry]
/// and carries NO bounds math of its own until the single commit edge:
/// Apply parses the draft, clamps it to `[min, max]`, quantizes it to
/// [decimalPlaces] via `toStringAsFixed`, and pops the result — the same
/// clamp+quantize discipline the stepper path applies inside
/// [ScaffoldNumericInput]. The popped value can therefore never sit
/// outside `[min, max]`; a dismissed sheet never pops a value at all.
Future<num?> showScaffoldNumericKeypad(
  BuildContext context, {
  required num initialValue,
  required num min,
  required num max,
  int decimalPlaces = 0,
  String? sheetTitle,
  String applyLabel = 'Apply',
  String clearLabel = 'Clear',
  String backspaceLabel = 'Backspace',
}) {
  return showModalBottomSheet<num>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _ScaffoldKeypadSheet(
      initialValue: initialValue,
      min: min,
      max: max,
      decimalPlaces: decimalPlaces,
      sheetTitle: sheetTitle,
      applyLabel: applyLabel,
      clearLabel: clearLabel,
      backspaceLabel: backspaceLabel,
    ),
  );
}

/// Pure keypad draft state (SCF-POS-02) — raw digit text with at most
/// one '.', never a formatted number.
///
/// All entry rules live here, not in the widget tree, so the sheet stays
/// thin and the rules stay unit-testable: a '.' is rejected outright
/// when [decimalPlaces] is 0 and when the draft already carries one; the
/// fraction is capped at [decimalPlaces] digits; anything that is
/// neither a digit nor '.' is ignored.
class ScaffoldKeypadEntry {
  /// Creates a [ScaffoldKeypadEntry] over raw [text].
  const ScaffoldKeypadEntry(this.text, {this.decimalPlaces = 0});

  /// Raw draft text: digits with at most one '.'.
  final String text;

  /// Maximum fraction digits the draft may hold.
  final int decimalPlaces;

  /// Whether nothing has been entered.
  bool get isEmpty => text.isEmpty;

  /// Appends one key ('0'-'9' or '.') and returns the next entry.
  ScaffoldKeypadEntry append(String key) {
    if (key == _kDecimalPoint) {
      if (decimalPlaces == 0 || text.contains(_kDecimalPoint)) {
        return this;
      }
      return ScaffoldKeypadEntry(
        text.isEmpty ? '0$_kDecimalPoint' : '$text$_kDecimalPoint',
        decimalPlaces: decimalPlaces,
      );
    }
    if (!_isDigit(key)) {
      return this;
    }
    final int dot = text.indexOf(_kDecimalPoint);
    if (dot != -1 && text.length - dot - 1 >= decimalPlaces) {
      return this;
    }
    return ScaffoldKeypadEntry('$text$key', decimalPlaces: decimalPlaces);
  }

  /// Deletes the last character and returns the next entry.
  ScaffoldKeypadEntry backspace() => text.isEmpty
      ? this
      : ScaffoldKeypadEntry(
          text.substring(0, text.length - 1),
          decimalPlaces: decimalPlaces,
        );

  /// Empties the draft.
  ScaffoldKeypadEntry clear() =>
      ScaffoldKeypadEntry('', decimalPlaces: decimalPlaces);

  /// Parses the draft to a num (0 for an empty or malformed draft; the
  /// append rules make malformed text unreachable).
  num parse() => text.isEmpty ? 0 : (num.tryParse(text) ?? 0);
}

/// The decimal-point key string.
const String _kDecimalPoint = '.';

/// Code unit of '0'.
const int _kDigitZero = 0x30;

/// Code unit of '9'.
const int _kDigitNine = 0x39;

bool _isDigit(String key) =>
    key.length == 1 &&
    key.codeUnitAt(0) >= _kDigitZero &&
    key.codeUnitAt(0) <= _kDigitNine;

/// Visual height of one keypad key (comfortably above the 48px floor).
const double _kKeyHeight = 64.0;

/// Gap between adjacent keys and sheet sections.
const double _kGap = 8.0;

/// Corner radius of a key's rounded fill.
const double _kKeyRadius = 8.0;

/// Size of the backspace icon.
const double _kBackspaceIconSize = 24.0;

/// Minimum size of the sheet's actions (48px touch floor).
const double _kActionMinSize = 48.0;

/// Maximum content width of the sheet on wide screens.
const double _kSheetMaxWidth = 640.0;

/// The keypad sheet body: draft display + the 3x4 key grid + Clear +
/// Apply. The draft seeds from the field's current value; the FIRST key
/// press starts a fresh entry (direct entry replaces the seed), while
/// backspace/Clear edit it from the seed.
class _ScaffoldKeypadSheet extends StatefulWidget {
  /// Creates a [_ScaffoldKeypadSheet] seeded with [initialValue].
  const _ScaffoldKeypadSheet({
    required this.initialValue,
    required this.min,
    required this.max,
    required this.decimalPlaces,
    required this.sheetTitle,
    required this.applyLabel,
    required this.clearLabel,
    required this.backspaceLabel,
  });

  /// The field's current value — the draft's starting text.
  final num initialValue;

  /// Commit-edge lower bound.
  final num min;

  /// Commit-edge upper bound.
  final num max;

  /// Maximum fraction digits (0 renders no decimal key).
  final int decimalPlaces;

  /// Optional title above the draft.
  final String? sheetTitle;

  /// Apply action label.
  final String applyLabel;

  /// Clear action label.
  final String clearLabel;

  /// Backspace key semantic label.
  final String backspaceLabel;

  @override
  State<_ScaffoldKeypadSheet> createState() => _ScaffoldKeypadSheetState();
}

class _ScaffoldKeypadSheetState extends State<_ScaffoldKeypadSheet> {
  late ScaffoldKeypadEntry _entry;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _entry = ScaffoldKeypadEntry(
      widget.initialValue.toStringAsFixed(widget.decimalPlaces),
      decimalPlaces: widget.decimalPlaces,
    );
  }

  void _onKey(String key) {
    setState(() {
      // First key press replaces the seed — direct entry, not append.
      _entry = _edited
          ? _entry.append(key)
          : ScaffoldKeypadEntry(
              '',
              decimalPlaces: widget.decimalPlaces,
            ).append(key);
      _edited = true;
    });
  }

  void _onBackspace() {
    setState(() {
      _entry = _entry.backspace();
      _edited = true;
    });
  }

  void _onClear() {
    setState(() {
      _entry = _entry.clear();
      _edited = true;
    });
  }

  /// The single commit edge: parse -> clamp to [min, max] -> quantize to
  /// [widget.decimalPlaces] (the stepper path's discipline).
  void _apply() {
    final num clamped = _entry.parse().clamp(widget.min, widget.max);
    final num quantized = num.parse(
      clamped.toStringAsFixed(widget.decimalPlaces),
    );
    Navigator.of(context).pop(quantized);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String draft = _entry.text.isEmpty ? '0' : _entry.text;
    final bool hasTitle = widget.sheetTitle != null;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kSheetMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(_kGap * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: hasTitle
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: <Widget>[
                    if (hasTitle)
                      Expanded(
                        child: Text(
                          widget.sheetTitle!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          _kActionMinSize,
                          _kActionMinSize,
                        ),
                      ),
                      onPressed: _onClear,
                      child: Text(widget.clearLabel),
                    ),
                  ],
                ),
                const SizedBox(height: _kGap),
                ScaffoldLiveRegion(
                  value: draft,
                  child: Text(
                    draft,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: _kGap * 2),
                for (int row = 0; row < 4; row++)
                  Padding(
                    padding: EdgeInsets.only(bottom: row == 3 ? 0 : _kGap),
                    child: Row(children: _buildRowCells(context, row, theme)),
                  ),
                const SizedBox(height: _kGap),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(_kActionMinSize, _kActionMinSize),
                  ),
                  onPressed: _apply,
                  child: Text(widget.applyLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One keypad row: three [Expanded] key cells (direct [Row] children,
  /// as Flex requires) with fixed gaps between them.
  List<Widget> _buildRowCells(BuildContext context, int row, ThemeData theme) {
    const List<String> order = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      '<',
    ];
    final List<Widget> cells = <Widget>[
      for (int column = 0; column < 3; column++)
        Expanded(child: _buildCell(context, order[row * 3 + column], theme)),
    ];
    final List<Widget> gapped = <Widget>[cells.first];
    for (int i = 1; i < cells.length; i++) {
      gapped.add(const SizedBox(width: _kGap));
      gapped.add(cells[i]);
    }
    return gapped;
  }

  /// One grid cell: the decimal key renders ONLY when fraction digits
  /// are allowed; otherwise the cell stays blank.
  Widget _buildCell(BuildContext context, String key, ThemeData theme) {
    if (key == '<') {
      return _backspaceCell(theme);
    }
    if (key == _kDecimalPoint) {
      if (widget.decimalPlaces == 0) {
        return const SizedBox.shrink();
      }
      return _keyCell(
        theme,
        glyph: _kDecimalPoint,
        semanticsLabel: kScaffoldKeypadDecimalLabel,
        onTap: () => _onKey(_kDecimalPoint),
      );
    }
    return _keyCell(
      theme,
      glyph: key,
      semanticsLabel: scaffoldKeypadDigitLabel(key),
      onTap: () => _onKey(key),
    );
  }

  /// One digit/decimal key: a 48px-floored [ScaffoldTouchTarget] over an
  /// M3 key fill, with the glyph excluded from semantics so the explicit
  /// [semanticsLabel] is exhaustive.
  Widget _keyCell(
    ThemeData theme, {
    required String glyph,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return ScaffoldTouchTarget(
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: SizedBox(
          height: _kKeyHeight,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_kKeyRadius),
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    glyph,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The backspace key (icon fill + semantics label, no glyph text).
  Widget _backspaceCell(ThemeData theme) {
    return ScaffoldTouchTarget(
      child: Semantics(
        button: true,
        label: widget.backspaceLabel,
        child: SizedBox(
          height: _kKeyHeight,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_kKeyRadius),
            child: InkWell(
              onTap: _onBackspace,
              child: Center(
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: _kBackspaceIconSize,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
