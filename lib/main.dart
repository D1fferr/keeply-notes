import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/folders/data/datasources/folder_local_data_source_impl.dart';
import 'features/folders/data/repositories/folder_repository_impl.dart';
import 'features/folders/domain/usecases/folder_crud_usecases.dart';
import 'features/folders/domain/usecases/watch_folders_usecase.dart';
import 'features/folders/presentation/cubit/folder_cubit.dart';
import 'features/folders/presentation/screens/folders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Bootstrap encrypted database ──────────────────────────────────────────
  final dbService = DatabaseService(
    secureStorageService: SecureStorageService(),
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
  final dataSource = FolderLocalDataSourceImpl(db);
  final repository = FolderRepositoryImpl(dataSource);

  final folderCubit = FolderCubit(
    watchRootFolders: WatchRootFoldersUseCase(repository),
    watchSubfolders: WatchSubfoldersUseCase(repository),
    getFolderById: GetFolderByIdUseCase(repository),
    createFolder: CreateFolderUseCase(repository),
    renameFolder: RenameFolderUseCase(repository),
    moveFolder: MoveFolderUseCase(repository),
    setFolderProtection: SetFolderProtectionUseCase(repository),
    deleteFolder: DeleteFolderUseCase(repository),
  );

  runApp(KeeplyNotesApp(folderCubit: folderCubit));
}

// ─── App root ─────────────────────────────────────────────────────────────────

class KeeplyNotesApp extends StatelessWidget {
  const KeeplyNotesApp({super.key, required this.folderCubit});

  final FolderCubit folderCubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: FoldersScreen(cubit: folderCubit),
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
