/// Google Maps Platform API key for Places Web Service (client-side).
///
/// Restrict this key in Google Cloud Console (Android/iOS apps + Places API).
/// Maps SDK key is configured separately in native projects (see README).
abstract final class MapsConfig {
  static const apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasPlacesApiKey => apiKey.isNotEmpty;
}
