import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import '../widgets/language_selector.dart';
import '../widgets/translation_card.dart';
import '../utils/constants.dart';

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

  late Language _sourceLanguage;
  late Language _targetLanguage;

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  bool _isTranslating = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _translationError = '';
  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize with default languages first
    _sourceLanguage = AppConstants.defaultLanguages[0];
    _targetLanguage = AppConstants.defaultLanguages[1];

    _loadSavedLanguages();
    _initSpeech();
    _initTts();
    _setupMicAnimation();
  }

  Future<void> _loadSavedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Find languages by code or use defaults
        final sourceCode = prefs.getString('sourceLangCode') ??
            AppConstants.defaultLanguages[0].code;
        final targetCode = prefs.getString('targetLangCode') ??
            AppConstants.defaultLanguages[1].code;

        _sourceLanguage = AppConstants.defaultLanguages.firstWhere(
          (lang) => lang.code == sourceCode,
          orElse: () => AppConstants.defaultLanguages[0],
        );

        _targetLanguage = AppConstants.defaultLanguages.firstWhere(
          (lang) => lang.code == targetCode,
          orElse: () => AppConstants.defaultLanguages[1],
        );
      });
    } catch (e) {
      print('Error loading saved languages: $e');
      // Keep defaults if loading fails
    }
  }

  Future<void> _saveLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sourceLangCode', _sourceLanguage.code);
      await prefs.setString('sourceLangName', _sourceLanguage.name);
      await prefs.setString('targetLangCode', _targetLanguage.code);
      await prefs.setString('targetLangName', _targetLanguage.name);
    } catch (e) {
      print('Error saving languages: $e');
    }
  }

  void _setupMicAnimation() {
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_targetLanguage.code);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
        print("TTS Error: $msg");
      });
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
            _micAnimationController.stop();
          }
        },
        onError: (val) {
          print('Speech error: $val');
          if (mounted) {
            setState(() {
              _translationError = 'Speech recognition error: $val';
              _isListening = false;
            });
          }
          _micAnimationController.stop();
        },
      );

      if (!available && mounted) {
        setState(() {
          _translationError = 'Speech recognition not available on this device';
        });
      }
    } catch (e) {
      print('Error initializing speech: $e');
      if (mounted) {
        setState(() {
          _translationError = 'Failed to initialize speech recognition';
        });
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      String tempText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = tempText;
    });
    _saveLanguages();
    _flutterTts.setLanguage(_targetLanguage.code);
  }

  Future<void> _translateText() async {
    if (_sourceController.text.isEmpty) {
      setState(() {
        _targetController.clear();
        _translationError = '';
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.debounceDuration, () async {
      if (!mounted) return;

      setState(() {
        _isTranslating = true;
        _translationError = '';
      });

      try {
        var translation = await _translator.translate(
          _sourceController.text,
          from: _sourceLanguage.code,
          to: _targetLanguage.code,
        );

        if (mounted) {
          setState(() {
            _targetController.text = translation.text;
            _isTranslating = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _translationError = 'Translation failed: ${e.toString()}';
            _isTranslating = false;
          });
        }
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize();
        if (available) {
          if (mounted) {
            setState(() {
              _isListening = true;
              _translationError = '';
            });
          }
          _micAnimationController.repeat(reverse: true);

          _speech.listen(
            onResult: (val) {
              if (mounted) {
                setState(() {
                  _sourceController.text = val.recognizedWords;
                });
              }
              if (val.finalResult) {
                _translateText();
                _micAnimationController.stop();
                if (mounted) {
                  setState(() => _isListening = false);
                }
              }
            },
            localeId: _sourceLanguage.code,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        }
      } catch (e) {
        print('Error during speech listening: $e');
        if (mounted) {
          setState(() {
            _translationError = 'Failed to start speech recognition';
            _isListening = false;
          });
        }
        _micAnimationController.stop();
      }
    } else {
      if (mounted) {
        setState(() => _isListening = false);
      }
      _micAnimationController.stop();
      _speech.stop();
    }
  }

  void _speak() async {
    if (_targetController.text.isNotEmpty) {
      try {
        if (_isSpeaking) {
          await _flutterTts.stop();
          if (mounted) {
            setState(() => _isSpeaking = false);
          }
        } else {
          if (mounted) {
            setState(() => _isSpeaking = true);
          }
          await _flutterTts.speak(_targetController.text);
        }
      } catch (e) {
        print('Error during TTS: $e');
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _sourceController.clear();
      _targetController.clear();
      _translationError = '';
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    _debounceTimer?.cancel();
    _micAnimationController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Translator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.light
                  ? Colors.blue.shade50
                  : Colors.grey.shade900,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language Selection Row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: LanguageSelector(
                        selectedLanguage: _sourceLanguage,
                        languages: AppConstants.defaultLanguages,
                        onChanged: (Language language) {
                          setState(() {
                            _sourceLanguage = language;
                          });
                          _saveLanguages();
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: _swapLanguages,
                        color: Colors.blue,
                        iconSize: 28,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LanguageSelector(
                        selectedLanguage: _targetLanguage,
                        languages: AppConstants.defaultLanguages,
                        onChanged: (Language language) {
                          setState(() {
                            _targetLanguage = language;
                          });
                          _saveLanguages();
                          _flutterTts.setLanguage(language.code);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Translation Cards
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TranslationCard(
                      title: 'Source Text',
                      controller: _sourceController,
                      hintText: 'Enter text or use microphone...',
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _translateText();
                        } else {
                          setState(() {
                            _targetController.clear();
                          });
                        }
                      },
                      onMicPressed: _listen,
                      isListening: _isListening,
                    ),
                    const SizedBox(height: 16),
                    if (_isListening)
                      Center(
                        child: AnimatedBuilder(
                          animation: _micAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _micAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    TranslationCard(
                      title: 'Translated Text',
                      controller: _targetController,
                      hintText: 'Translation will appear here...',
                      readOnly: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_targetController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                _isSpeaking ? Icons.stop : Icons.volume_up,
                                color: _isSpeaking ? Colors.red : Colors.blue,
                              ),
                              onPressed: _speak,
                            ),
                          if (_targetController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () =>
                                  _copyToClipboard(_targetController.text),
                            ),
                        ],
                      ),
                    ),
                    if (_translationError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _translationError,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isTranslating)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _sourceController.text.isNotEmpty && !_isTranslating
                                ? _translateText
                                : null,
                        icon: const Icon(Icons.translate),
                        label: const Text('Translate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
