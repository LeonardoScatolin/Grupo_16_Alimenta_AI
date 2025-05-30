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
  @override
  void initState() {
    super.initState();
    // Configure sua API key da OpenAI aqui ou no arquivo de configuração
    // context.read<AudioService>().setOpenAIApiKey('sua_api_key_aqui');
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
