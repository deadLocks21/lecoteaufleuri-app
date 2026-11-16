/// Un code vient de partir par SMS.
class OtpRequestDto {
  /// Numéro normalisé (E.164) auquel le code a été envoyé.
  final String phoneNumber;
  final DateTime expiresAt;

  const OtpRequestDto({required this.phoneNumber, required this.expiresAt});
}
