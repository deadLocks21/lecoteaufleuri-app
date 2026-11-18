/// Un mobile E.164 français (`+33612345678`) tel qu'on le lit en France :
/// `06 12 34 56 78`. Tout autre format est rendu tel quel.
String displayPhone(String e164) {
  final match = RegExp(
    r'^\+33(\d)(\d{2})(\d{2})(\d{2})(\d{2})$',
  ).firstMatch(e164);
  if (match == null) return e164;
  return '0${match[1]} ${match[2]} ${match[3]} ${match[4]} ${match[5]}';
}
