typedef ProgressCallback = void Function(String message, double? progress);
typedef TransitOperation = Future<List<String>> Function({ProgressCallback? onProgress, bool forceRefresh});