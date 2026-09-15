import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/theme_and_locale_provider.dart';

/// Language picker.
///
/// A full screen rather than a sheet: there are 71 languages, and a half-height
/// sheet with a keyboard open leaves room for about three of them.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final current = ref.watch(localeProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;

    final query = _query.trim().toLowerCase();
    final matches = AppLocalizations.supportedLanguages.where((language) {
      if (query.isEmpty) return true;
      // Matched on both names: someone may know their language only by its
      // English name, or only by its own.
      return language.nativeName.toLowerCase().contains(query) ||
          language.englishName.toLowerCase().contains(query) ||
          language.code.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('settings_language_select') ?? 'Choose a language'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: loc?.translate('settings_language_search') ?? 'Search languages',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final language = matches[index];
                final isCurrent = language.code == current;

                return ListTile(
                  // Native name first: someone scanning for their own language
                  // looks for the word they recognise, not its English label.
                  title: Text(
                    language.nativeName,
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? context.colours.primary : null,
                    ),
                  ),
                  subtitle: Text(language.englishName),
                  trailing: isCurrent
                      ? Icon(Icons.check_rounded, color: context.colours.primary)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(language.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
