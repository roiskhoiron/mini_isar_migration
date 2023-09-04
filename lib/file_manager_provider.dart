import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileManagerProvider {
  static final FileManagerProvider _instance = FileManagerProvider._init();

  String appSupportDirectory = '/storage/emulated/0';

  static FileManagerProvider get instance => _instance;

  factory FileManagerProvider() => _instance;

  static String root = '/VersionIsar';
  static String subMedia = '/Media';
  static String subBackups = '/Backups';
  static String subDatabases = '/Databases';
  static String subMediaAudio = '/Callink Audio';
  static String subMediaVideo = '/Callink Video';
  static String subMediaImages = '/Callink Images';
  static String subMediaDocuments = '/Callink Documents';
  static String subMediaStickers = '/Callink Stickers';

  FileManagerProvider._init();

  static Future<void> setup() async {
    await hasAcceptedPermissions();

    // var diverInfo = await DeviceInfoPlugin().androidInfo;
    //
    // if (diverInfo.version.sdkInt >= 31) {
    //   final directory = await getExternalStorageDirectory();
    //   if (directory == null) {
    //     print('External Storage Directory is null');
    //     final dir = await getApplicationSupportDirectory();
    //     _instance.appSupportDirectory = dir.path;
    //   } else {
    //     final path = directory.path;
    //     _instance.appSupportDirectory = path;
    //   }
    // }

    List folders = [
      root,
      subMedia,
      subBackups,
      subDatabases,
      subMediaAudio,
      subMediaVideo,
      subMediaImages,
      subMediaDocuments,
      subMediaStickers,
    ];

    if (Platform.isIOS) {
      _instance.appSupportDirectory =
          (await getApplicationSupportDirectory()).path;
    }

    for (var subFolder in folders) {
      await Directory('${_instance.appSupportDirectory}$root$subFolder')
          .create(recursive: true)
          .then((value) => print('Path of New Dir: ${value.path}'))
          .catchError((e) => print('Error create directory: $e'));
    }
  }

  static Future<bool> hasAcceptedPermissions() async {
    final storage = await _requestPermission(Permission.storage);
    final accessMediaLocation =
        await _requestPermission(Permission.accessMediaLocation);
    final external = await _requestPermission(Permission.manageExternalStorage);
    if (Platform.isAndroid) {
      if (storage && accessMediaLocation && external) {
        return true;
      } else {
        return false;
      }
    }
    if (Platform.isIOS) {
      if (await _requestPermission(Permission.photos)) {
        return true;
      } else {
        return false;
      }
    } else {
      // not android or ios
      return false;
    }
  }

  static Future<File> saveFile(
      {required String path, required File file}) async {
    final folder = '${_instance.appSupportDirectory}$root$path';
    final name = basename(file.path);

    if (FileManagerProvider.fileExists(path)) return file;
    print('new folder file : $folder/$name');
    final newFile = File('$folder/$name');
    await file.rename(newFile.path);
    return file;
  }

  static File readFile({required String path}) {
    return File(path);
  }

  static Future<bool> _requestPermission(Permission permission) async {
    return await permission.request().isGranted;
  }

  static String getPath({required String sub}) =>
      FileManagerProvider.instance.appSupportDirectory +
      FileManagerProvider.root +
      sub;

  static bool fileExists(String filePath) => File(filePath).existsSync();

  static void encryptFile(
      {required File file, required String keySecret}) async {
    final safeLocker = safeLockerSecret(keySafe: keySecret);
    final encryptedFile = File(file.path);

    final contents = await file.readAsBytes();
    final encryptedContents =
        safeLocker.value1.encryptBytes(contents, iv: safeLocker.value2);

    await encryptedFile.writeAsBytes(encryptedContents.bytes);
  }

  static Future<File> decryptFile(
      {required File encryptedFile, required String keySecret}) async {
    final safeLocker = safeLockerSecret(keySafe: keySecret);

    final path =
        '${await getApplicationDocumentsDirectory().then((value) => value.path)}/${basename(encryptedFile.path)}';
    // final path = encryptedFile.path;

    /// ifyou want see real data decrytped on directory with same filename
    final decryptedFile = File(path);

    final encryptedContents = await encryptedFile.readAsBytes();
    final decryptedBytes = safeLocker.value1
        .decryptBytes(Encrypted(encryptedContents), iv: safeLocker.value2);

    return await decryptedFile.writeAsBytes(decryptedBytes);
  }

  static Tuple2<Encrypter, IV> safeLockerSecret({required String keySafe}) {
    final keyLength = keySafe.padRight(16, '_');
    // print('myKey length : ${keyLength.length}');
    final key = Key.fromUtf8(keyLength);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return Tuple2(encrypter, iv);
  }
}
