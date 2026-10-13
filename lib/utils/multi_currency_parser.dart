// lib/utils/multi_currency_parser.dart

class ParsedAmount {
  final double amount;
  final String currency;
  final String rawText;

  ParsedAmount({
    required this.amount,
    required this.currency,
    required this.rawText,
  });

  @override
  String toString() => '$amount $currency (raw: $rawText)';
}

class MultiCurrencyParser {
  static const Map<String, String> _symbolMap = {
    '\$': 'USD',
    'USD': 'USD',
    '달러': 'USD',
    '¥': 'JPY',
    'JPY': 'JPY',
    '엔': 'JPY',
    '€': 'EUR',
    'EUR': 'EUR',
    '유로': 'EUR',
    '£': 'GBP',
    'GBP': 'GBP',
    '파운드': 'GBP',
    '₩': 'KRW',
    '원': 'KRW',
    'KRW': 'KRW',
  };

  static List<ParsedAmount> parse(String text) {
    List<ParsedAmount> results = [];

    final RegExp regExp = RegExp(
      r'([$\u00A3\u20AC\u00A5\u20A9]|USD|JPY|EUR|GBP|KRW)?\s*([\d,]+(?:\.\d+)?)\s*([$\u00A3\u20AC\u00A5\u20A9]|USD|JPY|EUR|GBP|KRW|달러|엔|유로|원)?',
      caseSensitive: false,
    );

    final matches = regExp.allMatches(text);

    for (final match in matches) {
      final prefix = match.group(1);
      final rawNumber = match.group(2);
      final suffix = match.group(3);

      if (rawNumber == null) continue;
      if (prefix == null && suffix == null) continue;

      String? matchedSymbol = prefix ?? suffix;
      if (matchedSymbol == null) continue;

      String currencyCode = _symbolMap[matchedSymbol.toUpperCase()] ?? 'UNKNOWN';

      String cleanNumber = rawNumber.replaceAll(',', '');
      double? parsedValue = double.tryParse(cleanNumber);

      if (parsedValue != null) {
        results.add(
          ParsedAmount(
            amount: parsedValue,
            currency: currencyCode,
            rawText: match.group(0)!.trim(),
          ),
        );
      }
    }

    return results;
  }
}

/*
import 'package:your_app_name/utils/multi_currency_parser.dart';

void processSms(String smsText) {
  List<ParsedAmount> amounts = MultiCurrencyParser.parse(smsText);

  for (var item in amounts) {
    print('추출 금액: ${item.amount}');
    print('통화 코드: ${item.currency}');
  }
}
*/
