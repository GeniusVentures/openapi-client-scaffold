import 'package:flutter/material.dart';
import 'package:genius_scaffold/theme/scaffold_colors.dart';
import 'package:genius_scaffold/theme/scaffold_dimens.dart';
import 'package:genius_scaffold/components/text_form_field_logic.dart';

class TextEntryFieldWidget extends StatelessWidget {
  final TextFormFieldLogic logic;

  const TextEntryFieldWidget({
    Key? key,
    required this.logic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: Colors.white,
      ),
      decoration: InputDecoration(
          hintText: logic.hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.0,
            color: ScaffoldColors.gray500,
          ),
          prefixIcon: null,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: ScaffoldColors.lightGreenPrimary,
              width: 1.0,
            ),
            borderRadius:
                BorderRadius.circular(ScaffoldDimens.borderRadiusCard),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: ScaffoldColors.borderGrey,
              width: 1.0,
            ),
            borderRadius:
                BorderRadius.circular(ScaffoldDimens.borderRadiusCard),
          ),
          filled: true,
          fillColor: ScaffoldColors.grayPrimary,
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
