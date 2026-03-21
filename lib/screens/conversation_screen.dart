import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../utils/constants.dart';

// Futuristic color palette
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

// Futuristic waveform painter
class _WaveformPainter extends CustomPainter {
  final double phase;
  final Color color;
  _WaveformPainter(this.phase, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bars = 20;
    final barWidth = size.width / bars;

    for (int i = 0; i < bars; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude =
          size.height * (0.2 + 0.8 * math.sin(phase + i * 0.5).abs());
      paint.color = color.withOpacity(0.3 + 0.7 * (i / bars));
      canvas.drawLine(
        Offset(x, size.height / 2 - amplitude / 2),
        Offset(x, size.height / 2 + amplitude / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.phase != phase || old.color != color;
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({Key? key}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with TickerProviderStateMixin {
  final GoogleTranslator _translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  Language _user1Lang = Language('en', 'English');
  Language _user2Lang = Language('es', 'Spanish');

  final TextEditingController _user1Controller = TextEditingController();
  final TextEditingController _user2Controller = TextEditingController();

  bool _isUser1Listening = false;
  bool _isUser2Listening = false;
  bool _isUser1Speaking = false;
  bool _isUser2Speaking = false;
  bool _isTranslating = false;

  late AnimationController _waveController;
  late AnimationController _glowController;

  List<ConversationMessage> _messages = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  Future<void> _translateUser1ToUser2() async {
    if (_user1Controller.text.isEmpty) {
      _user2Controller.clear();
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translation = await _translator.translate(
        _user1Controller.text,
        from: _user1Lang.code,
        to: _user2Lang.code,
      );

      setState(() {
        _user2Controller.text = translation.text;
        _isTranslating = false;
        _addMessage(
          fromPerson: 'Person 1',
          originalText: _user1Controller.text,
          fromLang: _user1Lang,
          toPerson: 'Person 2',
          translatedText: translation.text,
          toLang: _user2Lang,
          isFromUser1: true,
        );
      });

      await _speakToUser2(translation.text);
    } catch (e) {
      setState(() => _isTranslating = false);
      _showError('Translation failed');
    }
  }

  Future<void> _translateUser2ToUser1() async {
    if (_user2Controller.text.isEmpty) {
      _user1Controller.clear();
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translation = await _translator.translate(
        _user2Controller.text,
        from: _user2Lang.code,
        to: _user1Lang.code,
      );

      setState(() {
        _user1Controller.text = translation.text;
        _isTranslating = false;
        _addMessage(
          fromPerson: 'Person 2',
          originalText: _user2Controller.text,
          fromLang: _user2Lang,
          toPerson: 'Person 1',
          translatedText: translation.text,
          toLang: _user1Lang,
          isFromUser1: false,
        );
      });

      await _speakToUser1(translation.text);
    } catch (e) {
      setState(() => _isTranslating = false);
      _showError('Translation failed');
    }
  }

  void _addMessage({
    required String fromPerson,
    required String originalText,
    required Language fromLang,
    required String toPerson,
    required String translatedText,
    required Language toLang,
    required bool isFromUser1,
  }) {
    _messages.insert(
      0,
      ConversationMessage(
        fromPerson: fromPerson,
        originalText: originalText,
        fromLang: fromLang,
        toPerson: toPerson,
        translatedText: translatedText,
        toLang: toLang,
        timestamp: DateTime.now(),
        isFromUser1: isFromUser1,
      ),
    );

    if (_messages.length > 50) {
      _messages.removeLast();
    }
  }

  void _listenUser1() async {
    if (!_isUser1Listening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isUser1Listening = true;
          _isTranslating = false;
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _user1Controller.text = val.recognizedWords;
            });
            if (val.finalResult) {
              _translateUser1ToUser2();
              setState(() => _isUser1Listening = false);
            }
          },
          localeId: _user1Lang.code,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
        );
      }
    } else {
      setState(() => _isUser1Listening = false);
      _speech.stop();
    }
  }

  void _listenUser2() async {
    if (!_isUser2Listening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isUser2Listening = true;
          _isTranslating = false;
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _user2Controller.text = val.recognizedWords;
            });
            if (val.finalResult) {
              _translateUser2ToUser1();
              setState(() => _isUser2Listening = false);
            }
          },
          localeId: _user2Lang.code,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
        );
      }
    } else {
      setState(() => _isUser2Listening = false);
      _speech.stop();
    }
  }

  Future<void> _speakToUser1(String text) async {
    if (text.isNotEmpty) {
      setState(() => _isUser1Speaking = true);
      await _flutterTts.setLanguage(_user1Lang.code);
      await _flutterTts.speak(text);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isUser1Speaking = false);
    }
  }

  Future<void> _speakToUser2(String text) async {
    if (text.isNotEmpty) {
      setState(() => _isUser2Speaking = true);
      await _flutterTts.setLanguage(_user2Lang.code);
      await _flutterTts.speak(text);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isUser2Speaking = false);
    }
  }

  void _speakUser1Original() async {
    if (_user1Controller.text.isNotEmpty) {
      await _flutterTts.setLanguage(_user1Lang.code);
      await _flutterTts.speak(_user1Controller.text);
    }
  }

  void _speakUser2Original() async {
    if (_user2Controller.text.isNotEmpty) {
      await _flutterTts.setLanguage(_user2Lang.code);
      await _flutterTts.speak(_user2Controller.text);
    }
  }

  void _swapLanguages() {
    HapticFeedback.lightImpact();
    setState(() {
      final tempLang = _user1Lang;
      _user1Lang = _user2Lang;
      _user2Lang = tempLang;

      final tempText = _user1Controller.text;
      _user1Controller.text = _user2Controller.text;
      _user2Controller.text = tempText;
    });
  }

  void _clearMessages() {
    HapticFeedback.lightImpact();
    setState(() {
      _messages.clear();
      _user1Controller.clear();
      _user2Controller.clear();
      _isTranslating = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: _F.red, size: 18),
          const SizedBox(width: 8),
          Text(message, style: const TextStyle(fontFamily: 'monospace')),
        ]),
        backgroundColor: _F.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _F.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectLanguageForUser1() async {
    final selected = await showDialog<Language>(
      context: context,
      builder: (context) => _buildFuturisticLanguagePicker(),
    );

    if (selected != null && selected.code != _user2Lang.code) {
      setState(() => _user1Lang = selected);
    } else if (selected != null && selected.code == _user2Lang.code) {
      _showError('Cannot select the same language');
    }
  }

  Future<void> _selectLanguageForUser2() async {
    final selected = await showDialog<Language>(
      context: context,
      builder: (context) => _buildFuturisticLanguagePicker(),
    );

    if (selected != null && selected.code != _user1Lang.code) {
      setState(() => _user2Lang = selected);
    } else if (selected != null && selected.code == _user1Lang.code) {
      _showError('Cannot select the same language');
    }
  }

  Widget _buildFuturisticLanguagePicker() {
    return Dialog(
      backgroundColor: _F.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _F.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => _F.span.createShader(b),
              child: const Text(
                'SELECT LANGUAGE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: _F.border),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AppConstants.defaultLanguages.length,
                itemBuilder: (context, index) {
                  final lang = AppConstants.defaultLanguages[index];
                  return _buildFuturisticLanguageTile(lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticLanguageTile(Language language) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_F.amber.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _F.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pop(context, language),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  language.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: _F.t1,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _user1Controller.dispose();
    _user2Controller.dispose();
    _debounceTimer?.cancel();
    _waveController.dispose();
    _glowController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _F.bg,
        colorScheme:
            const ColorScheme.dark(primary: _F.amber, secondary: _F.orange),
      ),
      child: Scaffold(
        backgroundColor: _F.bg,
        body: Stack(
          children: [
            // Futuristic background
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
            // Animated glow effects
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
            SafeArea(
              child: Column(
                children: [
                  _buildFuturisticHeader(),
                  _buildFuturisticLanguageCards(),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildFuturisticMessageBubble(
                                  _messages[index]);
                            },
                          ),
                  ),
                  _buildFuturisticInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: _F.span,
              shape: BoxShape.circle,
              boxShadow: [_F.amberGlow],
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ShaderMask(
              shaderCallback: (b) => _F.span.createShader(b),
              child: const Text(
                'CONVERSATION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: _F.amber, size: 20),
                onPressed: _swapLanguages,
                tooltip: 'Swap languages',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all, color: _F.t2, size: 20),
                onPressed: _clearMessages,
                tooltip: 'Clear history',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticLanguageCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _selectLanguageForUser1,
              child: _buildGlowingCard(
                title: 'P1',
                language: _user1Lang,
                isActive: _isUser1Listening || _isUser1Speaking,
                color: _F.amber,
                icon: Icons.person,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _F.span,
                  boxShadow: [_F.amberGlow],
                ),
                child: const Icon(Icons.compare_arrows,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectLanguageForUser2,
              child: _buildGlowingCard(
                title: 'P2',
                language: _user2Lang,
                isActive: _isUser2Listening || _isUser2Speaking,
                color: _F.orange,
                icon: Icons.person_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingCard({
    required String title,
    required Language language,
    required bool isActive,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isActive ? 0.15 : 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isActive ? color : _F.border,
          width: isActive ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)]
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _F.t1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Text(language.flag, style: const TextStyle(fontSize: 10)),
                if (isActive)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color, blurRadius: 5)],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) => SizedBox(
              width: 100,
              height: 50,
              child: CustomPaint(
                painter: _WaveformPainter(
                  _waveController.value * 2 * math.pi,
                  _F.amber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'START',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: _F.t2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap microphone to speak',
            style: TextStyle(fontSize: 12, color: _F.t1.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _F.border)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _F.surface.withOpacity(0.5),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildFuturisticInputRow(
            title: 'P1 · ${_user1Lang.name.toUpperCase()}',
            controller: _user1Controller,
            onChanged: (_) => _translateUser1ToUser2(),
            onMicPressed: _listenUser1,
            isListening: _isUser1Listening,
            onSpeakPressed: _speakUser1Original,
            hintText: 'Speak or type...',
            color: _F.amber,
          ),
          const SizedBox(height: 8),
          _buildFuturisticInputRow(
            title: 'P2 · ${_user2Lang.name.toUpperCase()}',
            controller: _user2Controller,
            onChanged: (_) => _translateUser2ToUser1(),
            onMicPressed: _listenUser2,
            isListening: _isUser2Listening,
            onSpeakPressed: _speakUser2Original,
            hintText: 'Speak or type...',
            color: _F.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticInputRow({
    required String title,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onMicPressed,
    required bool isListening,
    required VoidCallback onSpeakPressed,
    required String hintText,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            color: color,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _F.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(color: _F.t1, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle:
                        TextStyle(color: _F.t2.withOpacity(0.5), fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: isListening ? _F.red : color,
                        size: 18,
                      ),
                      onPressed: onMicPressed,
                      padding: const EdgeInsets.all(6),
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 18),
                      onPressed: onSpeakPressed,
                      color: color,
                      padding: const EdgeInsets.all(6),
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticMessageBubble(ConversationMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original message
          Align(
            alignment: message.isFromUser1
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message.isFromUser1
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          message.isFromUser1
                              ? _F.amber.withOpacity(0.1)
                              : _F.orange.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (message.isFromUser1 ? _F.amber : _F.orange)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      message.originalText,
                      style: TextStyle(
                        fontSize: 13,
                        color: _F.t1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.fromPerson,
                          style: TextStyle(
                            fontSize: 8,
                            color: message.isFromUser1 ? _F.amber : _F.orange,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(message.fromLang.flag,
                            style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Translated message
          Align(
            alignment: message.isFromUser1
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message.isFromUser1
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          message.isFromUser1
                              ? _F.orange.withOpacity(0.1)
                              : _F.amber.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (message.isFromUser1 ? _F.orange : _F.amber)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      message.translatedText,
                      style: TextStyle(
                        fontSize: 13,
                        color: _F.t1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: message.isFromUser1
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Text(message.toLang.flag,
                            style: const TextStyle(fontSize: 9)),
                        const SizedBox(width: 4),
                        Text(
                          message.toPerson,
                          style: TextStyle(
                            fontSize: 8,
                            color: message.isFromUser1 ? _F.orange : _F.amber,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationMessage {
  final String fromPerson;
  final String originalText;
  final Language fromLang;
  final String toPerson;
  final String translatedText;
  final Language toLang;
  final DateTime timestamp;
  final bool isFromUser1;

  ConversationMessage({
    required this.fromPerson,
    required this.originalText,
    required this.fromLang,
    required this.toPerson,
    required this.translatedText,
    required this.toLang,
    required this.timestamp,
    required this.isFromUser1,
  });
}
