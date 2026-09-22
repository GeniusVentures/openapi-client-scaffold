# Ticket: TextEntryFieldWidget light-mode contrast (entered text)

**Filed by:** GCS chat workstream (phase 02-spaces-rooms, plan 02-04 Task 1)
**Date:** 2026-09-19
**Component:** `lib/components/text_entry_field_widget.dart`
**Type:** accessibility / contrast bug
**Severity:** minor (light palette only, entered text only)

## Problem

`TextEntryFieldWidget` hardcodes the input text color to `Colors.white`
(`text_entry_field_widget.dart:18-25`, the `style` of the internal
`TextFormField`) while the field fill is `palette.grayPrimary`. On the dark
palette this is correct. On the light palette the fill is near-white
(#F1F3F5), so typed text renders white-on-near-white — a contrast failure.

## Scope

- Entered text ONLY. Hint text uses `palette.gray500` and is unaffected.
- Light palette ONLY. Dark palette is correct as-is.

## Consumer constraint

The GCS chat app composes this atom for its create/edit dialog
(`src/app/lib/shell/space_room_dialog.dart`, phase 2 decision D-05). The
scaffold submodule is read-only for that workstream — the consumer will not
fork or wrap-fix the atom; the fix belongs here.

## Suggested fix

Resolve the input `style` color from the palette (e.g.
`palette.textPrimary`) instead of the hardcoded `Colors.white`, consistent
with how the hint style already resolves `palette.gray500`. If this file is
template-generated, change the template and regenerate per CONTRIBUTING.md.

## Repro

Run any consumer app on the light palette, type into a
`TextEntryFieldWidget`, and observe the near-invisible entered text.
