class OpenAIConfig {
  // TODO: Configure sua API key da OpenAI aqui
  // Você pode obter uma API key em: https://platform.openai.com/api-keys
  // static const String apiKey = ""
  static const String model = 'gpt-4o-mini-transcribe';
  static const String language = 'pt'; // Português
  static const double temperature = 0.0; // Para maior precisão

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Verificar se a API key está configurada
  static bool get isConfigured =>
      apiKey != 'YOUR_OPENAI_API_KEY' && apiKey.isNotEmpty;
}
