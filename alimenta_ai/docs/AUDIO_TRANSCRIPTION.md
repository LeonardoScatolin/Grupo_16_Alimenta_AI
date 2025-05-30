# Serviço de Transcrição de Áudio com OpenAI

Este serviço integra gravação de áudio com transcrição automática usando a API Whisper da OpenAI.

## Configuração

### 1. API Key da OpenAI

1. Acesse [OpenAI Platform](https://platform.openai.com/api-keys)
2. Crie uma nova API key
3. Configure a API key no arquivo `lib/config/openai_config.dart`:

```dart
class OpenAIConfig {
  static const String apiKey = 'sk-proj-...'; // Sua API key aqui
  // ... resto das configurações
}
```

### 2. Dependências

As seguintes dependências foram adicionadas ao `pubspec.yaml`:

- `dio: ^5.4.0` - Para requisições HTTP
- `mime: ^1.0.4` - Para detecção de tipos de arquivo

### 3. Permissões

Certifique-se de que as permissões de microfone estão configuradas:

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Este app precisa acessar o microfone para gravar áudio</string>
```

## Como Usar

### 1. AudioService

O `AudioService` agora inclui transcrição automática:

```dart
final audioService = Provider.of<AudioService>(context);

// Configurar API key (opcional, se não estiver no config)
audioService.setOpenAIApiKey('sua_api_key');

// Gravar áudio
await audioService.startRecording();
await audioService.stopRecording(); // Automaticamente transcreve

// Acessar transcrição
String? transcricao = audioService.lastTranscription;
```

### 2. Tela de Demonstração

Acesse a tela de demonstração através da rota `/audio-transcription`:

```dart
Navigator.pushNamed(context, '/audio-transcription');
```

### 3. Fluxo Completo

1. **Gravar**: Clique em "Gravar" para iniciar a gravação
2. **Parar**: Clique em "Parar" para finalizar (inicia transcrição automática)
3. **Aguardar**: A transcrição é processada pela OpenAI automaticamente
4. **Resultado**: O texto transcrito aparece na tela
5. **Enviar**: Use o botão "Enviar para Backend" para processar o texto

## Características

### ✅ Funcionalidades Implementadas

- Gravação de áudio em formato WAV
- Transcrição automática após gravação
- Interface visual com status em tempo real
- Configuração dinâmica de API key
- Reprodução do áudio gravado
- Limpeza de arquivos temporários
- Tratamento de erros completo

### 🎯 Configurações da OpenAI

- **Modelo**: `whisper-1`
- **Idioma**: Português (`pt`)
- **Temperatura**: `0.0` (máxima precisão)
- **Formato**: Texto simples ou JSON detalhado
- **Timeout**: 30s conexão, 60s recebimento

### 📱 Compatibilidade

- ✅ Android
- ✅ iOS  
- ✅ Windows
- ✅ Web (limitado)

## API da OpenAI

### Endpoint Usado
```
POST https://api.openai.com/v1/audio/transcriptions
```

### Parâmetros
- `file`: Arquivo de áudio (WAV)
- `model`: whisper-1
- `language`: pt
- `response_format`: text ou verbose_json
- `temperature`: 0.0

### Custos
Consulte [OpenAI Pricing](https://openai.com/pricing) para custos atuais da API Whisper.

## Resolução de Problemas

### Erro de Permissão
- Verifique se as permissões de microfone estão configuradas
- Teste em dispositivo real (microfone pode não funcionar no simulador)

### Erro de API Key
- Verifique se a API key está correta
- Confirme se há créditos na conta OpenAI

### Erro de Conectividade
- Verifique conexão com internet
- Teste em rede diferente se necessário

## Próximos Passos

1. **Integração com Backend**: Enviar transcrição para seu servidor
2. **Cache Local**: Armazenar transcrições localmente
3. **Múltiplos Idiomas**: Suporte a outros idiomas
4. **Compressão**: Otimizar arquivos de áudio antes do envio
5. **Batch Processing**: Processar múltiplos áudios

## Estrutura de Arquivos

```
lib/
├── config/
│   └── openai_config.dart          # Configurações da OpenAI
├── services/
│   ├── audio_service.dart          # Serviço principal de áudio
│   └── openai_service.dart         # Cliente da API OpenAI
└── pages/
    └── audio_transcription_page.dart # Tela de demonstração
```

## 🆕 Melhorias v2.0 - Armazenamento Persistente

### Novos Recursos Implementados

#### 🔧 Sistema de Armazenamento Aprimorado
- **Diretórios Persistentes**: Áudios agora são salvos em locais permanentes específicos por plataforma
- **Limpeza Automática**: Manutenção automática dos arquivos (mantém últimos 10 áudios)
- **Verificação de Integridade**: Sistema verifica se arquivos foram criados corretamente
- **Diagnóstico Completo**: Health check do sistema de áudio

#### 📂 Locais de Armazenamento por Plataforma
- **Windows**: `%USERPROFILE%\alimenta_ai_audios\`
- **Android**: `Application Documents/audios/`
- **iOS**: `Application Documents/audios/`
- **Outros**: Diretório temporário do sistema

#### 🏥 Sistema de Diagnóstico
```dart
// Verificar saúde do sistema de áudio
final audioService = Provider.of<AudioService>(context);
final health = await audioService.checkAudioSystemHealth();

// Retorna informações sobre:
// - Permissões de microfone
// - Configuração da OpenAI
// - Acesso ao armazenamento
// - Quantidade de arquivos salvos
// - Plataforma atual
```

#### 🛠️ Novos Métodos no AudioService
```dart
// Listar arquivos de áudio armazenados
List<String> files = await audioService.getStoredAudioFiles();

// Limpar arquivos antigos
await audioService.cleanOldAudioFiles();

// Verificar saúde do sistema
Map<String, dynamic> health = await audioService.checkAudioSystemHealth();
```

#### 🎨 Widget de Debug
Novo widget `AudioDebugWidget` para monitoramento visual:
- Exibe status do sistema em tempo real
- Permite limpeza manual de arquivos
- Mostra informações de diagnóstico
- Indicadores visuais de problemas

### Solução para Problemas de Armazenamento

O erro "ENOENT: no such file or directory" foi resolvido com:

1. **Criação de Diretórios Permanentes**: Sistema cria automaticamente diretórios específicos
2. **Verificação de Arquivos**: Validação antes do envio para o backend
3. **Backup e Recuperação**: Sistema de fallback para diretórios alternativos
4. **Logs Detalhados**: Rastreamento completo do ciclo de vida dos arquivos

### Como Usar as Novas Funcionalidades

```dart
// Na sua página, adicione o widget de debug
import 'package:alimenta_ai/widgets/audio_debug_widget.dart';

// No build method:
Column(
  children: [
    AudioDebugWidget(), // Widget de diagnóstico
    // ... resto da sua UI
  ],
)
```
