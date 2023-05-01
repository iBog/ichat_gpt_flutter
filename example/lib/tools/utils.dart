import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Utils {
  static Future<Directory?> getDownloadsDir() async {
    // Get the platform-specific downloads directory path
    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      final externalStorageFolder = await getExternalStorageDirectory();
      if (externalStorageFolder != null) {
        downloadsDirectory =
            Directory(p.join(externalStorageFolder.path, "Downloads"));
      }
    } else {
      downloadsDirectory = await getDownloadsDirectory();
    }

    return downloadsDirectory;
  }

  static Future<void> saveImageFromUrl(
      BuildContext context, String url, String prompt) async {
    // Download the image from the URL
    Uri pathUri = Uri.parse(url);
    final response = await http.get(pathUri);
    final bytes = response.bodyBytes;
    String fileName = prompt.replaceAll(' ', '').toLowerCase();
    String fileExt = p.extension(pathUri.path);
    if (fileExt.isEmpty) {
      fileExt = '.jpg';
    }
    int length = (fileName.length > 16 ? 16 : fileName.length);
    fileName = fileName.substring(0, length);
    Directory? downloadPath = await Utils.getDownloadsDir();
    final String? fileSavePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save Image",
      initialDirectory: downloadPath?.path,
      fileName: "$fileName$fileExt",
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg'],
    );
    if (fileSavePath == null) {
      return;
    }
    final file = File(fileSavePath);
    await file.writeAsBytes(bytes);
    if (context.mounted) {
      final SnackBar snackBar =
          SnackBar(content: Text('The image was saved to ${file.path}.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: const Text('Image Saved'),
      //     content: Text('The image was saved to ${file.path}.'),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.pop(context),
      //         child: const Text('OK'),
      //       ),
      //     ],
      //   ),
      // );
    }
  }
}
