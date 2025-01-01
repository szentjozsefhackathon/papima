library common;

Map<dynamic, dynamic>? firstWhereOrFirst(
    List<Map> list, bool Function(Map) test) {
  try {
    return list.firstWhere(test);
  } catch (_) {
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }
}
