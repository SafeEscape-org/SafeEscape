import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final String serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

  Future<void> sendNotification(String fcmToken, String message) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final body = jsonEncode({
      'to': fcmToken,
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
      print('Notification sent successfully');
    } else {
      print('Error sending notification: ${response.body}');
    }
  }
}
