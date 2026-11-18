/// Rewrites a string so that it no longer contains a sensitive value.
typedef Redactor = String Function(String input);

/// Ready-made [Redactor]s.
///
/// ```dart
/// Log.redactors.addAll([Redactors.email, Redactors.creditCard]);
/// ```
abstract final class Redactors {
  /// Replaces `Bearer xxx` with `Bearer <redacted>`.
  static final Redactor bearerToken = pattern(
    RegExp(r'\bbearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    'Bearer <redacted>',
  );

  /// Replaces JSON Web Tokens.
  static final Redactor jwt = pattern(
    RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
    '<jwt>',
  );

  /// Replaces email addresses.
  static final Redactor email = pattern(
    RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'),
    '<email>',
  );

  /// Replaces 13 to 19 digit card numbers (with optional spaces or dashes).
  static final Redactor creditCard = pattern(
    RegExp(r'\b(?:\d[ -]?){12,18}\d\b'),
    '<card>',
  );

  /// Builds a redactor from a regular expression.
  static Redactor pattern(RegExp regExp, String replacement) =>
      (String input) => input.replaceAll(regExp, replacement);

  /// Redacts the value of every query parameter named in [names].
  static Redactor queryParameters(Set<String> names) {
    final lower = names.map((String n) => n.toLowerCase()).toSet();
    return (String input) {
      final uri = Uri.tryParse(input.trim());
      if (uri == null || uri.queryParameters.isEmpty) {
        return input;
      }
      final params = Map<String, String>.of(uri.queryParameters)
        ..updateAll(
          (String k, String v) =>
              lower.contains(k.toLowerCase()) ? '<redacted>' : v,
        );
      return uri.replace(queryParameters: params).toString();
    };
  }
}

/// Returns a copy of [headers] with sensitive values replaced.
Map<String, String> redactHeaders(
  Map<String, String> headers,
  Set<String> sensitive,
) {
  final lower = sensitive.map((String n) => n.toLowerCase()).toSet();
  return {
    for (final MapEntry<String, String> e in headers.entries)
      e.key: lower.contains(e.key.toLowerCase()) ? '<redacted>' : e.value,
  };
}
