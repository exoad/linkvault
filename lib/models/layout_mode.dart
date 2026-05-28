enum LayoutMode {
  list,
  grid,
}

extension LayoutModeX on LayoutMode {
  String get storageValue => name;

  static LayoutMode fromStorage(String value) {
    return LayoutMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LayoutMode.list,
    );
  }
}
