import 'utils.dart';

class WebRTCInit {
  static Future<Null> initialize(String title, String text, String channelName) async {
    await WebRTC.methodChannel()
      .invokeMethod("initialize", <String, String>{
        "title": title,
        "text": text,
        "channelName": channelName,
      });
  }

  static Future<Null> deinitialize() async {
    await WebRTC.methodChannel().invokeMethod("deinitialize");
  }
}
