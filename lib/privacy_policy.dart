import 'nordic.dart';
import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key, required this.language});
  final String language;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: NordicAppBar(
      title: Text(language == 'de' ? 'Datenschutz' : 'Privacy policy'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: nordicPageWidth),
          child: FutureBuilder<String>(
            future: DefaultAssetBundle.of(context).loadString(
              'assets/privacy/privacy-${language == 'de' ? 'de' : 'en'}.txt',
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    language == 'de'
                        ? 'Die Datenschutzerklärung konnte nicht geladen werden.'
                        : 'The privacy policy could not be loaded.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 250 ? 12 : 24,
                ),
                child: SelectableText(snapshot.data!),
              );
            },
          ),
        ),
      ),
    ),
  );
}
