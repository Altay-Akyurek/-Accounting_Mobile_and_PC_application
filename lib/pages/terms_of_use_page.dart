import 'package:flutter/material.dart';
import '../constants/legal_contents.dart';
import '../l10n/app_localizations.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final sections = LegalContent.getTermsSections(locale);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(LegalContent.getTermsTitle(context, locale)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sections.map((s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(s['title']!),
                _buildParagraph(s['body']!),
              ],
            )),
            const SizedBox(height: 32),
            Text(LegalContent.getTermsEffectiveDate(locale), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF011627)),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
      textAlign: TextAlign.justify,
    );
  }
}
