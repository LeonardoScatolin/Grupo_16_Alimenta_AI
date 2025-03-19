class ModeloDieta {
  String name;
  String iconPath;
  String duracao;
  String calorias;
  bool viewIsSelected;

  ModeloDieta(
      {required this.name,
      required this.iconPath,
      required this.duracao,
      required this.calorias,
      required this.viewIsSelected});

  get boxColor => null;

  static List<ModeloDieta> getDietas() {
    List<ModeloDieta> dietas = [];

    dietas.add(ModeloDieta(
        name: 'Café da Manhã',
        iconPath: 'assets/icons/pancakes.svg',
        duracao: '10min',
        calorias: '200KCal',
        viewIsSelected: true));

    dietas.add(
      ModeloDieta(
          name: 'Jantar',
          iconPath: 'assets/icons/janta.svg',
          duracao: '10min',
          calorias: '200KCal',
          viewIsSelected: false));

    dietas.add(ModeloDieta(
        name: 'Almoço',
        iconPath: 'assets/icons/plate.svg',
        duracao: '10min',
        calorias: '200KCal',
        viewIsSelected: false));


  return dietas;
  }
}
