/// A language the app ships translations for.
final class LanguageItem {
  const LanguageItem({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  /// ISO 639-1 code, matching `assets/Localizations/<code>.json`.
  final String code;

  /// Name in English, for users searching in a language they do not read.
  final String englishName;

  /// Name as speakers of that language write it. Shown first in the picker:
  /// someone looking for their own language scans for the word they know.
  final String nativeName;
}

/// Languages that read right to left.
///
/// Flutter derives text direction from the locale, so this is only needed where
/// the app has to reason about direction itself.
const Set<String> kRightToLeftLanguages = {'ar', 'fa', 'he', 'ur', 'ps'};

/// Every language with a translation file, sorted by English name.
///
/// This list and the contents of `assets/Localizations/` must agree: a code
/// listed here without a file falls back to English silently, and a file not
/// listed here is never reachable. A test holds the two together.
const List<LanguageItem> kSupportedLanguages = [
  LanguageItem(code: 'af', englishName: 'Afrikaans', nativeName: 'Afrikaans'),
  LanguageItem(code: 'sq', englishName: 'Albanian', nativeName: 'Shqip'),
  LanguageItem(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
  LanguageItem(code: 'hy', englishName: 'Armenian', nativeName: 'Հայերեն'),
  LanguageItem(code: 'az', englishName: 'Azerbaijani', nativeName: 'Azərbaycanca'),
  LanguageItem(code: 'eu', englishName: 'Basque', nativeName: 'Euskara'),
  LanguageItem(code: 'be', englishName: 'Belarusian', nativeName: 'Беларуская'),
  LanguageItem(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা'),
  LanguageItem(code: 'bs', englishName: 'Bosnian', nativeName: 'Bosanski'),
  LanguageItem(code: 'bg', englishName: 'Bulgarian', nativeName: 'Български'),
  LanguageItem(code: 'ca', englishName: 'Catalan', nativeName: 'Català'),
  LanguageItem(code: 'zh', englishName: 'Chinese', nativeName: '中文'),
  LanguageItem(code: 'hr', englishName: 'Croatian', nativeName: 'Hrvatski'),
  LanguageItem(code: 'cs', englishName: 'Czech', nativeName: 'Čeština'),
  LanguageItem(code: 'da', englishName: 'Danish', nativeName: 'Dansk'),
  LanguageItem(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands'),
  LanguageItem(code: 'en', englishName: 'English', nativeName: 'English'),
  LanguageItem(code: 'et', englishName: 'Estonian', nativeName: 'Eesti'),
  LanguageItem(code: 'fil', englishName: 'Filipino', nativeName: 'Filipino'),
  LanguageItem(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi'),
  LanguageItem(code: 'fr', englishName: 'French', nativeName: 'Français'),
  LanguageItem(code: 'gl', englishName: 'Galician', nativeName: 'Galego'),
  LanguageItem(code: 'ka', englishName: 'Georgian', nativeName: 'ქართული'),
  LanguageItem(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
  LanguageItem(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά'),
  LanguageItem(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
  LanguageItem(code: 'he', englishName: 'Hebrew', nativeName: 'עברית'),
  LanguageItem(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
  LanguageItem(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar'),
  LanguageItem(code: 'is', englishName: 'Icelandic', nativeName: 'Íslenska'),
  LanguageItem(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia'),
  LanguageItem(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
  LanguageItem(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
  LanguageItem(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  LanguageItem(code: 'kk', englishName: 'Kazakh', nativeName: 'Қазақша'),
  LanguageItem(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
  LanguageItem(code: 'ky', englishName: 'Kyrgyz', nativeName: 'Кыргызча'),
  LanguageItem(code: 'lo', englishName: 'Lao', nativeName: 'ລາວ'),
  LanguageItem(code: 'lv', englishName: 'Latvian', nativeName: 'Latviešu'),
  LanguageItem(code: 'lt', englishName: 'Lithuanian', nativeName: 'Lietuvių'),
  LanguageItem(code: 'mk', englishName: 'Macedonian', nativeName: 'Македонски'),
  LanguageItem(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu'),
  LanguageItem(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
  LanguageItem(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
  LanguageItem(code: 'mn', englishName: 'Mongolian', nativeName: 'Монгол'),
  LanguageItem(code: 'my', englishName: 'Burmese', nativeName: 'မြန်မာ'),
  LanguageItem(code: 'ne', englishName: 'Nepali', nativeName: 'नेपाली'),
  LanguageItem(code: 'ps', englishName: 'Pashto', nativeName: 'پښتو'),
  LanguageItem(code: 'fa', englishName: 'Persian', nativeName: 'فارسی'),
  LanguageItem(code: 'pl', englishName: 'Polish', nativeName: 'Polski'),
  LanguageItem(code: 'pt', englishName: 'Portuguese', nativeName: 'Português'),
  LanguageItem(code: 'pa', englishName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
  LanguageItem(code: 'ro', englishName: 'Romanian', nativeName: 'Română'),
  LanguageItem(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
  LanguageItem(code: 'sr', englishName: 'Serbian', nativeName: 'Српски'),
  LanguageItem(code: 'si', englishName: 'Sinhala', nativeName: 'සිංහල'),
  LanguageItem(code: 'sk', englishName: 'Slovak', nativeName: 'Slovenčina'),
  LanguageItem(code: 'sl', englishName: 'Slovenian', nativeName: 'Slovenščina'),
  LanguageItem(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  LanguageItem(code: 'sw', englishName: 'Swahili', nativeName: 'Kiswahili'),
  LanguageItem(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska'),
  LanguageItem(code: 'tl', englishName: 'Tagalog', nativeName: 'Tagalog'),
  LanguageItem(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
  LanguageItem(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
  LanguageItem(code: 'th', englishName: 'Thai', nativeName: 'ไทย'),
  LanguageItem(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
  LanguageItem(code: 'uk', englishName: 'Ukrainian', nativeName: 'Українська'),
  LanguageItem(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
  LanguageItem(code: 'uz', englishName: 'Uzbek', nativeName: 'Oʻzbekcha'),
  LanguageItem(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt'),
  LanguageItem(code: 'zu', englishName: 'Zulu', nativeName: 'isiZulu'),
];
