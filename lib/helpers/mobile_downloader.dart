import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadImage(Uint8List bytes) async {
  try {
    // Periksa izin penyimpanan
    if (await Permission.storage.request().isGranted ||
        await Permission.manageExternalStorage.request().isGranted) {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final filePath =
            '${directory.path}/downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Simpan gambar
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        print('Image downloaded successfully at $filePath');
      } else {
        print('Failed to get directory');
      }
    } else {
      print('Storage permission denied');
    }
  } catch (e) {
    print('Failed to download image: $e');
  }
}
