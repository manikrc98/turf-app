class AuthConstants {
  /// Web Client ID from Google Cloud Console (OAuth 2.0 Client IDs -> Web application)
  /// This is REQUIRED for Android to retrieve the `idToken` from Google Sign-In.
  static const String googleWebClientId = '946550792820-uq3rvvmjvrl00vru9kcfb7kdvspugma6.apps.googleusercontent.com';

  /// iOS Client ID from Google Cloud Console (OAuth 2.0 Client IDs -> iOS)
  /// This is REQUIRED for iOS to authenticate.
  static const String googleIosClientId = '946550792820-56rlft5uopjpfl8jigq4l8dh0qkv118k.apps.googleusercontent.com';
}
