import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadImage(Uint8List bytes) async {
  try {
    // Minta izin penyimpanan
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Dapatkan direktori eksternal untuk menyimpan gambar
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Simpan gambar
      final file = File(path);
      await file.writeAsBytes(bytes);

      print('Image downloaded successfully at $path');
    } else {
      print('Storage permission denied');
    }
  } catch (e) {
    print('Failed to download image: $e');
  }
}
