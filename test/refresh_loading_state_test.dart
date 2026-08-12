import 'package:flutter_test/flutter_test.dart';
import 'package:farm/utils/refresh_loading_state.dart';

void main() {
  group('RefreshLoadingState', () {
    test('only shows the loader while the first fetch is still pending or content is empty', () {
      expect(
        RefreshLoadingState.shouldShowInitialLoading(
          isLoading: true,
          hasCompletedFirstLoad: false,
          hasContent: false,
        ),
        isTrue,
      );

      expect(
        RefreshLoadingState.shouldShowInitialLoading(
          isLoading: true,
          hasCompletedFirstLoad: false,
          hasContent: true,
        ),
        isTrue,
      );

      expect(
        RefreshLoadingState.shouldShowInitialLoading(
          isLoading: true,
          hasCompletedFirstLoad: true,
          hasContent: false,
        ),
        isFalse,
      );

      expect(
        RefreshLoadingState.shouldShowInitialLoading(
          isLoading: true,
          hasCompletedFirstLoad: true,
          hasContent: true,
        ),
        isFalse,
      );

      expect(
        RefreshLoadingState.shouldShowInitialLoading(
          isLoading: false,
          hasCompletedFirstLoad: true,
          hasContent: true,
        ),
        isFalse,
      );
    });
  });
}
