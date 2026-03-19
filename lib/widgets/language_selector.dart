import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LanguageSelector extends StatelessWidget {
  final Language selectedLanguage;
  final List<Language> languages;
  final ValueChanged<Language> onChanged;

  const LanguageSelector({
    Key? key,
    required this.selectedLanguage,
    required this.languages,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Language>(
          value: selectedLanguage,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_circle_outlined),
          iconSize: 20,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: languages.map((Language language) {
            return DropdownMenuItem<Language>(
              value: language,
              child: Row(
                children: [
                  Text(
                    language.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      language.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Language? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
