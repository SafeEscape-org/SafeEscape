import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final String serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

  Future<void> sendMulticastNotification(List<String> fcmTokens, String message) async {
    if (fcmTokens.isEmpty) {
      print("No FCM tokens provided.");
      return;
    }

    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final body = jsonEncode({
      'registration_ids': fcmTokens,  // <-- MULTICAST: Multiple FCM tokens
      'notification': {
        'title': 'Disaster Alert',
        'body': message,
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Multicast Notification sent successfully');
    } else {
      print('Error sending multicast notification: ${response.body}');
    }
  }
}
