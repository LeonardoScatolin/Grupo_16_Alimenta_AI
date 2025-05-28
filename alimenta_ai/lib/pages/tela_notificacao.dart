import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  final List<Map<String, String>> notificacoes = const [
    {
      'titulo': 'Oba! É hora do Almoço',
      'subtitulo': '1 minuto atrás',
      'imagem': 'assets/icons/lanches.svg',
    },
    {
      'titulo': 'Hey, Vamos adicionar o café da manhã?',
      'subtitulo': '3 horas atrás',
      'imagem': 'assets/icons/pancakes.svg',
    },
    {
      'titulo': 'Almoçoo! Não decepcione sua Nutri!',
      'subtitulo': '1 hora atrás',
      'imagem': 'assets/icons/plate.svg',
    },
  ];

  AppBar appbar(BuildContext context) {
    return AppBar(
      title: Text(
        'Notificações',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: appbar(context),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: notificacoes.length,
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xffDDDADA),
          thickness: 1.0,
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          final item = notificacoes[index];
          return NotificationItem(
            titulo: item['titulo']!,
            subtitulo: item['subtitulo']!,
            imagem: item['imagem']!,
          );
        },
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String imagem;

  const NotificationItem({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.imagem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: SvgPicture.asset(imagem),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
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
            const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
