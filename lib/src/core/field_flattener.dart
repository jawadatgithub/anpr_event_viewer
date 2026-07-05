class FieldFlattener {
  static Map<String, dynamic> flattenMap(Map<String, dynamic> input) {
    final output = <String, dynamic>{};

    void walk(dynamic value, String path) {
      if (value is Map) {
        for (final entry in value.entries) {
          final key = entry.key.toString();
          final nextPath = path.isEmpty ? key : '$path.$key';
          walk(entry.value, nextPath);
        }
        return;
      }

      if (value is List) {
        output[path] = value;
        for (var i = 0; i < value.length; i++) {
          walk(value[i], '$path.$i');
        }
        return;
      }

      if (path.isEmpty) return;
      output[path] = value;

      final leaf = path.split('.').last;
      output.putIfAbsent(leaf, () => value);
    }

    walk(input, '');
    return {...input, ...output};
  }
}
