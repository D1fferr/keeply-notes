import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'core/database/database_service.dart';
import 'core/services/biometric_auth_service.dart';
import 'core/services/encryption_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/sync/data/repositories/google_auth_repository_impl.dart';
import 'features/sync/data/services/drive_sync_service.dart';
import 'features/sync/domain/services/hkdf_key_derivation_service.dart';
import 'features/sync/domain/services/sync_encryption_service.dart';
import 'features/sync/presentation/cubit/google_auth_cubit.dart';
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
import 'features/reminders/data/datasources/reminder_local_data_source_impl.dart';
import 'features/reminders/data/repositories/reminder_repository_impl.dart';
import 'features/reminders/domain/usecases/reminder_usecases.dart';

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

  // ── Bootstrap notification service & timezones ────────────────────────────
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e, st) {
    AppLogger.error('Warning: could not initialize NotificationService', e, st);
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
  final searchNotesUseCase = SearchNotesUseCase(noteRepository);

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

  // ── Wire up reminder feature (Native alarm scheduling) ─────────────────────
  final reminderDataSource = ReminderLocalDataSourceImpl(db);
  final reminderRepository = ReminderRepositoryImpl(
    dataSource: reminderDataSource,
    notificationService: notificationService,
  );

  final watchReminderForNoteUseCase =
      WatchReminderForNoteUseCase(reminderRepository);
  final setReminderUseCase = SetReminderUseCase(reminderRepository);
  final deleteReminderUseCase = DeleteReminderUseCase(reminderRepository);
  final rescheduleAllRemindersUseCase =
      RescheduleAllRemindersUseCase(reminderRepository);
  final getSubRemindersUseCase = GetSubRemindersUseCase(reminderRepository);
  final setSubRemindersUseCase = SetSubRemindersUseCase(reminderRepository);

  // ── Bootstrap biometric security & session manager ─────────────────────────
  final biometricAuthService = BiometricAuthService();
  final sessionManager = SessionManager(authService: biometricAuthService);

  // ── Bootstrap Google Drive auth & sync ────────────────────────────────────
  final googleAuthService = GoogleAuthService();
  final googleAuthRepository = GoogleAuthRepositoryImpl(googleAuthService);
  final driveSyncService = DriveSyncService(
    db: db,
    authRepository: googleAuthRepository,
    keyEngine: const SyncKeyDerivationEngine(),
    encryptionService: const SyncEncryptionService(),
  );
  final googleAuthCubit = GoogleAuthCubit(
    authRepository: googleAuthRepository,
    driveSyncService: driveSyncService,
  );

  // ── Bootstrap theme mode cubit ─────────────────────────────────────────────
  final themeModeCubit = ThemeModeCubit();

  // Reschedule active reminders on app startup (e.g. after reboot or process recreate)
  try {
    await rescheduleAllRemindersUseCase();
  } catch (e, st) {
    AppLogger.error('Failed to reschedule reminders on startup', e, st);
  }

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
    watchReminderForNoteUseCase: watchReminderForNoteUseCase,
    setReminderUseCase: setReminderUseCase,
    deleteReminderUseCase: deleteReminderUseCase,
    getSubRemindersUseCase: getSubRemindersUseCase,
    setSubRemindersUseCase: setSubRemindersUseCase,
    searchNotesUseCase: searchNotesUseCase,
    sessionManager: sessionManager,
    biometricAuthService: biometricAuthService,
    googleAuthCubit: googleAuthCubit,
    themeModeCubit: themeModeCubit,
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
    required this.watchReminderForNoteUseCase,
    required this.setReminderUseCase,
    required this.deleteReminderUseCase,
    required this.getSubRemindersUseCase,
    required this.setSubRemindersUseCase,
    this.searchNotesUseCase,
    this.sessionManager,
    this.biometricAuthService,
    this.googleAuthCubit,
    this.themeModeCubit,
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

  final WatchReminderForNoteUseCase watchReminderForNoteUseCase;
  final SetReminderUseCase setReminderUseCase;
  final DeleteReminderUseCase deleteReminderUseCase;
  final GetSubRemindersUseCase getSubRemindersUseCase;
  final SetSubRemindersUseCase setSubRemindersUseCase;

  final SearchNotesUseCase? searchNotesUseCase;
  final SessionManager? sessionManager;
  final BiometricAuthService? biometricAuthService;
  final GoogleAuthCubit? googleAuthCubit;
  final ThemeModeCubit? themeModeCubit;

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the theme mode changes.
    if (themeModeCubit != null) {
      return ListenableBuilder(
        listenable: themeModeCubit!,
        builder: (context, _) => _buildApp(themeModeCubit!.mode),
      );
    }
    return _buildApp(ThemeMode.system);
  }

  Widget _buildApp(ThemeMode themeMode) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
        watchReminderForNoteUseCase: watchReminderForNoteUseCase,
        setReminderUseCase: setReminderUseCase,
        deleteReminderUseCase: deleteReminderUseCase,
        getSubRemindersUseCase: getSubRemindersUseCase,
        setSubRemindersUseCase: setSubRemindersUseCase,
        searchNotesUseCase: searchNotesUseCase,
        sessionManager: sessionManager,
        biometricAuthService: biometricAuthService,
        googleAuthCubit: googleAuthCubit,
        themeModeCubit: themeModeCubit,
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
