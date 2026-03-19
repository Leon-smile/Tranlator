import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final VoidCallback? onMicPressed;
  final bool isListening;

  const TranslationCard({
    Key? key,
    required this.title,
    required this.controller,
    required this.hintText,
    this.readOnly = false,
    this.onChanged,
    this.suffixIcon,
    this.onMicPressed,
    this.isListening = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onMicPressed != null)
                  IconButton(
                    icon: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.red : Colors.blue,
                    ),
                    onPressed: onMicPressed,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade50
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                readOnly: readOnly,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: suffixIcon,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
