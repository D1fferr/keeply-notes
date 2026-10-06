import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/encryption_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/folders/data/datasources/folder_local_data_source_impl.dart';
import 'features/folders/data/repositories/folder_repository_impl.dart';
import 'features/folders/domain/usecases/folder_crud_usecases.dart';
import 'features/folders/domain/usecases/watch_folders_usecase.dart';
import 'features/folders/presentation/cubit/folder_cubit.dart';
import 'features/folders/presentation/screens/folders_screen.dart';
import 'features/notes/data/datasources/attachment_local_data_source_impl.dart';
import 'features/notes/data/datasources/note_local_data_source_impl.dart';
import 'features/notes/data/repositories/attachment_repository_impl.dart';
import 'features/notes/data/repositories/note_repository_impl.dart';
import 'features/notes/domain/usecases/attachment_usecases.dart';
import 'features/notes/domain/usecases/note_crud_usecases.dart';
import 'features/notes/presentation/cubit/notes_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorageService = SecureStorageService();
  final encryptionService = const EncryptionService();

  // ── Bootstrap encrypted database ──────────────────────────────────────────
  final dbService = DatabaseService(
    secureStorageService: secureStorageService,
  );

  try {
    await dbService.init();
  } catch (e, st) {
    AppLogger.error('Fatal: could not initialize database', e, st);
    // Surface a minimal error UI rather than a blank screen.
    runApp(const _DatabaseErrorApp());
    return;
  }

  final db = dbService.database;

  // ── Wire up folder feature ─────────────────────────────────────────────────
  final folderDataSource = FolderLocalDataSourceImpl(db);
  final folderRepository = FolderRepositoryImpl(folderDataSource);

  final folderCubit = FolderCubit(
    watchRootFolders: WatchRootFoldersUseCase(folderRepository),
    watchSubfolders: WatchSubfoldersUseCase(folderRepository),
    getFolderById: GetFolderByIdUseCase(folderRepository),
    createFolder: CreateFolderUseCase(folderRepository),
    renameFolder: RenameFolderUseCase(folderRepository),
    moveFolder: MoveFolderUseCase(folderRepository),
    setFolderProtection: SetFolderProtectionUseCase(folderRepository),
    deleteFolder: DeleteFolderUseCase(folderRepository),
  );

  // ── Wire up note feature ───────────────────────────────────────────────────
  final noteDataSource = NoteLocalDataSourceImpl(db);
  final noteRepository = NoteRepositoryImpl(noteDataSource);

  final createNoteUseCase = CreateNoteUseCase(noteRepository);
  final updateNoteUseCase = UpdateNoteUseCase(noteRepository);
  final deleteNoteUseCase = DeleteNoteUseCase(noteRepository);
  final togglePinNoteUseCase = TogglePinNoteUseCase(noteRepository);
  final moveNoteUseCase = MoveNoteUseCase(noteRepository);
  final watchNotesInFolderUseCase = WatchNotesInFolderUseCase(noteRepository);

  final notesCubit = NotesCubit(
    watchNotesInFolder: watchNotesInFolderUseCase,
    togglePinNote: togglePinNoteUseCase,
    deleteNote: deleteNoteUseCase,
    moveNote: moveNoteUseCase,
  );

  // ── Wire up attachment feature (AES-256 disk encryption) ───────────────────
  final attachmentDataSource = AttachmentLocalDataSourceImpl(db);
  final attachmentRepository = AttachmentRepositoryImpl(
    dataSource: attachmentDataSource,
    encryptionService: encryptionService,
    secureStorageService: secureStorageService,
  );

  final saveAttachmentUseCase = SaveAttachmentUseCase(attachmentRepository);
  final getDecryptedAttachmentBytesUseCase =
      GetDecryptedAttachmentBytesUseCase(attachmentRepository);
  final watchNoteAttachmentsUseCase =
      WatchNoteAttachmentsUseCase(attachmentRepository);
  final deleteAttachmentUseCase = DeleteAttachmentUseCase(attachmentRepository);

  runApp(KeeplyNotesApp(
    folderCubit: folderCubit,
    notesCubit: notesCubit,
    createNoteUseCase: createNoteUseCase,
    updateNoteUseCase: updateNoteUseCase,
    deleteNoteUseCase: deleteNoteUseCase,
    saveAttachmentUseCase: saveAttachmentUseCase,
    getDecryptedAttachmentBytesUseCase: getDecryptedAttachmentBytesUseCase,
    watchNoteAttachmentsUseCase: watchNoteAttachmentsUseCase,
    deleteAttachmentUseCase: deleteAttachmentUseCase,
  ));
}

// ─── App root ─────────────────────────────────────────────────────────────────

class KeeplyNotesApp extends StatelessWidget {
  const KeeplyNotesApp({
    super.key,
    required this.folderCubit,
    required this.notesCubit,
    required this.createNoteUseCase,
    required this.updateNoteUseCase,
    required this.deleteNoteUseCase,
    required this.saveAttachmentUseCase,
    required this.getDecryptedAttachmentBytesUseCase,
    required this.watchNoteAttachmentsUseCase,
    required this.deleteAttachmentUseCase,
  });

  final FolderCubit folderCubit;
  final NotesCubit notesCubit;
  final CreateNoteUseCase createNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;

  final SaveAttachmentUseCase saveAttachmentUseCase;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytesUseCase;
  final WatchNoteAttachmentsUseCase watchNoteAttachmentsUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: FoldersScreen(
        folderCubit: folderCubit,
        notesCubit: notesCubit,
        createNoteUseCase: createNoteUseCase,
        updateNoteUseCase: updateNoteUseCase,
        deleteNoteUseCase: deleteNoteUseCase,
        saveAttachmentUseCase: saveAttachmentUseCase,
        getDecryptedAttachmentBytesUseCase: getDecryptedAttachmentBytesUseCase,
        watchNoteAttachmentsUseCase: watchNoteAttachmentsUseCase,
        deleteAttachmentUseCase: deleteAttachmentUseCase,
      ),
    );
  }
}

// ─── Fallback error screen ────────────────────────────────────────────────────

class _DatabaseErrorApp extends StatelessWidget {
  const _DatabaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Could not open the secure database.\n'
                  'Please restart the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
