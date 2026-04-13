import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

/// Drop-in replacement for Text() that auto-translates its content.
/// Usage: TranslatedText('Hello') — works exactly like Text('Hello')
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? textScaleFactor;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translated = '';
  String _lastLang = '';
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _translated = widget.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.watch<LocalizationService>();
    final lang = service.currentLanguageCode;

    if (lang != _lastLang || widget.text != _lastText) {
      _lastLang = lang;
      _lastText = widget.text;
      if (lang == 'en') {
        if (mounted) setState(() => _translated = widget.text);
      } else {
        service.translate(widget.text).then((result) {
          if (mounted) setState(() => _translated = result);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translated,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap ?? true,
      textScaler: widget.textScaleFactor != null
          ? TextScaler.linear(widget.textScaleFactor!)
          : TextScaler.noScaling,
    );
  }
}

/// Extension on String for convenient inline translation
/// Usage: context.tr('Hello')
extension TranslationExtension on BuildContext {
  Future<String> tr(String text) {
    return read<LocalizationService>().translate(text);
  }

  String get languageCode => read<LocalizationService>().currentLanguageCode;
  bool get isRTL => read<LocalizationService>().isRTL;
}

/// A widget that wraps content with RTL/LTR directionality based on language
class LocalizedDirectionality extends StatelessWidget {
  final Widget child;
  const LocalizedDirectionality({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isRTL = context.select<LocalizationService, bool>((s) => s.isRTL);
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}

/// FutureBuilder-based widget for translating dynamic strings
class AsyncTranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AsyncTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<LocalizationService>();
    if (service.currentLanguageCode == 'en') {
      return Text(text, style: style, textAlign: textAlign,
          maxLines: maxLines, overflow: overflow);
    }
    return FutureBuilder<String>(
      future: service.translate(text),
      initialData: text,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}