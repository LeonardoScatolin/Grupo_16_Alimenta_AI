import 'package:flutter/material.dart';

class ModeloDieta {
  String name;
  String iconPath;
  String duracao;
  String calorias;
  bool viewIsSelected;
  Color boxColor;
  

  ModeloDieta(
      {required this.name,
      required this.iconPath,
      required this.duracao,
      required this.calorias,
      required this.viewIsSelected,
      required this.boxColor
      });



  static List<ModeloDieta> getDietas() {
    List<ModeloDieta> dietas = [];

    dietas.add(ModeloDieta(
        name: 'Café da Manhã',
        iconPath: 'assets/icons/pancakesGrande.svg',
        duracao: '10min',
        calorias: '200KCal',
        viewIsSelected: true,
        boxColor: const Color(0xff92A3FD)
        ));

    dietas.add(ModeloDieta(
        name: 'Jantar',
        iconPath: 'assets/icons/jantaGrande.svg',
        duracao: '10min',
        calorias: '200KCal',
        viewIsSelected: false,
        boxColor: const Color(0xffC58BF2)
        ));

    dietas.add(ModeloDieta(
        name: 'Almoço',
        iconPath: 'assets/icons/plateGrande.svg',
        duracao: '10min',
        calorias: '200KCal',
        viewIsSelected: false,
        boxColor: const Color(0xff92A3FD)
        ));

    return dietas;
  }
}
