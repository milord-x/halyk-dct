class AppConstants {
  static const bool useMock = false;

  static const String apiBaseUrl = 'https://banner-author-declared.ngrok-free.dev/api/v1';

  static const Duration requestTimeout = Duration(seconds: 30);

  // ngrok требует этот заголовок чтобы пропустить страницу предупреждения
  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };
}
