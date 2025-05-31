/* TODO, will use later */
/* class FcmBackgroundHandler {
  Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage remoteMessage) async {
    await Firebase.initializeApp();

    if (remoteMessage.data.containsKey('data')) {
      String name = '';
      String age = '';
      if (PlatformUtil.isIOS()) {
        name = remoteMessage.data['name'];
        age = remoteMessage.data['age'];
      } else if (PlatformUtil.isAndroid()) {
        var data = remoteMessage.data['data'];
        name = data['name'];
        age = data['age'];
      }
    }
    return;
  }

  Future<void> init() async {
    final firebaseMessaging = FirebaseMessaging.instance;
    if (PlatformUtil.isIOS()) {
      firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(
        (message) => firebaseMessagingBackgroundHandler(message));

    FirebaseMessaging.instance.getToken().then((token) {});

    FirebaseMessaging.instance
        .subscribeToTopic('all')
        .then((response) => {
              // See the MessagingTopicManagementResponse reference documentation
              // for the contents of response.
              //fcm then:
            })
        .catchError((error) => {
              //Failed to subscribe to topic: $error
            });
  }

  void _handleMessage(RemoteMessage remoteMessage) {
    String name = '';
    String age = '';
    if (PlatformUtil.isIOS()) {
      name = remoteMessage.data['name'];
      age = remoteMessage.data['age'];
    } else if (PlatformUtil.isAndroid()) {
      var data = remoteMessage.data['data'];
      name = data['name'];
      age = data['age'];
    }

    //getDataFcm: name: $name & age: $age
  }
} **/
