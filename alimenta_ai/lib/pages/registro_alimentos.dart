import 'package:alimenta_ai/models/modelo_categoria.dart';
import 'package:alimenta_ai/models/ver_dietanutri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ModeloCategoria> categorias = [];
  List<ModeloDieta> dietas = [];

  // Variável para controlar o estado de gravação e reprodução
  bool isRecording = false;
  bool isPlayingAudio = false;
  bool hasRecordedAudio = false;
  // Controlador de animação para o botão de microfone
  double micButtonOffset = 0;
  // FocusNode para controlar o foco do TextField
  late FocusNode textFieldFocus;
  // Variáveis para controlar o tempo de gravação
  int recordingDuration = 0;
  late Timer? recordingTimer;

  @override
  void initState() {
    super.initState();
    textFieldFocus = FocusNode();
    getInitialInfo();
    recordingTimer = null;
  }

  @override
  void dispose() {
    textFieldFocus.dispose();
    stopRecordingTimer();
    super.dispose();
  }

  // Inicia o timer de gravação
  void startRecordingTimer() {
    recordingDuration = 0;
    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        recordingDuration++;
      });
    });
  }

  // Para o timer de gravação
  void stopRecordingTimer() {
    recordingTimer?.cancel();
    recordingTimer = null;
  }

  // Formata o tempo de gravação para exibição
  String get formattedRecordingTime {
    final minutes = (recordingDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void getInitialInfo() {
    categorias = ModeloCategoria.getCategorias();
    dietas = ModeloDieta.getDietas();
  }

  // Simula a reprodução do áudio gravado
  void playRecordedAudio() {
    setState(() {
      isPlayingAudio = true;
    });
    // Simula o tempo de reprodução (usando o mesmo tempo da gravação)
    Timer(Duration(seconds: recordingDuration), () {
      setState(() {
        isPlayingAudio = false;
      });
    });
  }

  // Função para deletar o áudio gravado
  void deleteRecordedAudio() {
    setState(() {
      hasRecordedAudio = false;
      recordingDuration = 0;
      isPlayingAudio = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField(),
          const SizedBox(
            height: 40,
          ),
          sessaoCategoria(),
          const SizedBox(
            height: 40,
          ),
          dietasNutri(),
          searchIAField()
        ],
      ),
      // FloatingActionButton removido
    );
  }

  Container searchIAField() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D1617).withOpacity(0.11),
            blurRadius: 40,
            spreadRadius: 0.0,
          )
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Botão de microfone ou play
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Row(
                  children: [
                    // Microfone/Play botão
                    GestureDetector(
                      onTap: hasRecordedAudio && !isRecording && !isPlayingAudio
                          ? () {
                              // Reproduz o áudio gravado quando clica no microfone após ter gravado
                              playRecordedAudio();
                            }
                          : null,
                      child: Listener(
                        onPointerDown: !hasRecordedAudio && !isPlayingAudio
                            ? (event) {
                                setState(() {
                                  micButtonOffset = -10;
                                  isRecording = true;
                                  // Inicia o timer de gravação
                                  startRecordingTimer();
                                });
                              }
                            : null,
                        onPointerUp: !hasRecordedAudio && isRecording
                            ? (event) {
                                setState(() {
                                  micButtonOffset =
                                      0; // Volta à posição original
                                  isRecording = false;
                                  hasRecordedAudio = true;
                                  // Para o timer de gravação
                                  stopRecordingTimer();
                                });
                              }
                            : null,
                        onPointerCancel: isRecording
                            ? (event) {
                                setState(() {
                                  micButtonOffset = 0;
                                  isRecording = false;
                                  // Para o timer de gravação
                                  stopRecordingTimer();
                                });
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform:
                              Matrix4.translationValues(0, micButtonOffset, 0),
                          child: hasRecordedAudio &&
                                  !isRecording &&
                                  !isPlayingAudio
                              ? const Icon(
                                  Icons.play_arrow,
                                  color: Color(0xff92A3FD),
                                  size: 28,
                                )
                              : SvgPicture.asset(
                                  'assets/icons/mic.svg',
                                  color: isRecording
                                      ? const Color(0xff92A3FD)
                                      : isPlayingAudio
                                          ? Colors.green
                                          : null,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Indicador de status (gravando, reproduzindo ou hint)
                    Expanded(
                      child: isRecording || isPlayingAudio
                          ? Row(
                              children: [
                                // Tempo de gravação/reprodução
                                Text(
                                  formattedRecordingTime,
                                  style: const TextStyle(
                                    color: Color(0xff92A3FD),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isRecording
                                        ? 'Gravando...'
                                        : 'Reproduzindo...',
                                    style: const TextStyle(
                                      color: Color(0xff92A3FD),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              hasRecordedAudio
                                  ? 'Áudio gravado'
                                  : 'Pressione para falar',
                              style: TextStyle(
                                color: hasRecordedAudio
                                    ? const Color(0xff92A3FD)
                                    : const Color(0xffDDDADA),
                                fontSize: 14,
                              ),
                            ),
                    ),
                    // Botão para deletar o áudio (aparece apenas quando tem áudio gravado)
                    if (hasRecordedAudio && !isRecording && !isPlayingAudio)
                      GestureDetector(
                        onTap: () {
                          deleteRecordedAudio();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Botão de enviar
            Container(
              margin: const EdgeInsets.all(5),
              width: 50,
              child: Row(
                children: [
                  Container(
                    width: 1,
                    height: 30,
                    color: const Color(0xFFEEEEEE),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap:
                            hasRecordedAudio && !isRecording && !isPlayingAudio
                                ? () {
                                    // Lógica para enviar o áudio gravado
                                    setState(() {
                                      // Após enviar, resetamos o estado
                                      hasRecordedAudio = false;
                                      recordingDuration = 0;
                                    });
                                  }
                                : null,
                        child: SvgPicture.asset(
                          'assets/icons/enviar.svg',
                          color: hasRecordedAudio &&
                                  !isRecording &&
                                  !isPlayingAudio
                              ? null // Cor normal quando ativo
                              : Colors
                                  .grey, // Desabilita o botão se não houver áudio gravado
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column dietasNutri() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Cardápio do(a)\nNutri:',
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                width: 210,
                decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: dietas[index].boxColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SvgPicture.asset(dietas[index].iconPath),
                    Text(
                      dietas[index].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${dietas[index].duracao} | ${dietas[index].calorias}',
                      style: const TextStyle(
                          color: Color(0xff7B6F72),
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                    ),
                    Container(
                      height: 45,
                      width: 130,
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xff9DCEFF), Color(0xff92A3FD)]),
                          borderRadius: BorderRadius.circular(50)),
                      child: const Center(
                        child: Text(
                          'Ver',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(
              width: 25,
            ),
            itemCount: dietas.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 20),
          ),
        )
      ],
    );
  }

  Column sessaoCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'Refeições',
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            itemCount: categorias.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 20),
            separatorBuilder: (context, index) => const SizedBox(
              width: 25,
            ),
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: categorias[index].boxColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(categorias[index].iconPath),
                      ),
                    ),
                    Text(
                      categorias[index].name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          fontSize: 14),
                    )
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Container searchField() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            // ignore: deprecated_member_use
            color: const Color(0xff1D1617).withOpacity(0.11),
            blurRadius: 40,
            spreadRadius: 0.0)
      ]),
      child: TextField(
        focusNode: textFieldFocus,
        decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(15),
            hintText: 'Procurar Alimento',
            hintStyle: const TextStyle(color: Color(0xffDDDADA), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset('assets/icons/Search.svg'),
            ),
            suffixIcon: SizedBox(
              width: 100,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const VerticalDivider(
                      color: Colors.black,
                      indent: 10,
                      endIndent: 10,
                      thickness: 0.1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset('assets/icons/Filter.svg'),
                    ),
                  ],
                ),
              ),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none)),
      ),
    );
  }

  AppBar appbar() {
    return AppBar(
      title: const Text(
        'Registrar Refeição',
        style: TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pushNamed(
            context, '/home'), // Modifica navegação para a tela de dashboard
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10)),
          child: SvgPicture.asset(
            'assets/icons/seta_esquerda.svg',
            height: 20,
            width: 20,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(10),
            alignment: Alignment.center,
            width: 37,
            decoration: BoxDecoration(
                color: const Color(0xffF7F8F8),
                borderRadius: BorderRadius.circular(10)),
            child: SvgPicture.asset(
              'assets/icons/dots.svg',
              height: 5,
              width: 5,
            ),
          ),
        )
      ],
    );
  }
}
