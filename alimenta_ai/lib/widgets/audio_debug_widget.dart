import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alimenta_ai/services/audio_service.dart';

/// Widget para exibir informações de debug do sistema de áudio
class AudioDebugWidget extends StatefulWidget {
  const AudioDebugWidget({super.key});

  @override
  State<AudioDebugWidget> createState() => _AudioDebugWidgetState();
}

class _AudioDebugWidgetState extends State<AudioDebugWidget> {
  Map<String, dynamic>? _healthCheck;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _performHealthCheck();
  }

  Future<void> _performHealthCheck() async {
    final audioService = context.read<AudioService>();
    final health = await audioService.checkAudioSystemHealth();
    setState(() {
      _healthCheck = health;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_healthCheck == null) {
      return const SizedBox.shrink();
    }

    final hasIssues = !_healthCheck!['permissions'] ||
        !_healthCheck!['openai_configured'] ||
        _healthCheck!.containsKey('error');

    return Card(
      margin: const EdgeInsets.all(8),
      color: hasIssues ? Colors.red.shade50 : Colors.green.shade50,
      child: ExpansionTile(
        leading: Icon(
          hasIssues ? Icons.warning : Icons.check_circle,
          color: hasIssues ? Colors.red : Colors.green,
        ),
        title: Text(
          hasIssues
              ? 'Sistema de Áudio - Problemas Detectados'
              : 'Sistema de Áudio - OK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasIssues ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
        subtitle: Text(
          'Toque para ${_isExpanded ? 'ocultar' : 'ver'} detalhes',
        ),
        initiallyExpanded: hasIssues,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHealthRow(
                  'Permissões de Microfone',
                  _healthCheck!['permissions'],
                  Icons.mic,
                ),
                _buildHealthRow(
                  'OpenAI Configurado',
                  _healthCheck!['openai_configured'],
                  Icons.smart_toy,
                ),
                _buildHealthRow(
                  'Acesso ao Armazenamento',
                  _healthCheck!['storage_accessible'],
                  Icons.folder,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text('Plataforma: ${_healthCheck!['platform']}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.audiotrack,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                        'Áudios salvos: ${_healthCheck!['stored_files_count']}'),
                  ],
                ),
                if (_healthCheck!.containsKey('error')) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Erro: ${_healthCheck!['error']}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _performHealthCheck,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_healthCheck!['stored_files_count'] > 0)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final audioService = context.read<AudioService>();
                          await audioService.cleanOldAudioFiles();
                          await _performHealthCheck();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Arquivos antigos removidos!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Limpar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, bool isHealthy, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            size: 16,
            color: isHealthy ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Icon(iconData, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            isHealthy ? 'OK' : 'ERRO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHealthy ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
