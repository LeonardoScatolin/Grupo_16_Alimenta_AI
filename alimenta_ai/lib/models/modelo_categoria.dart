import 'package:flutter/material.dart';

class ModeloCategoria {
  String name;
  String iconPath;
  Color boxColor;

  ModeloCategoria({
    required this.name,
    required this.iconPath,
    required this.boxColor
  }); 

  static List<ModeloCategoria> getCategorias(){
    List<ModeloCategoria> categorias = [];

    categorias.add(
      ModeloCategoria(
        name: 'Almoço',
        iconPath: 'assets/icons/plate.svg',
        boxColor: const Color(0xff92A3FD)
      )
    );

     categorias.add(
      ModeloCategoria(
        name: 'Café Matinal',
        iconPath: 'assets/icons/pancakes.svg',
        boxColor: const Color(0xffC58BF2)
      )
    );

     categorias.add(
      ModeloCategoria(
        name: 'Lanches',
        iconPath: 'assets/icons/lanches.svg',
        boxColor: const Color(0xff92A3FD)
      )
    );

     categorias.add(
      ModeloCategoria(
        name: 'Jantar',
        iconPath: 'assets/icons/janta.svg',
        boxColor: const Color(0xffC58BF2)
      )
    );

    return categorias;
  }
}
