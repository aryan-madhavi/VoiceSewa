/// A phone-book contact, enriched with Vaani app data when registered.
class AppContact {
  const AppContact({
    required this.displayName,
    this.phoneNumber,
    this.uid,
    this.isOnApp = false,
  });

  final String displayName;
  final String? phoneNumber; // E.164 normalised
  final String? uid;         // set when contact is a registered Vaani user
  final bool isOnApp;
}
