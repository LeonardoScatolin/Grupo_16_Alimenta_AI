import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:alimenta_ai/theme/theme_provider.dart';
import 'package:alimenta_ai/services/user_service.dart';
import 'package:alimenta_ai/pages/chat_nutricionista.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  String _userName = 'Usuário'; // Nome padrão caso não carregue

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Método para carregar o nome do usuário
  void _loadUserName() async {
    try {
      final userName = await UserService.getUserName();
      if (userName != null) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (e) {
      print('Erro ao carregar nome do usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0.0,
          leading: IconButton(
            icon: SvgPicture.asset(
              themeProvider.isDarkMode 
                ? 'assets/icons/seta-white.svg'
                : 'assets/icons/seta-black.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                color: Theme.of(context).colorScheme.onSurface,
                width: 24,
                height: 24,
              ),
              onPressed: () => _showSettingsModal(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(child: _buildProfileSection()),
                  const SizedBox(height: 30),
                  _buildInformationSection(),
                  const SizedBox(height: 20),
                  _buildNotificationSection(),
                  const SizedBox(height: 20),
                  _buildOthersSection(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    });
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto de perfil com círculo gradiente
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff92A3FD).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 15),              // Nome do usuário
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 5), // Título do usuário
              Text(
                'Nutricionista Nutrime',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informações'),
        _buildMenuCard(
          icon: Icons.person_outline,
          title: 'Dados do Nutricionista',
          onTap: () => _showNutritionistPopup(context),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notificação'),        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            elevation: 2,
            shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Theme.of(context).brightness == Brightness.dark
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xff92A3FD).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_outlined,
                            color: Color(0xff92A3FD),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Notificações',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      activeColor: const Color(0xff92A3FD),
                      activeTrackColor: const Color(0xff92A3FD).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOthersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Outros'),        _buildMenuCard(
          icon: Icons.chat_outlined,
          title: 'Contato com Nutricionista',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatNutricionista(),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xff92A3FD).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: const Color(0xff92A3FD),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );  }

  Widget _buildBottomNavigationBar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode 
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            border: themeProvider.isDarkMode 
              ? Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: 'assets/icons_bar/Home-Active.svg',
                isActive: false,
                onTap: () => Navigator.pushNamed(context, '/home'),
              ),
              _buildAddButton(),
              _buildNavItem(
                icon: 'assets/icons_bar/Profile.svg',
                isActive: true,
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildNavItem({
    required String icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? const Color(0xff92A3FD)
                      : (themeProvider.isDarkMode 
                          ? Colors.grey[400]!
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
                placeholderBuilder: (BuildContext context) => SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(
                      Icons.error,
                      size: 20,
                      color: themeProvider.isDarkMode 
                        ? Colors.grey[400]
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }  Widget _buildAddButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/registra-alimento'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    colors: [Color(0xFF7A66EC), Color(0xFF5D42D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                    ? const Color(0xFF7A66EC).withOpacity(0.3)
                    : const Color(0xff92A3FD).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons_bar/plus.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
                placeholderBuilder: (BuildContext context) => const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(Icons.add, size: 24, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNutritionistPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff92A3FD).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xff92A3FD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Informações do Nutricionista',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff92A3FD),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nutritionist info
                  _buildInfoRow(Icons.person, 'Nome', 'Dr. Carlos'),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.email, 'Email', 'carlos@nutrialimenta.com'),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.phone, 'Telefone', '(11) 98765-4321'),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.location_on, 'Endereço',
                      'Av. Paulista, 1000 - São Paulo'),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.schedule, 'Horário', 'Segunda à Sexta, 9h às 18h'),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xff92A3FD)),
                        ),
                        child: const Text(
                          'Fechar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          // Navigate to chat or contact screen
                          Navigator.of(context).pop();
                          // Navigator.pushNamed(context, '/chat-nutricionista');
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xff92A3FD)),
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                        child: const Text(
                          'Entrar em Contato',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xff92A3FD),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Método para alternar o tema
  void toggleTheme() {
    context.read<ThemeProvider>().toggleTheme();
  }  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Deixamos transparente para controlar dentro do Consumer
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabeçalho
                    Row(
                      children: [
                        Text(
                          'Configurações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),

                    // Tema
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ListTile(
                        leading: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          themeProvider.isDarkMode ? 'Tema Escuro' : 'Tema Claro',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          activeColor: Theme.of(context).colorScheme.primary,
                          activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Logout
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ListTile(
                        leading: SvgPicture.asset(
                          'assets/icons/logout.svg',
                          width: 24,
                          height: 24,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Sair',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }
}
