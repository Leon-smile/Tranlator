import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';
import '../utils/constants.dart';

// Futuristic color palette (matching conversation screen)
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

// Futuristic scan line painter
class _ScanLinePainter extends CustomPainter {
  final double phase;
  _ScanLinePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _F.amber.withOpacity(0.3 + 0.3 * math.sin(phase * math.pi * 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final y = size.height * (0.2 + 0.6 * math.sin(phase * math.pi * 2).abs());
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.phase != phase;
}

class PictureTranslatorScreen extends StatefulWidget {
  const PictureTranslatorScreen({Key? key}) : super(key: key);

  @override
  State<PictureTranslatorScreen> createState() =>
      _PictureTranslatorScreenState();
}

class _PictureTranslatorScreenState extends State<PictureTranslatorScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final GoogleTranslator _translator = GoogleTranslator();

  File? _selectedImage;
  String _detectedText = '';
  String _translatedText = '';
  Language _targetLanguage = AppConstants.defaultLanguages[1];
  bool _isProcessing = false;
  bool _isTranslating = false;
  String _error = '';

  late AnimationController _glowController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanController.dispose();
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
                  _buildLanguageSelector(),
                  Expanded(
                    flex: 2,
                    child: _buildImageArea(),
                  ),
                  _buildActionButtons(),
                  Expanded(
                    flex: 2,
                    child: _buildResultsArea(),
                  ),
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
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ShaderMask(
              shaderCallback: (b) => _F.span.createShader(b),
              child: const Text(
                'PICTURE TRANSLATOR',
                style: TextStyle(
                  fontSize: 12,
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
          if (_detectedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: _F.amber, size: 18),
              onPressed: () => _copyToClipboard(_detectedText),
              tooltip: 'Copy text',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_F.amber.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _F.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'TO',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: _F.amber,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Language>(
                value: _targetLanguage,
                isExpanded: true,
                dropdownColor: _F.surface,
                style: TextStyle(
                  fontSize: 13,
                  color: _F.t1,
                  fontWeight: FontWeight.w500,
                ),
                icon: Icon(Icons.arrow_drop_down, color: _F.amber, size: 20),
                items: AppConstants.defaultLanguages.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Language? newLang) {
                  if (newLang != null) {
                    setState(() => _targetLanguage = newLang);
                    if (_detectedText.isNotEmpty) {
                      _translateText();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_F.surface, _F.bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _F.border),
        boxShadow: [_F.amberGlow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (_selectedImage == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) => Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _F.span,
                          boxShadow: [_F.amberGlow],
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TAP TO SELECT IMAGE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: _F.t2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera or Gallery',
                      style: TextStyle(
                        fontSize: 11,
                        color: _F.amber.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // Scan line animation when processing
                  if (_isProcessing)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (_, __) => CustomPaint(
                        painter: _ScanLinePainter(_scanController.value),
                        size: Size.infinite,
                      ),
                    ),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _F.bg.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            // Corner brackets
            _buildCornerBrackets(),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBrackets() {
    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: _buildCorner(_F.amber, true, false, false, false),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _buildCorner(_F.amber, false, true, false, false),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: _buildCorner(_F.amber, false, false, true, false),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: _buildCorner(_F.amber, false, false, false, true),
        ),
      ],
    );
  }

  Widget _buildCorner(Color color, bool tl, bool tr, bool bl, bool br) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerPainter(color: color, tl: tl, tr: tr, bl: bl, br: br),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFuturisticButton(
              onPressed: _isProcessing ? null : _pickImage,
              icon: Icons.camera_alt,
              label: 'PICK',
              color: _F.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFuturisticButton(
              onPressed:
                  _isProcessing || _selectedImage == null ? null : _extractText,
              icon: Icons.text_fields,
              label: 'EXTRACT',
              color: _F.orange,
              isLoading: _isProcessing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(onPressed != null ? 0.15 : 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: onPressed != null ? color : _F.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                else
                  Icon(icon,
                      color: onPressed != null ? color : _F.t2, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: onPressed != null ? color : _F.t2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_F.surface, _F.bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _F.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detected Text Header
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: _F.spanV,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DETECTED',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: _F.amber,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (_detectedText.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () => _copyToClipboard(_detectedText),
                  color: _F.t2,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Text(
                _detectedText.isEmpty
                    ? 'No text detected yet. Select an image and extract text.'
                    : _detectedText,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: _F.t1,
                ),
              ),
            ),
          ),
          const Divider(color: _F.border, height: 12),
          // Translation Header
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: _F.spanV,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TRANSLATION',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: _F.orange,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (_translatedText.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () => _copyToClipboard(_translatedText),
                  color: _F.t2,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 1,
            child: _isTranslating
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_F.orange),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Text(
                      _translatedText.isEmpty
                          ? 'Translation will appear here after extraction.'
                          : _translatedText,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _F.t1,
                      ),
                    ),
                  ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _F.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _F.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: _F.red, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: TextStyle(color: _F.red, fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = ''),
                      child: Icon(Icons.close,
                          color: _F.red.withOpacity(0.7), size: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _F.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _F.border),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _F.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _F.span,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 18),
                ),
                title:
                    const Text('Take a photo', style: TextStyle(color: _F.t1)),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _F.span,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Colors.white, size: 18),
                ),
                title: const Text('Choose from gallery',
                    style: TextStyle(color: _F.t1)),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectedText = '';
          _translatedText = '';
          _error = '';
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _extractText() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _error = '';
    });

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);

      // Try different scripts for better text recognition
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String extracted = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            extracted += line.text.trim() + '\n';
          }
        }
      }

      await textRecognizer.close();

      if (extracted.trim().isEmpty) {
        setState(() {
          _error = 'No text found in the image. Try a clearer image.';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _detectedText = extracted.trim();
        _isProcessing = false;
      });

      if (_detectedText.isNotEmpty) {
        _translateText();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to extract text: ${e.toString().split('\n').first}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _translateText() async {
    if (_detectedText.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _error = '';
    });

    try {
      final translation = await _translator.translate(
        _detectedText,
        to: _targetLanguage.code,
      );

      setState(() {
        _translatedText = translation.text;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Translation failed: ${e.toString().split('\n').first}';
        _isTranslating = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _F.green, size: 16),
            const SizedBox(width: 8),
            const Text('Copied to clipboard', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: _F.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _F.green.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// Corner bracket painter
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool tl, tr, bl, br;

  _CornerPainter({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (tl) {
      canvas.drawLine(Offset(0, 8), Offset.zero, paint);
      canvas.drawLine(Offset.zero, Offset(8, 0), paint);
    }
    if (tr) {
      canvas.drawLine(Offset(size.width - 8, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, 8), paint);
    }
    if (bl) {
      canvas.drawLine(
          Offset(0, size.height - 8), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(8, size.height), paint);
    }
    if (br) {
      canvas.drawLine(Offset(size.width - 8, size.height),
          Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height - 8),
          Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
