class AppUser {
  const AppUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  String get label => displayName ?? email ?? 'Rider';
}
