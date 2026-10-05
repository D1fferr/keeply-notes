import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import 'app_database.dart';
import 'database_opener.dart';

class DatabaseService {
  final SecureStorageService _secureStorageService;
  AppDatabase? _database;

  DatabaseService({SecureStorageService? secureStorageService})
      : _secureStorageService = secureStorageService ?? SecureStorageService();

  /// Returns the initialized AppDatabase instance.
  AppDatabase get database {
    if (_database == null) {
      throw StateError('DatabaseService has not been initialized. Call init() first.');
    }
    return _database!;
  }

  /// Initializes the encrypted database.
  Future<AppDatabase> init() async {
    if (_database != null) return _database!;

    try {
      AppLogger.info('Initializing encrypted database...');
      final key = await _secureStorageService.getOrCreateDatabaseKey();
      final executor = openEncryptedDatabase(key);
      _database = AppDatabase(executor);
      
      // Perform test query to verify database initialization
      await _database!.customSelect('SELECT 1').get();
      AppLogger.info('Encrypted database initialized successfully.');

      return _database!;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize encrypted database', e, stackTrace);
      rethrow;
    }
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('Database connection closed.');
    }
  }
}
