enum AppFlavor {
  development,
  demo,
  production;

  static AppFlavor fromName(String? name) {
    return AppFlavor.values.firstWhere(
      (f) => f.name == name,
      orElse: () => AppFlavor.development,
    );
  }

  bool get isDemo => this == AppFlavor.demo;

  String get displayName {
    switch (this) {
      case AppFlavor.development:
        return 'Development';
      case AppFlavor.demo:
        return 'Demo';
      case AppFlavor.production:
        return 'Production';
    }
  }
}
