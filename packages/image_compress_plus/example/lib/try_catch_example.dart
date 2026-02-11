import 'dart:async';

import 'package:image_compress_plus/image_compress_plus.dart';

class TryCatchExample {
  Future<List<int>?> compressAndTryCatch(String path) async {
    List<int>? result;
    try {
      result = await ImageCompressPlus.compressWithFile(
        path,
        format: CompressFormat.heic,
      );
    } on UnsupportedError catch (e) {
      print(e.message);
      result = await ImageCompressPlus.compressWithFile(
        path,
        format: CompressFormat.jpeg,
      );
    } on Error catch (e) {
      print(e.toString());
      print(e.stackTrace);
    } on Exception catch (e) {
      print(e.toString());
    }
    return result;
  }
}
