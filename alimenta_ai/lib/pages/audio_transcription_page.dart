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
                          ),

                          // Botões de ação na transcrição
                          if (audioService.lastTranscription != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Aqui você pode enviar a transcrição para o backend
                                    _sendTranscriptionToBackend(
                                        audioService.lastTranscription!);
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Enviar para Backend'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    audioService.clearTranscription();
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpar'),
                                ),
                              ],
                            ),
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
  }

  // Método para enviar transcrição para o backend
  void _sendTranscriptionToBackend(String transcription) {
    // TODO: Implementar envio para o backend
    debugPrint('📤 Enviando transcrição para backend: $transcription');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Transcrição enviada: ${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
