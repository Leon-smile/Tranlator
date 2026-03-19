import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';
import '../utils/constants.dart';

// ─── BRIDGO Theme ─────────────────────────────────────────────────────────────
// Identity: bridge arches · amber gold · burnt orange · deep steel navy
class _B {
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

// ─── Painter: Bridge Cable Background ─────────────────────────────────────────
class _BridgePainter extends CustomPainter {
  final double phase;
  _BridgePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Catenary cables
    final cablePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int arc = 0; arc < 2; arc++) {
      final sag = arc == 0 ? h * 0.28 : h * 0.44;
      final op = arc == 0 ? 0.20 : 0.09;
      cablePaint.shader = LinearGradient(colors: [
        Colors.transparent,
        _B.amber.withOpacity(op),
        _B.orange.withOpacity(op),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(0, 0, w, h));
      final path = Path()
        ..moveTo(0, sag)
        ..quadraticBezierTo(w / 2, sag * 0.08, w, sag);
      canvas.drawPath(path, cablePaint);
    }

    // Vertical hanger cables
    final hangerPaint = Paint()..strokeWidth = 0.5;
    const count = 14;
    for (int i = 1; i <= count; i++) {
      final x = i * w / (count + 1);
      final t = x / w;
      final cY = h * 0.28 * (1 - 4 * (t - 0.5) * (t - 0.5));
      final shimmer = 0.5 + 0.5 * math.sin(phase * 2 * math.pi - i * 0.5);
      hangerPaint.color = _B.amber.withOpacity(0.05 + shimmer * 0.09);
      canvas.drawLine(Offset(x, cY), Offset(x, h * 0.88), hangerPaint);
    }

    // Horizon road line
    final roadPaint = Paint()
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        _B.amber.withOpacity(0.16),
        _B.orange.withOpacity(0.16),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(0, 0, w, 1))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, h * 0.88), Offset(w, h * 0.88), roadPaint);

    // Warm glow orb behind cables
    final glowPaint = Paint()
      ..shader = RadialGradient(colors: [
        _B.amber.withOpacity(0.07 + 0.03 * math.sin(phase * 2 * math.pi)),
        Colors.transparent,
      ]).createShader(
          Rect.fromCircle(center: Offset(w / 2, h * 0.28), radius: w * 0.38));
    canvas.drawCircle(Offset(w / 2, h * 0.28), w * 0.38, glowPaint);
  }

  @override
  bool shouldRepaint(_BridgePainter old) => old.phase != phase;
}

// ─── Painter: Waveform ────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  _WavePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const bars = 22;
    final bw = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final x = i * bw + bw / 2;
      final amp =
          size.height / 2 * (0.25 + 0.75 * math.sin(phase + i * 0.55).abs());
      paint.color = color.withOpacity(0.3 + 0.7 * (i / bars));
      canvas.drawLine(Offset(x, size.height / 2 - amp),
          Offset(x, size.height / 2 + amp), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.phase != phase || o.color != color;
}

// ─── Scan Line ────────────────────────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Positioned(
          top: _c.value * MediaQuery.of(context).size.height - 2,
          left: 0,
          right: 0,
          child: Container(
              height: 2,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                Colors.transparent,
                _B.amber.withOpacity(0.09),
                Colors.transparent,
              ]))),
        ),
      );
}

// ─── Corner Brackets ─────────────────────────────────────────────────────────
class _Brackets extends StatelessWidget {
  final Widget child;
  final Color color;
  final double sz;
  const _Brackets({required this.child, required this.color, this.sz = 12});
  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        Positioned(
            top: 0, left: 0, child: _Crn(color: color, size: sz, tl: true)),
        Positioned(
            top: 0, right: 0, child: _Crn(color: color, size: sz, tr: true)),
        Positioned(
            bottom: 0, left: 0, child: _Crn(color: color, size: sz, bl: true)),
        Positioned(
            bottom: 0, right: 0, child: _Crn(color: color, size: sz, br: true)),
      ]);
}

class _Crn extends StatelessWidget {
  final Color color;
  final double size;
  final bool tl, tr, bl, br;
  const _Crn(
      {required this.color,
      required this.size,
      this.tl = false,
      this.tr = false,
      this.bl = false,
      this.br = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
            painter: _CrnP(
                color: color, size: size, tl: tl, tr: tr, bl: bl, br: br)),
      );
}

class _CrnP extends CustomPainter {
  final Color color;
  final double size;
  final bool tl, tr, bl, br;
  _CrnP(
      {required this.color,
      required this.size,
      this.tl = false,
      this.tr = false,
      this.bl = false,
      this.br = false});
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    if (tl) {
      canvas.drawLine(Offset(0, size), Offset.zero, p);
      canvas.drawLine(Offset.zero, Offset(size, 0), p);
    }
    if (tr) {
      canvas.drawLine(Offset(size, size), Offset(size, 0), p);
      canvas.drawLine(Offset(size, 0), Offset.zero, p);
    }
    if (bl) {
      canvas.drawLine(Offset.zero, Offset(0, size), p);
      canvas.drawLine(Offset(0, size), Offset(size, size), p);
    }
    if (br) {
      canvas.drawLine(Offset(size, 0), Offset(size, size), p);
      canvas.drawLine(Offset(0, size), Offset(size, size), p);
    }
  }

  @override
  bool shouldRepaint(_CrnP o) => false;
}

// ─── Language Chip ────────────────────────────────────────────────────────────
class _LangChip extends StatefulWidget {
  final Language language;
  final List<Language> languages;
  final ValueChanged<Language> onChanged;
  final Color color;
  const _LangChip(
      {required this.language,
      required this.languages,
      required this.onChanged,
      required this.color});
  @override
  State<_LangChip> createState() => _LangChipState();
}

class _LangChipState extends State<_LangChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _g;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _g = Tween<double>(begin: 0, end: 1).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _c.forward(),
        onExit: (_) => _c.reverse(),
        child: GestureDetector(
          onTap: _showPicker,
          child: AnimatedBuilder(
              animation: _g,
              builder: (_, __) => _Brackets(
                    color: widget.color,
                    sz: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: _B.surface,
                        border: Border.all(
                            color: widget.color
                                .withOpacity(0.18 + _g.value * 0.32)),
                        boxShadow: [
                          BoxShadow(
                              color: widget.color
                                  .withOpacity(0.04 + _g.value * 0.10),
                              blurRadius: 12)
                        ],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.language_rounded,
                            color: widget.color.withOpacity(0.65), size: 12),
                        const SizedBox(width: 6),
                        Flexible(
                            child: Text(
                          widget.language.name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: widget.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace'),
                        )),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more_rounded,
                            color: widget.color.withOpacity(0.55), size: 13),
                      ]),
                    ),
                  )),
        ),
      );

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, sc) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: _B.surface,
            border: Border.all(color: _B.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [_B.amberGlow],
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(children: [
                ShaderMask(
                    shaderCallback: (b) => _B.span.createShader(b),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white, size: 17)),
                const SizedBox(width: 9),
                Text('SELECT LANGUAGE',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    )),
              ]),
            ),
            Container(height: 1, color: _B.border),
            Expanded(
                child: ListView.builder(
              controller: sc,
              itemCount: widget.languages.length,
              itemBuilder: (_, i) => _tile(widget.languages[i]),
              padding: const EdgeInsets.only(bottom: 12),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _tile(Language lang) {
    final sel = lang.code == widget.language.code;
    return InkWell(
      onTap: () {
        widget.onChanged(lang);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? widget.color.withOpacity(0.07) : Colors.transparent,
          border: Border(
              left: BorderSide(
                  color: sel ? widget.color : Colors.transparent, width: 2)),
        ),
        child: Row(children: [
          Expanded(
              child: Text(lang.name,
                  style: TextStyle(
                    color: sel ? widget.color : _B.t1,
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ))),
          Text(lang.code.toUpperCase(),
              style: TextStyle(
                  color: _B.t2,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontFamily: 'monospace')),
          if (sel) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, color: widget.color, size: 14)
          ],
        ]),
      ),
    );
  }
}

// ─── Text Panel ───────────────────────────────────────────────────────────────
class _Panel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Color color;
  final List<Widget> actions;
  const _Panel(
      {required this.label,
      required this.controller,
      required this.hint,
      required this.color,
      this.readOnly = false,
      this.onChanged,
      this.actions = const []});

  @override
  Widget build(BuildContext context) => _Brackets(
        color: color,
        sz: 13,
        child: Container(
          decoration: BoxDecoration(
            color: _B.surface,
            border: Border.all(color: color.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 14)
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.08), Colors.transparent]),
                border:
                    Border(bottom: BorderSide(color: color.withOpacity(0.11))),
              ),
              child: Row(children: [
                Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(0.8), blurRadius: 5)
                        ])),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace')),
                const Spacer(),
                ...actions,
              ]),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly,
              onChanged: onChanged,
              maxLines: 5,
              minLines: 4,
              style: const TextStyle(color: _B.t1, fontSize: 15, height: 1.65),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: _B.t2.withOpacity(0.4),
                    fontSize: 14,
                    fontStyle: FontStyle.italic),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
              cursorColor: color,
            ),
          ]),
        ),
      );
}

// ─── Mic Button ───────────────────────────────────────────────────────────────
class _MicBtn extends StatefulWidget {
  final bool listening;
  final VoidCallback onTap;
  const _MicBtn({required this.listening, required this.onTap});
  @override
  State<_MicBtn> createState() => _MicBtnState();
}

class _MicBtnState extends State<_MicBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _p;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _p = Tween<double>(begin: 1.0, end: 1.55)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_MicBtn old) {
    super.didUpdateWidget(old);
    if (widget.listening && !old.listening)
      _c.repeat(reverse: true);
    else if (!widget.listening && old.listening) {
      _c.stop();
      _c.reset();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.listening ? _B.red : _B.amber;
    return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _p,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            if (widget.listening)
              Container(
                width: 52 * _p.value,
                height: 52 * _p.value,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withOpacity(1.0 - (_p.value - 1.0) * 1.8),
                        width: 1)),
              ),
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.11),
                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(widget.listening ? 0.5 : 0.16),
                        blurRadius: widget.listening ? 22 : 8,
                        spreadRadius: widget.listening ? 2 : 0)
                  ],
                ),
                child: Icon(widget.listening ? Icons.mic : Icons.mic_none,
                    color: color, size: 19)),
          ]),
        ));
  }
}

// ─── Swap Button ─────────────────────────────────────────────────────────────
class _SwapBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _SwapBtn({required this.onTap});
  @override
  State<_SwapBtn> createState() => _SwapBtnState();
}

class _SwapBtnState extends State<_SwapBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _r;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _r = Tween<double>(begin: 0, end: math.pi)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          _c.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
            animation: _r,
            builder: (_, __) => Transform.rotate(
                  angle: _r.value,
                  child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          _B.amber.withOpacity(0.16),
                          _B.orange.withOpacity(0.16)
                        ]),
                        border: Border.all(color: _B.border, width: 1),
                        boxShadow: [_B.amberGlow],
                      ),
                      child: ShaderMask(
                        shaderCallback: (b) => _B.span.createShader(b),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: Colors.white, size: 17),
                      )),
                )),
      );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool translating, listening;
  const _StatusBadge({required this.translating, required this.listening});
  @override
  Widget build(BuildContext context) {
    if (!translating && !listening) return const SizedBox.shrink();
    final color = listening ? _B.red : _B.amber;
    final label = listening ? 'LISTENING' : 'TRANSLATING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.26)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFamily: 'monospace')),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.4 + _c.value * 0.6),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withOpacity(0.7),
                    blurRadius: 5 * _c.value)
              ],
            )),
      );
}

// ─── Waveform Display ─────────────────────────────────────────────────────────
class _WaveDisplay extends StatefulWidget {
  final bool active;
  final Color color;
  const _WaveDisplay({required this.active, required this.color});
  @override
  State<_WaveDisplay> createState() => _WaveDisplayState();
}

class _WaveDisplayState extends State<_WaveDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: widget.active ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        child: SizedBox(
            height: 38,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                  painter: _WavePainter(
                      phase: _c.value * 2 * math.pi, color: widget.color)),
            )),
      );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({Key? key}) : super(key: key);
  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with TickerProviderStateMixin {
  final GoogleTranslator _translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  late Language _srcLang, _tgtLang;
  final _srcCtrl = TextEditingController();
  final _tgtCtrl = TextEditingController();

  bool _translating = false, _listening = false, _speaking = false;
  String _error = '';
  Timer? _debounce;
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _srcLang = AppConstants.defaultLanguages[0];
    _tgtLang = AppConstants.defaultLanguages[1];
    _loadSavedLanguages();
    _initSpeech();
    _initTts();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
  }

  Future<void> _loadSavedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        final sc =
            prefs.getString('srcLang') ?? AppConstants.defaultLanguages[0].code;
        final tc =
            prefs.getString('tgtLang') ?? AppConstants.defaultLanguages[1].code;
        _srcLang = AppConstants.defaultLanguages.firstWhere((l) => l.code == sc,
            orElse: () => AppConstants.defaultLanguages[0]);
        _tgtLang = AppConstants.defaultLanguages.firstWhere((l) => l.code == tc,
            orElse: () => AppConstants.defaultLanguages[1]);
      });
    } catch (_) {}
  }

  Future<void> _saveLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('srcLang', _srcLang.code);
      await prefs.setString('tgtLang', _tgtLang.code);
    } catch (_) {}
  }

  void _swap() {
    HapticFeedback.lightImpact();
    setState(() {
      final t = _srcLang;
      _srcLang = _tgtLang;
      _tgtLang = t;
      final s = _srcCtrl.text;
      _srcCtrl.text = _tgtCtrl.text;
      _tgtCtrl.text = s;
    });
    _saveLanguages();
    _flutterTts.setLanguage(_tgtLang.code);
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_tgtLang.code);
      await _flutterTts.setSpeechRate(0.5);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
  }

  void _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (v) {
          if ((v == 'done' || v == 'notListening') && mounted)
            setState(() => _listening = false);
        },
        onError: (_) {
          if (mounted)
            setState(() {
              _error = 'Speech recognition error';
              _listening = false;
            });
        },
      );
      if (!ok && mounted)
        setState(() => _error = 'Speech recognition not available');
    } catch (_) {}
  }

  Future<void> _translate() async {
    if (_srcCtrl.text.isEmpty) {
      setState(() {
        _tgtCtrl.clear();
        _error = '';
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(AppConstants.debounceDuration, () async {
      if (!mounted) return;
      setState(() {
        _translating = true;
        _error = '';
      });
      try {
        final r = await _translator.translate(_srcCtrl.text,
            from: _srcLang.code, to: _tgtLang.code);
        if (mounted)
          setState(() {
            _tgtCtrl.text = r.text;
            _translating = false;
          });
      } catch (_) {
        if (mounted)
          setState(() {
            _error = 'Translation failed';
            _translating = false;
          });
      }
    });
  }

  void _listen() async {
    HapticFeedback.mediumImpact();
    if (!_listening) {
      try {
        if (await _speech.initialize()) {
          setState(() {
            _listening = true;
            _error = '';
          });
          _speech.listen(
            onResult: (v) {
              if (mounted) setState(() => _srcCtrl.text = v.recognizedWords);
              if (v.finalResult) {
                _translate();
                if (mounted) setState(() => _listening = false);
              }
            },
            localeId: _srcLang.code,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        }
      } catch (_) {
        if (mounted)
          setState(() {
            _error = 'Failed to start speech recognition';
            _listening = false;
          });
      }
    } else {
      setState(() => _listening = false);
      _speech.stop();
    }
  }

  void _speak() async {
    if (_tgtCtrl.text.isEmpty) return;
    HapticFeedback.selectionClick();
    try {
      if (_speaking) {
        await _flutterTts.stop();
        if (mounted) setState(() => _speaking = false);
      } else {
        if (mounted) setState(() => _speaking = true);
        await _flutterTts.speak(_tgtCtrl.text);
      }
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _copy(String text) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_outline, color: _B.green, size: 15),
        const SizedBox(width: 8),
        Text('Copied to clipboard',
            style:
                TextStyle(color: _B.t1, fontFamily: 'monospace', fontSize: 12)),
      ]),
      backgroundColor: _B.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: _B.green.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _srcCtrl.clear();
      _tgtCtrl.clear();
      _error = '';
    });
  }

  @override
  void dispose() {
    _srcCtrl.dispose();
    _tgtCtrl.dispose();
    _debounce?.cancel();
    _bgCtrl.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: _B.bg,
          colorScheme:
              const ColorScheme.dark(primary: _B.amber, secondary: _B.orange),
        ),
        child: Scaffold(
          backgroundColor: _B.bg,
          body: Stack(children: [
            // Bridge cable background
            AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => CustomPaint(
                    painter: _BridgePainter(_bgCtrl.value),
                    size: Size.infinite)),
            // Bottom warm vignette
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_B.orange.withOpacity(0.06), Colors.transparent],
                  )),
                )),
            const _ScanLine(),
            SafeArea(
                child: Column(children: [
              _appBar(),
              _langBar(),
              Expanded(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: [
                  _sourcePanel(),
                  const SizedBox(height: 10),
                  _midRow(),
                  const SizedBox(height: 10),
                  _targetPanel(),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _errorBanner()
                  ],
                  const SizedBox(height: 18),
                  _actionRow(),
                ]),
              )),
            ])),
          ]),
        ),
      );

  Widget _appBar() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(children: [
          // Bridge arch logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                gradient: _B.span,
                shape: BoxShape.circle,
                boxShadow: [_B.amberGlow]),
            child: const Icon(Icons.account_balance_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 11),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => _B.span.createShader(b),
              child: const Text('BRIDGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  )),
            ),
            Text('BRIDGE · LANGUAGE · GO',
                style: TextStyle(
                    color: _B.t2,
                    fontSize: 7,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace')),
          ]),
          const Spacer(),
          _StatusBadge(translating: _translating, listening: _listening),
        ]),
      );

  Widget _langBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _B.surface,
          border: Border.all(color: _B.border),
          boxShadow: [_B.amberGlow],
        ),
        child: Row(children: [
          Expanded(
              child: _LangChip(
            language: _srcLang,
            languages: AppConstants.defaultLanguages,
            color: _B.amber,
            onChanged: (l) {
              setState(() => _srcLang = l);
              _saveLanguages();
            },
          )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _SwapBtn(onTap: _swap)),
          Expanded(
              child: Align(
                  alignment: Alignment.centerRight,
                  child: _LangChip(
                    language: _tgtLang,
                    languages: AppConstants.defaultLanguages,
                    color: _B.orange,
                    onChanged: (l) {
                      setState(() => _tgtLang = l);
                      _saveLanguages();
                      _flutterTts.setLanguage(l.code);
                    },
                  ))),
        ]),
      );

  Widget _sourcePanel() => _Panel(
        label: 'INPUT / SOURCE',
        controller: _srcCtrl,
        hint: 'Type or speak to translate...',
        color: _B.amber,
        onChanged: (v) {
          if (v.isNotEmpty)
            _translate();
          else
            setState(() => _tgtCtrl.clear());
        },
        actions: [
          _MicBtn(listening: _listening, onTap: _listen),
          const SizedBox(width: 4),
          if (_srcCtrl.text.isNotEmpty)
            GestureDetector(
                onTap: _clear,
                child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.clear_rounded, color: _B.t2, size: 15))),
        ],
      );

  Widget _midRow() => SizedBox(
      height: 38,
      child: Row(children: [
        Expanded(child: _WaveDisplay(active: _listening, color: _B.red)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _translating
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _B.amber))
              : ShaderMask(
                  shaderCallback: (b) => _B.spanV.createShader(b),
                  child: const Icon(Icons.arrow_downward_rounded,
                      color: Colors.white, size: 17)),
        ),
        Expanded(child: _WaveDisplay(active: _speaking, color: _B.orange)),
      ]));

  Widget _targetPanel() => _Panel(
        label: 'OUTPUT / TRANSLATION',
        controller: _tgtCtrl,
        hint: 'Translation will appear here...',
        color: _B.orange,
        readOnly: true,
        actions: [
          if (_tgtCtrl.text.isNotEmpty) ...[
            GestureDetector(
                onTap: _speak,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (_speaking ? _B.orange : Colors.white)
                        .withOpacity(0.06),
                    border:
                        Border.all(color: _speaking ? _B.orange : _B.border),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined,
                      color: _speaking ? _B.orange : _B.t2, size: 13),
                )),
            const SizedBox(width: 5),
            GestureDetector(
                onTap: () => _copy(_tgtCtrl.text),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: _B.border),
                      borderRadius: BorderRadius.circular(5)),
                  child: Icon(Icons.copy_outlined, color: _B.t2, size: 13),
                )),
          ],
        ],
      );

  Widget _errorBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _B.red.withOpacity(0.07),
          border: Border.all(color: _B.red.withOpacity(0.26)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: _B.red, size: 13),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_error.toUpperCase(),
                  style: TextStyle(
                      color: _B.red,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontFamily: 'monospace'))),
          GestureDetector(
              onTap: () => setState(() => _error = ''),
              child:
                  Icon(Icons.close, color: _B.red.withOpacity(0.7), size: 13)),
        ]),
      );

  Widget _actionRow() {
    final active = _srcCtrl.text.isNotEmpty && !_translating;
    return Row(children: [
      Expanded(
          child: GestureDetector(
        onTap: _clear,
        child: _Brackets(
            color: _B.t2,
            sz: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: _B.t2.withOpacity(0.13))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.clear_all, color: _B.t2, size: 15),
                const SizedBox(width: 7),
                Text('CLEAR',
                    style: TextStyle(
                        color: _B.t2,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace')),
              ]),
            )),
      )),
      const SizedBox(width: 12),
      Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: active ? _translate : null,
            child: _Brackets(
              color: active ? _B.amber : _B.t2,
              sz: 9,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: active
                      ? LinearGradient(colors: [
                          _B.amber.withOpacity(0.13),
                          _B.orange.withOpacity(0.13)
                        ])
                      : null,
                  border: Border.all(
                      color: active
                          ? _B.amber.withOpacity(0.30)
                          : _B.t2.withOpacity(0.13)),
                  boxShadow: active ? [_B.amberGlow] : null,
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.translate,
                      color: active ? _B.amber : _B.t2, size: 15),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: active ? [_B.amber, _B.orange] : [_B.t2, _B.t2],
                    ).createShader(b),
                    child: const Text('TRANSLATE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        )),
                  ),
                ]),
              ),
            ),
          )),
    ]);
  }
}
