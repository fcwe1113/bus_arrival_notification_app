class RefreshResult {
  final List<String> failedItems;

  const RefreshResult({this.failedItems = const []});

  bool get hasFailures => failedItems.isNotEmpty;
}