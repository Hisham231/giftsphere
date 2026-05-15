import 'package:url_launcher/url_launcher.dart';

class ContactService {
  // دعوة القطة
  static Future<bool> sendQattahInviteSMS({
    required String phoneNumber,
    required String inviteCode,
    required String qattahTitle,
    required String contactName,
  }) async {
    final String message =
        "Hi $contactName! 🎁 You've been invited to join the Qattah "
        "\"$qattahTitle\" on GiftSphere.\n"
        "Use this code to join: $inviteCode";

    return _sendSMS(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // دعوة الـ Secret Exchange
  static Future<bool> sendExchangeInviteSMS({
    required String phoneNumber,
    required String inviteCode,
    required String exchangeTitle,
    required String contactName,
  }) async {
    final String message =
        "Hi $contactName! 🎁 You've been invited to join the Secret Exchange "
        "\"$exchangeTitle\" on GiftSphere.\n"
        "Use this code to join: $inviteCode";

    return _sendSMS(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  static Future<bool> _sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    try {
      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      print('SMS launch error: $e');
      return false;
    }
  }
}