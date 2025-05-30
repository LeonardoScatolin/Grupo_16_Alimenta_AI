import 'package:dio/dio.dart';

void main() async {
  print('🧪 Testando conexão com backend...');

  try {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    // Teste 1: Verificar se o backend está acessível
    print('📡 Teste 1: Verificando se backend está acessível...');
    final response = await dio.get('http://localhost:3333');
    print('✅ Backend respondeu com status: ${response.statusCode}');

    // Teste 2: Testar a rota específica
    print('📡 Teste 2: Testando rota de busca por transcrição...');
    final searchResponse = await dio.post(
      'http://localhost:3333/alimento/buscar-por-transcricao',
      data: {
        'texto_transcrito': 'maçã',
        'limite': 5,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    print('✅ Rota de busca respondeu com status: ${searchResponse.statusCode}');
    print('✅ Dados recebidos: ${searchResponse.data}');
  } on DioException catch (e) {
    print('❌ Erro Dio:');
    print('Tipo: ${e.type}');
    print('Mensagem: ${e.message}');
    print('Código: ${e.response?.statusCode}');
    print('URL: ${e.requestOptions.uri}');
  } catch (e) {
    print('❌ Erro geral: $e');
  }
}
