import 'package:flutter/material.dart';

enum CardInfo {
  camera('Cameras', Icons.video_call, Color(0xff2354C7), Color(0xffECEFFD)),
  lighting('Lighting', Icons.lightbulb, Color(0xff806C2A), Color(0xffFAEEDF)),
  climate('Climate', Icons.thermostat, Color(0xffA44D2A), Color(0xffFAEDE7)),
  wifi('Wifi', Icons.wifi, Color(0xff417345), Color(0xffE5F4E0)),
  media('Media', Icons.library_music, Color(0xff2556C8), Color(0xffECEFFD)),
  security(
      'Security', Icons.crisis_alert, Color(0xff794C01), Color(0xffFAEEDF)),
  safety(
      'Safety', Icons.medical_services, Color(0xff2251C5), Color(0xffECEFFD)),
  more('', Icons.add, Color(0xff201D1C), Color(0xffE3DFD8));

  const CardInfo(this.label, this.icon, this.color, this.backgroundColor);
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

class ImageInfo {
  final String title;
  final String subtitle;
  final String url;

  const ImageInfo(this.title, this.subtitle, this.url);
}

class ImageInfoData {
  static const List<ImageInfo> values = [
    ImageInfo('The Flow', 'Sponsored | Season 1 Now Streaming',
        'content_based_color_scheme_1.png'),
    ImageInfo(
      'Through the Pane',
      'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_2.png',
    ),
    ImageInfo('Iridescence', 'Sponsored | Season 1 Now Streaming',
        'content_based_color_scheme_3.png'),
    ImageInfo('Sea Change', 'Sponsored | Season 1 Now Streaming',
        'content_based_color_scheme_4.png'),
    ImageInfo('Blue Symphony', 'Sponsored | Season 1 Now Streaming',
        'content_based_color_scheme_5.png'),
    ImageInfo('When It Rains', 'Sponsored | Season 1 Now Streaming',
        'content_based_color_scheme_6.png'),
  ];
}
