import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/translator_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/picture_translator_screen.dart';
import 'utils/constants.dart';

// Futuristic color palette (matching all screens)
class _F {
  static const Color bg = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F1522);
  static const Color amber = Color(0xFFF5A623);
  static const Color orange = Color(0xFFE8632A);
  static const Color green = Color(0xFF3DDC84);
  static const Color red = Color(0xFFFF4D4D);
  static const Color t1 = Color(0xFFF2E8D5);
  static const Color t2 = Color(0xFF7A8BAA);
  static const Color border = Color(0x22F5A623);

  static LinearGradient get span => const LinearGradient(
        colors: [amber, orange],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
  static LinearGradient get spanV => const LinearGradient(
        colors: [amber, orange],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
  static BoxShadow get amberGlow => const BoxShadow(
      color: Color(0x40F5A623), blurRadius: 20, spreadRadius: 1);
  static BoxShadow get orangeGlow => const BoxShadow(
      color: Color(0x40E8632A), blurRadius: 20, spreadRadius: 1);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  runApp(const MLTranslatorApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.microphone,
    Permission.camera,
    Permission.storage,
  ].request();
}

class MLTranslatorApp extends StatelessWidget {
  const MLTranslatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _F.bg,
        colorScheme: const ColorScheme.dark(
          primary: _F.amber,
          secondary: _F.orange,
          surface: _F.surface,
          background: _F.bg,
          onSurface: _F.t1,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: _F.t1,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: _F.t1,
            fontFamily: 'monospace',
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _F.t1),
          bodyMedium: TextStyle(color: _F.t1),
          titleLarge: TextStyle(color: _F.t1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _F.amber,
            foregroundColor: _F.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: _F.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _F.border),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _glowController;

  final List<Widget> _screens = [
    const TranslatorScreen(),
    const ConversationScreen(),
    const PictureTranslatorScreen(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(Icons.translate_outlined, Icons.translate, 'TRANSLATE'),
    NavigationItem(
        Icons.chat_bubble_outline, Icons.chat_bubble, 'CONVERSATION'),
    NavigationItem(Icons.camera_alt_outlined, Icons.camera_alt, 'PICTURE'),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _F.bg,
      body: Stack(
        children: [
          // Futuristic background with radial gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  _F.surface,
                  _F.bg,
                ],
              ),
            ),
          ),
          // Animated glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.6,
                  colors: [
                    _F.amber.withOpacity(0.05 + _glowController.value * 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content with SafeArea to avoid notch and system bars
          SafeArea(
            child: Column(
              children: [
                _buildFuturisticHeader(),
                Expanded(
                  child: _screens[_currentIndex],
                ),
                // Add bottom padding to avoid overlap with system navigation
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: _buildFuturisticBottomNav(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Animated logo
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: _F.span,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        _F.amber.withOpacity(0.3 + _glowController.value * 0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.translate,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => _F.span.createShader(b),
                child: const Text(
                  'BRIDGO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Text(
                'BRIDGE · LANGUAGE · GO',
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 2,
                  color: _F.t2,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Spacer(),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _F.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _F.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _F.green, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'READY',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1,
                    color: _F.t2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _F.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _F.border),
        boxShadow: [
          BoxShadow(
            color: _F.amber.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (index) {
          final isSelected = _currentIndex == index;
          final item = _navItems[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          _F.amber.withOpacity(0.2),
                          _F.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? Border.all(
                        color: _F.amber.withOpacity(0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? _F.amber : _F.t2,
                    size: 20,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: _F.amber,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem(this.icon, this.activeIcon, this.label);
}
