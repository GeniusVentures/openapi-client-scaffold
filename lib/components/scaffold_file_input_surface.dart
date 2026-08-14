import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:frontend_scaffold/components/scaffold_dashed_border.dart';
import 'package:frontend_scaffold/components/scaffold_disabled_overlay.dart';
import 'package:frontend_scaffold/components/scaffold_drop_target.dart';
import 'package:frontend_scaffold/components/scaffold_status_indicator.dart';
import 'package:frontend_scaffold/components/scaffold_surface.dart';
import 'package:frontend_scaffold/theme/scaffold_palette.dart';
import 'package:frontend_scaffold/theme/scaffold_dimens.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';

/// File select / drop surface with validation.
///
/// Composes [ScaffoldSurface] + [ScaffoldDropTarget] + [ScaffoldStatusIndicator].
/// Idle renders a dashed border with an upload icon and [idleLabel]; a valid
/// file shows a `palette.statusSuccess` border with a check icon and filename;
/// an invalid file shows a `palette.statusError` border with an error icon and
/// the validation message. The surface is tappable — the tap handler calls
/// the consumer-supplied [pickFile] and then [onFileSelected] with the picked
/// [File], running [validate] to derive the valid/invalid state. When
/// [pickFile] is null the surface is drop-only (no tap-to-pick), since file
/// picking is a platform concern the scaffold does not own.
class ScaffoldFileInputSurface extends StatefulWidget {
  const ScaffoldFileInputSurface({
    super.key,
    required this.onFileSelected,
    this.validate,
    this.maxSize,
    this.maxSizeExceededMessage = 'File is too large',
    this.disabled = false,
    this.idleLabel = 'Choose a file or drag here',
    this.pickFile,
  });

  /// Called with the selected [File] after a pick or drop.
  final ValueChanged<File> onFileSelected;

  /// Returns a non-null validation message to mark the file invalid.
  final String? Function(File file)? validate;

  /// Optional maximum file size in bytes; larger files are rejected.
  final int? maxSize;

  /// Error message shown when a file exceeds [maxSize] (consumer-supplied
  /// copy).
  final String maxSizeExceededMessage;

  /// When true, applies [ScaffoldDisabledOverlay] and blocks interaction.
  final bool disabled;

  /// Label shown in the idle state (consumer-supplied copy).
  final String idleLabel;

  /// Injectable file-picker supplied by the consumer. When null, the surface
  /// is drop-only — no tap-to-pick. The scaffold deliberately has no
  /// hard file-picker dependency; consumers wire `file_picker`, `image_picker`,
  /// or a platform channel here. Tests inject a fake to avoid native channels.
  final Future<File?> Function()? pickFile;

  @override
  State<ScaffoldFileInputSurface> createState() =>
      _ScaffoldFileInputSurfaceState();
}

class _ScaffoldFileInputSurfaceState extends State<ScaffoldFileInputSurface> {
  File? _selectedFile;
  String? _validationError;

  Future<void> _pick() async {
    final Future<File?> Function()? picker = widget.pickFile;
    if (picker == null) {
      // Drop-only surface — no consumer picker wired, so tap does nothing.
      return;
    }
    final File? file = await picker();
    if (file == null || !mounted) {
      return;
    }
    _applyFile(file);
  }

  void _applyFile(File file) {
    String? error;
    final int? maxSize = widget.maxSize;
    if (maxSize != null) {
      try {
        if (file.lengthSync() > maxSize) {
          error = widget.maxSizeExceededMessage;
        }
      } catch (_) {
        // The file may not exist on disk (e.g. an injected test file); defer
        // to the consumer validate callback.
      }
    }
    error ??= widget.validate?.call(file);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFile = file;
      _validationError = error;
    });
    widget.onFileSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldPalette palette = context.palette;
    final ScaffoldDimens dimens = context.dimens;

    Widget content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.disabled ? null : _pick,
      child: _buildContent(palette),
    );

    content = ScaffoldDropTarget(
      showIdleBorder: false,
      acceptCondition: (dynamic data) => data is File,
      onAccept: (dynamic data) => _applyFile(data as File),
      child: content,
    );

    final BorderRadius radius = BorderRadius.circular(dimens.borderRadiusCard);
    Widget result;
    if (_selectedFile == null) {
      result = ScaffoldDashedBorder(
        color: palette.borderSubtle,
        borderRadius: radius,
        child: ScaffoldSurface(child: content),
      );
    } else if (_validationError == null) {
      result = ScaffoldSurface(
        border: Border.all(color: palette.statusSuccess, width: 2),
        child: content,
      );
    } else {
      result = ScaffoldSurface(
        border: Border.all(color: palette.statusError, width: 2),
        child: content,
      );
    }

    if (widget.disabled) {
      result = ScaffoldDisabledOverlay(disabled: true, child: result);
    }

    return result;
  }

  Widget _buildContent(ScaffoldPalette palette) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final File? file = _selectedFile;

    if (file == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.upload_file, size: 48, color: palette.textSecondary),
          SizedBox(height: context.dimens.space4),
          Text(widget.idleLabel, style: textTheme.bodyLarge),
        ],
      );
    }

    if (_validationError == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle, size: 48, color: palette.statusSuccess),
          SizedBox(height: context.dimens.space4),
          const ScaffoldStatusIndicator(
            status: StatusVariant.success,
            label: 'Valid file',
          ),
          SizedBox(height: context.dimens.space2),
          Text(_fileName(file), style: textTheme.bodyLarge),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.error, size: 48, color: palette.statusError),
        SizedBox(height: context.dimens.space4),
        const ScaffoldStatusIndicator(
          status: StatusVariant.error,
          label: 'Invalid file',
        ),
        SizedBox(height: context.dimens.space2),
        Text(_validationError!, style: textTheme.bodyLarge),
      ],
    );
  }

  String _fileName(File file) {
    final String path = file.path;
    final int separator = path.lastIndexOf(RegExp(r'[/\\]'));
    return separator == -1 ? path : path.substring(separator + 1);
  }
}
