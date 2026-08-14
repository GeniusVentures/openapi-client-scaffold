import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_scaffold/components/scaffold_card_state.dart';
import 'package:frontend_scaffold/components/scaffold_search_bar_state.dart';
import 'package:frontend_scaffold/components/scaffold_state_view_state.dart';

void main() {
  test('copyWith can reset a nullable field to null (card lastAction)', () {
    const state = ScaffoldCardState(cardVariant: 'elevated', lastAction: 'tap');

    expect(state.copyWith(lastAction: null).lastAction, isNull);
    // Omitted fields keep their current value.
    expect(state.copyWith().lastAction, 'tap');
  });

  test('copyWith can reset a nullable field to null (state view lastError)', () {
    const state = ScaffoldStateViewState(stateType: 'error', lastError: 'boom');

    expect(state.copyWith(lastError: null).lastError, isNull);
    expect(state.copyWith(stateType: 'empty').lastError, 'boom');
  });

  test('copyWith can reset a nullable field to null (search errorMessage)', () {
    const state = ScaffoldSearchBarState(query: 'q', errorMessage: 'failed');

    expect(state.copyWith(errorMessage: null).errorMessage, isNull);
    expect(state.copyWith(query: 'q2').errorMessage, 'failed');
  });
}
