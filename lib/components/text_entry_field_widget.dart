import 'package:flutter/material.dart';
import 'package:frontend_scaffold/theme/scaffold_theme.dart';
import 'package:frontend_scaffold/components/text_form_field_logic.dart';

class TextEntryFieldWidget extends StatelessWidget {
  final TextFormFieldLogic logic;

  const TextEntryFieldWidget({
    super.key,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dimens = context.dimens;
    final typography = context.typography;
    final colorRoles = context.colorRoles;
    final shapes = context.shapes;

    return TextFormField(
      style: typography.inputStyle.copyWith(color: colorRoles.inputForeground),
      decoration: InputDecoration(
          hintText: logic.hintText,
          hintStyle: typography.inputStyle.copyWith(color: palette.gray500),
          prefixIcon: null,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorRoles.accentOnSurface,
              width: shapes.inputFocusedBorderWidth ?? 1.0,
            ),
            borderRadius:
                BorderRadius.circular(dimens.borderRadiusCard),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorRoles.borderControl,
              width: 1.0,
            ),
            borderRadius:
                BorderRadius.circular(dimens.borderRadiusCard),
          ),
          filled: true,
          fillColor: palette.grayPrimary,
          suffixIcon: null,
          contentPadding: const EdgeInsets.all(16)),
      controller: logic.controller,
      initialValue: logic.initialValue,
      keyboardType: logic.keyboardType,
      textCapitalization: logic.textCapitalization,
      autofocus: logic.autofocus,
      readOnly: logic.readOnly,
      obscureText: logic.obscureText,
      maxLengthEnforcement: logic.maxLengthEnforcement,
      minLines: logic.minLines,
      maxLines: logic.maxLines,
      expands: logic.expands,
      maxLength: logic.maxLength,
      onChanged: logic.onChanged,
      onTap: logic.onTap,
      onEditingComplete: logic.onEditingComplete,
      onFieldSubmitted: logic.onFieldSubmitted,
      onSaved: logic.onSaved,
      validator: logic.validator,
      inputFormatters: logic.inputFormatters,
      enabled: logic.enabled,
      scrollPhysics: logic.scrollPhysics,
      autovalidateMode: logic.autovalidateMode,
      scrollController: logic.scrollController,
      textAlign: logic.textAlign,
      textAlignVertical: logic.textAlignVertical,
    );
  }
}
