class RefreshLoadingState {
  const RefreshLoadingState._();

  static bool shouldShowInitialLoading({
    required bool isLoading,
    required bool hasCompletedFirstLoad,
    required bool hasContent,
  }) {
    if (!isLoading) {
      return false;
    }

    return !hasCompletedFirstLoad;
  }
}
