import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/logger.dart';

/// Opens an encrypted SQLite database via SQLCipher PRAGMA key configuration.
LazyDatabase openEncryptedDatabase(String encryptionKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'keeply_notes.sqlite'));

    AppLogger.info('Opening SQLCipher encrypted database at: ${file.path}');

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // Execute SQLCipher PRAGMA key for AES-256 disk encryption
        rawDb.execute("PRAGMA key = '$encryptionKey';");
      },
    );
  });
}
