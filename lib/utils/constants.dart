class AppConstants {
  static const String appName = 'ML Translator';
  static const String appVersion = '1.0.0';

  static const List<Language> defaultLanguages = [
    Language('en', 'English'),
    Language('es', 'Spanish'),
    Language('fr', 'French'),
    Language('de', 'German'),
    Language('it', 'Italian'),
    Language('pt', 'Portuguese'),
    Language('ru', 'Russian'),
    Language('ja', 'Japanese'),
    Language('ko', 'Korean'),
    Language('zh-cn', 'Chinese'),
    Language('ar', 'Arabic'),
    Language('hi', 'Hindi'),
    Language('nl', 'Dutch'),
    Language('pl', 'Polish'),
    Language('tr', 'Turkish'),
    Language('vi', 'Vietnamese'),
    Language('th', 'Thai'),
    Language('id', 'Indonesian'),
  ];

  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'zh-cn': '🇨🇳',
    'ar': '🇸🇦',
    'hi': '🇮🇳',
    'nl': '🇳🇱',
    'pl': '🇵🇱',
    'tr': '🇹🇷',
    'vi': '🇻🇳',
    'th': '🇹🇭',
    'id': '🇮🇩',
  };

  static const Duration debounceDuration = Duration(milliseconds: 500);
}

class Language {
  final String code;
  final String name;

  const Language(this.code, this.name);

  String get flag => AppConstants.languageFlags[code] ?? '🌐';

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
