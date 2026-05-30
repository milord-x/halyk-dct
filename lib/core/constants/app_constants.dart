class AppConstants {
  // Переключатель: true = mock-данные, false = реальный API
  static const bool useMock = true;

  // Базовый URL реального API (меняется при подключении к БД)
  static const String apiBaseUrl = 'http://192.168.1.100:8000/api/v1';

  // Таймаут запросов
  static const Duration requestTimeout = Duration(seconds: 15);
}
