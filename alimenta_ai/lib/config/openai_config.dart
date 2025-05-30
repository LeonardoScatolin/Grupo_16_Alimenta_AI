class OpenAIConfig {
  // TODO: Configure sua API key da OpenAI aqui
  // Você pode obter uma API key em: https://platform.openai.com/api-keys
  static const String apiKey =
      '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';
  // Configurações do Whisper
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
