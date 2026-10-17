import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/core/database/app_database.dart';
import 'package:keeply_notes/core/services/biometric_auth_service.dart';
import 'package:keeply_notes/core/services/session_manager.dart';
import 'package:keeply_notes/features/folders/data/datasources/folder_local_data_source_impl.dart';
import 'package:keeply_notes/features/notes/data/datasources/note_local_data_source_impl.dart';
import 'package:keeply_notes/features/notes/data/repositories/note_repository_impl.dart';
import 'package:keeply_notes/features/notes/domain/usecases/note_crud_usecases.dart';

class _FakeBiometricAuthService implements BiometricAuthService {
  bool shouldSucceed = true;
  int authCallCount = 0;

  @override
  Future<bool> authenticate({String localizedReason = 'Authenticate to access protected content'}) async {
    authCallCount++;
    return shouldSucceed;
  }

  @override
  Future<bool> canCheckBiometrics() async => true;

  @override
  Future<List<dynamic>> getAvailableBiometrics() async => [];

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Protected Folders UI & Access Control Tests (Task 5.2)', () {
    late AppDatabase db;
    late FolderLocalDataSourceImpl folderDataSource;
    late NoteLocalDataSourceImpl noteDataSource;
    late NoteRepositoryImpl noteRepository;
    late WatchAllNotesUseCase watchAllNotesUseCase;
    late SearchNotesUseCase searchNotesUseCase;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      folderDataSource = FolderLocalDataSourceImpl(db);
      noteDataSource = NoteLocalDataSourceImpl(db);
      noteRepository = NoteRepositoryImpl(noteDataSource);
      watchAllNotesUseCase = WatchAllNotesUseCase(noteRepository);
      searchNotesUseCase = SearchNotesUseCase(noteRepository);
    });

    tearDown(() async {
      await db.close();
    });

    test('watchAllNotes excludes notes in protected folders and subtrees when locked', () async {
      final now = DateTime.now();

      // 1. Create a public folder
      await folderDataSource.insertFolder(
        id: 'public-folder',
        name: 'Public Folder',
        isProtected: false,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Create a protected folder
      await folderDataSource.insertFolder(
        id: 'secret-folder',
        name: 'Secret Folder',
        isProtected: true,
        createdAt: now,
        updatedAt: now,
      );

      // 3. Create a subfolder inside the secret folder
      await folderDataSource.insertFolder(
        id: 'nested-secret-folder',
        name: 'Nested Secret Folder',
        parentId: 'secret-folder',
        isProtected: false,
        createdAt: now,
        updatedAt: now,
      );

      // 4. Create notes
      await noteRepository.createNote(
        title: 'Root Note',
        contentJson: '[]',
      );
      await noteRepository.createNote(
        folderId: 'public-folder',
        title: 'Public Note',
        contentJson: '[]',
      );
      await noteRepository.createNote(
        folderId: 'secret-folder',
        title: 'Secret Note',
        contentJson: '[]',
      );
      await noteRepository.createNote(
        folderId: 'nested-secret-folder',
        title: 'Nested Secret Note',
        contentJson: '[]',
      );

      // When includeProtected = true (unlocked session)
      final allNotes = await watchAllNotesUseCase(includeProtected: true).first;
      expect(allNotes.length, equals(4));

      // When includeProtected = false (locked session)
      final publicNotes = await watchAllNotesUseCase(includeProtected: false).first;
      expect(publicNotes.length, equals(2));
      final titles = publicNotes.map((n) => n.title).toSet();
      expect(titles, contains('Root Note'));
      expect(titles, contains('Public Note'));
      expect(titles, isNot(contains('Secret Note')));
      expect(titles, isNot(contains('Nested Secret Note')));
    });

    test('searchNotes filters out notes from protected folders when includeProtected is false', () async {
      final now = DateTime.now();

      await folderDataSource.insertFolder(
        id: 'protected-folder',
        name: 'Passwords & Financials',
        isProtected: true,
        createdAt: now,
        updatedAt: now,
      );

      await noteRepository.createNote(
        title: 'Bank accounts overview',
        contentJson: '[]',
      );
      await noteRepository.createNote(
        folderId: 'protected-folder',
        title: 'Secret bank password',
        contentJson: '[]',
      );

      // Search with includeProtected = true
      final unlockedResults = await searchNotesUseCase('bank', includeProtected: true);
      expect(unlockedResults.length, equals(2));

      // Search with includeProtected = false
      final lockedResults = await searchNotesUseCase('bank', includeProtected: false);
      expect(lockedResults.length, equals(1));
      expect(lockedResults.first.title, equals('Bank accounts overview'));
    });

    test('SessionManager gating correctly controls access to protected folders', () async {
      final fakeAuth = _FakeBiometricAuthService();
      final sessionManager = SessionManager(authService: fakeAuth);

      expect(sessionManager.isUnlocked, isFalse);

      // Authenticate succeeds
      fakeAuth.shouldSucceed = true;
      final success = await sessionManager.authenticateAndUnlock();
      expect(success, isTrue);
      expect(sessionManager.isUnlocked, isTrue);
      expect(fakeAuth.authCallCount, equals(1));

      // Manual lock resets session
      sessionManager.lock();
      expect(sessionManager.isUnlocked, isFalse);

      // Authenticate fails
      fakeAuth.shouldSucceed = false;
      final fail = await sessionManager.authenticateAndUnlock();
      expect(fail, isFalse);
      expect(sessionManager.isUnlocked, isFalse);
    });
  });
}
