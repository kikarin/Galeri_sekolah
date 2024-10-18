import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadImage(Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "downloaded_image.jpg")
    ..click();
  html.Url.revokeObjectUrl(url);
  print('Image downloaded successfully on web');
}
