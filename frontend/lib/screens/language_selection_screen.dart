import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  void _selectLanguage(BuildContext context, String code) {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(code);
    // The Consumer2 in main.dart will automatically react and show the LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF00BFA5), size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose Language\nभाषा चुनें\nభాషను ఎంచుకోండి',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),
                _LanguageButton(
                  title: 'English',
                  subtitle: 'English',
                  onTap: () => _selectLanguage(context, 'en'),
                ),
                const SizedBox(height: 16),
                _LanguageButton(
                  title: 'हिंदी',
                  subtitle: 'Hindi',
                  onTap: () => _selectLanguage(context, 'hi'),
                ),
                const SizedBox(height: 16),
                _LanguageButton(
                  title: 'తెలుగు',
                  subtitle: 'Telugu',
                  onTap: () => _selectLanguage(context, 'te'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageButton({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
