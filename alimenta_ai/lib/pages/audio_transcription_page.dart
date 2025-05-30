import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:alimenta_ai/services/audio_service.dart';

class AudioTranscriptionPage extends StatefulWidget {
  const AudioTranscriptionPage({super.key});

  @override
  State<AudioTranscriptionPage> createState() => _AudioTranscriptionPageState();
}

class _AudioTranscriptionPageState extends State<AudioTranscriptionPage> {
  Map<String, dynamic>? _systemHealth;
  List<String> _storedFiles = [];

  // Novos estados para busca de alimentos
  bool _isSearchingFood = false;
  Map<String, dynamic>? _foodSearchResult;
  String? _lastSearchText;

  @override
  void initState() {
    super.initState();
    // Configure sua API key da OpenAI aqui ou no arquivo de configuração
    // context.read<AudioService>().setOpenAIApiKey('sua_api_key_aqui');
    _checkSystemHealth();
  }

  Future<void> _checkSystemHealth() async {
    final audioService = context.read<AudioService>();
    final health = await audioService.checkAudioSystemHealth();
    final files = await audioService.getStoredAudioFiles();

    setState(() {
      _systemHealth = health;
      _storedFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gravação e Transcrição'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<AudioService>(
        builder: (context, audioService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status da configuração
                Card(
                  color: audioService.isOpenAIConfigured
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          audioService.isOpenAIConfigured
                              ? Icons.check_circle
                              : Icons.warning,
                          color: audioService.isOpenAIConfigured
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            audioService.isOpenAIConfigured
                                ? 'OpenAI configurada e pronta'
                                : 'Configure sua API key da OpenAI',
                            style: TextStyle(
                              color: audioService.isOpenAIConfigured
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Informações do sistema de áudio
                if (_systemHealth != null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado do Sistema de Áudio',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _systemHealth!['permissions']
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _systemHealth!['permissions']
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                  'Permissões: ${_systemHealth!['permissions'] ? 'OK' : 'Negadas'}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _systemHealth!['openai_configured']
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _systemHealth!['openai_configured']
                                    ? Colors.green
                                    : Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                  'OpenAI: ${_systemHealth!['openai_configured'] ? 'Configurado' : 'Pendente'}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.folder,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                  'Áudios armazenados: ${_storedFiles.length}'),
                              const SizedBox(width: 8),
                              if (_storedFiles.isNotEmpty)
                                TextButton(
                                  onPressed: () => _showStoredFiles(),
                                  child: const Text('Ver lista'),
                                ),
                              TextButton(
                                onPressed: () => _checkSystemHealth(),
                                child: const Text('Atualizar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Aviso específico para web
                if (kIsWeb)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Executando na web: transcrição automática desabilitada. Use em dispositivo móvel ou desktop para melhor experiência.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Duração da gravação
                if (audioService.isRecording)
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mic,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gravando: ${audioService.formattedDuration}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Status de transcrição
                if (audioService.isTranscribing)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Transcrevendo áudio...',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Botões de controle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão gravar/parar
                    ElevatedButton.icon(
                      onPressed: audioService.isTranscribing
                          ? null
                          : () async {
                              if (audioService.isRecording) {
                                await audioService.stopRecording();
                              } else {
                                final success =
                                    await audioService.startRecording();
                                if (!success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Falha ao iniciar gravação'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: Icon(
                        audioService.isRecording ? Icons.stop : Icons.mic,
                      ),
                      label: Text(
                        audioService.isRecording ? 'Parar' : 'Gravar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            audioService.isRecording ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Botão reproduzir
                    ElevatedButton.icon(
                      onPressed: audioService.currentRecordingPath != null &&
                              !audioService.isRecording &&
                              !audioService.isTranscribing
                          ? () async {
                              if (audioService.isPlaying) {
                                await audioService.stopPlaying();
                              } else {
                                await audioService.playRecording();
                              }
                            }
                          : null,
                      icon: Icon(
                        audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(
                        audioService.isPlaying ? 'Pausar' : 'Reproduzir',
                      ),
                    ),

                    // Botão deletar
                    ElevatedButton.icon(
                      onPressed: audioService.currentRecordingPath != null &&
                              !audioService.isRecording &&
                              !audioService.isTranscribing
                          ? () async {
                              await audioService.deleteCurrentRecording();
                            }
                          : null,
                      icon: const Icon(Icons.delete),
                      label: const Text('Deletar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Resultado da transcrição
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transcrição:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  audioService.lastTranscription ??
                                      'Nenhuma transcrição disponível.\n\nGrave um áudio para ver a transcrição aqui.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        audioService.lastTranscription != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                    fontStyle:
                                        audioService.lastTranscription != null
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ), // Botões de ação na transcrição
                          if (audioService.lastTranscription != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Botão para buscar alimentos
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSearchingFood
                                        ? null
                                        : () {
                                            _searchFoodFromTranscription(
                                                audioService);
                                          },
                                    icon: _isSearchingFood
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.search),
                                    label: Text(_isSearchingFood
                                        ? 'Buscando...'
                                        : 'Buscar Alimentos'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    audioService.clearTranscription();
                                    setState(() {
                                      _foodSearchResult = null;
                                      _lastSearchText = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpar'),
                                ),
                              ],
                            ),
                          ],

                          // Resultados da busca de alimentos
                          if (_foodSearchResult != null) ...[
                            const SizedBox(height: 16),
                            _buildFoodSearchResults(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStoredFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Áudios Armazenados'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _storedFiles.isEmpty
              ? const Center(child: Text('Nenhum áudio armazenado'))
              : ListView.builder(
                  itemCount: _storedFiles.length,
                  itemBuilder: (context, index) {
                    final filePath = _storedFiles[index];
                    final fileName = filePath.split('/').last.split('\\').last;

                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(fileName),
                      subtitle: Text(filePath),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            await File(filePath).delete();
                            await _checkSystemHealth();
                            if (mounted) {
                              Navigator.of(context).pop();
                              _showStoredFiles();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao deletar: $e')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final audioService = context.read<AudioService>();
              await audioService.cleanOldAudioFiles();
              await _checkSystemHealth();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Limpeza realizada!')),
                );
              }
            },
            child: const Text('Limpar Antigos'),
          ),
        ],
      ),
    );
  } // Método para enviar transcrição para o backend (não usado atualmente)
  // void _sendTranscriptionToBackend(String transcription) {
  //   debugPrint('📤 Enviando transcrição para backend: $transcription');
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //           'Transcrição enviada: ${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}...'),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  // }

  /// Buscar alimentos baseado na transcrição
  Future<void> _searchFoodFromTranscription(AudioService audioService) async {
    if (audioService.lastTranscription == null) return;

    setState(() {
      _isSearchingFood = true;
      _lastSearchText = audioService.lastTranscription;
    });

    try {
      final result = await audioService.transcribeAndSearchFood();

      setState(() {
        _foodSearchResult = result;
        _isSearchingFood = false;
      });

      if (result != null && result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Encontrados ${result['alimentos']?.length ?? 0} alimentos!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? 'Erro ao buscar alimentos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSearchingFood = false;
        _foodSearchResult = {
          'status': false,
          'error': 'Erro inesperado: $e',
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Widget para exibir resultados da busca de alimentos
  Widget _buildFoodSearchResults() {
    if (_foodSearchResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Alimentos Encontrados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastSearchText != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Busca: "$_lastSearchText"',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_foodSearchResult!['status'] == true) ...[
              if (_foodSearchResult!['alimentos'] != null &&
                  _foodSearchResult!['alimentos'].isNotEmpty) ...[
                Text(
                  '${_foodSearchResult!['alimentos'].length} alimento(s) encontrado(s):',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de alimentos
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _foodSearchResult!['alimentos'].length,
                    itemBuilder: (context, index) {
                      final alimento = _foodSearchResult!['alimentos'][index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            alimento['nome'] ?? 'Nome não disponível',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (alimento['calorias'] != null)
                                Text('Calorias: ${alimento['calorias']} kcal'),
                              if (alimento['categoria'] != null)
                                Text('Categoria: ${alimento['categoria']}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showFoodDetails(alimento);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child:
                            Text('Nenhum alimento encontrado para esta busca.'),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Erro na busca
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _foodSearchResult!['error'] ?? 'Erro desconhecido',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mostrar detalhes de um alimento
  void _showFoodDetails(Map<String, dynamic> alimento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alimento['nome'] ?? 'Alimento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alimento['categoria'] != null) ...[
                _buildDetailRow('Categoria', alimento['categoria']),
                const SizedBox(height: 8),
              ],
              if (alimento['calorias'] != null) ...[
                _buildDetailRow('Calorias', '${alimento['calorias']} kcal'),
                const SizedBox(height: 8),
              ],
              if (alimento['proteinas'] != null) ...[
                _buildDetailRow('Proteínas', '${alimento['proteinas']} g'),
                const SizedBox(height: 8),
              ],
              if (alimento['carboidratos'] != null) ...[
                _buildDetailRow(
                    'Carboidratos', '${alimento['carboidratos']} g'),
                const SizedBox(height: 8),
              ],
              if (alimento['gordura'] != null) ...[
                _buildDetailRow('Gordura', '${alimento['gordura']} g'),
                const SizedBox(height: 8),
              ],
              if (alimento['fibra'] != null) ...[
                _buildDetailRow('Fibra', '${alimento['fibra']} g'),
                const SizedBox(height: 8),
              ],
              if (alimento['codigo'] != null) ...[
                _buildDetailRow('Código TACO', alimento['codigo']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Aqui você pode implementar ação para adicionar o alimento
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${alimento['nome']} selecionado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }

  /// Helper para construir linhas de detalhes
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
