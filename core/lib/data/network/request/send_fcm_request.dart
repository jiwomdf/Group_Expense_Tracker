// To parse this JSON data, do
//
//     final sendFcmRequest = sendFcmRequestFromJson(jsonString);

class SendFcmRequest {
  final String to;
  final FcmNotification notification;

  SendFcmRequest({
    required this.to,
    required this.notification,
  });

  Map<String, dynamic> toJson() => {
        "to": to,
        "notification": notification.toJson(),
      };
}

class FcmNotification {
  final String title;
  final String body;

  FcmNotification({
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "body": body,
      };
}

/**
     *  {
        "to": "YOUR_FCM_TOEKEN",
        "notification": {
            "title": "HI DEVELOPER I AM TEWST",
            "body": "Hi DEVELOPER"
        }
    }
*/
