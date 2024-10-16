import 'dart:html' as html;
import 'dart:typed_data';

void downloadImage(Uint8List bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DownloadedImage.jpg")
    ..click();

  html.Url.revokeObjectUrl(url);
}
