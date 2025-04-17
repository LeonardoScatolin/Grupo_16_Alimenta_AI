import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  AppBar appbar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Notificações',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffF7F8F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert_rounded, color: Colors.black, size: 20),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appbar(context),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: 3,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            color: Color(0xffDDDADA),
            thickness: 1.0,
            indent: 20,
            endIndent: 20,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          String titulo = '';
          String subtitulo = '';
          String imagem = '';

          if (index == 0) {
            titulo = 'Oba! É hora do Almoço';
            subtitulo = '1 minuto atrás';
            imagem = 'assets/icons/lanches.svg';
          } else if (index == 1) {
            titulo = 'Hey, Vamos adicionar o café da manhã?';
            subtitulo = '3 horas atrás';
            imagem = 'assets/icons/pancakes.svg';
          } else if (index == 2) {
            titulo = 'Almoçoo! Não decepcione sua Nutri!';
            subtitulo = '1 hora atrás';
            imagem = 'assets/icons/plate.svg';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset(
                    imagem,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}