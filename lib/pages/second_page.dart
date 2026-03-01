import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.secondPage)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.goBack),
        ),
      ),
    );
  }
}
