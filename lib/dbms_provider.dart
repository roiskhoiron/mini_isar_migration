import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:mini_isar_migration/main.dart';

import 'file_manager_provider.dart';

// late final Future<Isar> isar;

class DbmsProvider {
  Isar isar;

  static List<CollectionSchema> databaseSchemas = [CountSchema];

  DbmsProvider({required this.isar});

  IsarCollection readCollections({required TableEnum tableEnum}) {
    var collect = {
      TableEnum.tableCount: isar.counts,
    };

    return collect[tableEnum] as IsarCollection;
  }

  dbInsert({required TableEnum tableEnum, required dynamic object}) async {
    await isar.writeTxn(() async {
      var collect = readCollections(tableEnum: tableEnum);
      await collect.put(object);
    });
  }

  dbInsertAll({required TableEnum tableEnum, required List list}) async {
    await isar.writeTxn(() async {
      var collect = readCollections(tableEnum: tableEnum);
      await collect.putAll(list);
    });
  }

  dbDelete({required TableEnum tableEnum, required int id}) async {
    await isar.writeTxn(() async {
      var collect = readCollections(tableEnum: tableEnum);
      await collect.delete(id);
    });
  }

  reset() async => await isar.writeTxn(() async => await isar.clear());

  Future<void> restore({required String key, required String user}) async {
    for (var schema in DbmsProvider.databaseSchemas) {
      final path =
          '${FileManagerProvider.getPath(sub: FileManagerProvider.subBackups)}/V1_${schema.name}_$user.json';

      if (FileManagerProvider.fileExists(path)) {
        final schemaData = await FileManagerProvider.decryptFile(
            encryptedFile: File(path), keySecret: key);
        String schemaJson = await schemaData.readAsString();
        final jsonData =
            List<Map<String, dynamic>>.from(jsonDecode(schemaJson));

        print('''
        restore schema : `${schema.name}`
        path : $path 
        data length : ${jsonData.length}
        payload : $jsonData
        ''');
        switch (schema) {
          case CountSchema:
            await isar.writeTxn(() => isar.counts.importJson(jsonData));
            break;

          default:
        }
      }
    }
  }

  backup({required String user, required String key}) async {
    for (var schema in DbmsProvider.databaseSchemas) {
      List<Map<String, dynamic>>? stringJson;
      switch (schema) {
        case CountSchema:
          stringJson = await isar.counts.where().exportJson();
          break;
      }
      final jsonString = jsonEncode(stringJson);
      File jsonFile = File(
          '${FileManagerProvider.getPath(sub: FileManagerProvider.subBackups)}/V${Env.dbVersion}_${schema.name}_$user.json');
      if (FileManagerProvider.fileExists(jsonFile.path)) {
        File(jsonFile.path).deleteSync();
      }
      jsonFile.writeAsStringSync(jsonString);

      FileManagerProvider.encryptFile(file: jsonFile, keySecret: key);
    }
  }
}

Future<Isar> initIsar() async {
  await FileManagerProvider.setup();

  final isarInit = await Isar.open(DbmsProvider.databaseSchemas,
      name: '${Env.dbName}_V${Env.dbVersion}',
      inspector: true,
      directory:
          FileManagerProvider.getPath(sub: FileManagerProvider.subDatabases));
  return isarInit;
}

class Env {
  static int get dbVersion => 2;
  static String get dbName => 'migrationApp';
}

enum TableEnum { tableCount }
