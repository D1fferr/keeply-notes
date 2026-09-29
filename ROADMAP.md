# Keeply Notes — Step-by-Step Implementation Roadmap

This document breaks down the development of **Keeply Notes** into modular, atomic, and cohesive tasks. Each task represents a self-contained unit of work designed to leave the codebase in a clean, compilable, and testable state.

---

## 🏗 Phase 1: Project Setup & Encrypted Database Foundation

- [x] **Task 1.1: Flutter Project Initialization & Project Structure**
  - Initialize Flutter app supporting Android and iOS.
  - Setup feature-first clean architecture directory layout (`lib/core/`, `lib/features/`).
  - Add core dependencies (`drift`, `sqflite_sqlcipher`, `flutter_secure_storage`, `uuid`, etc.) in `pubspec.yaml`.

- [x] **Task 1.2: Drift Database Schemas & Data Models**
  - Define Drift tables: `Folders`, `Notes`, `Reminders`, `SubReminders`, and `Attachments`.
  - Configure foreign keys (with `ON DELETE CASCADE` for sub-reminders) and indices.
  - Run `build_runner` to generate Drift database code.

- [x] **Task 1.3: SQLCipher Disk Encryption & Database Wiring**
  - Configure `sqflite_sqlcipher` database opener.
  - Implement secure database key generation and storage via `flutter_secure_storage`.
  - Verify database initialization and local encrypted storage.

---

## 📁 Phase 2: Multilevel Folders & Folder Navigation

- [ ] **Task 2.1: Folder Repository & Recursive CTE Queries**
  - Implement CRUD operations for folders in Drift.
  - Write recursive SQLite CTE query in Drift to retrieve all subfolders and notes within a folder subtree.

- [ ] **Task 2.2: Folder Tree UI & Breadcrumb Navigation**
  - Build minimalist UI for viewing and managing folder hierarchy.
  - Add breadcrumb navigation bar (`Home > Folder > Subfolder`).
  - Add folder creation, renaming, moving, and deletion dialogs.

---

## 📝 Phase 3: Rich Text Editor & Media Attachments

- [ ] **Task 3.1: Rich Text Note Editor Integration**
  - Integrate `flutter_quill` WYSIWYG editor.
  - Build formatting toolbar (bold, italic, headers, bullet lists, checkboxes).
  - Implement note creation and editing saving Delta JSON to Drift.

- [ ] **Task 3.2: Local Media Attachment & Disk Encryption**
  - Implement image picking and local saving to app documents directory.
  - Add image preview rendering inside note editor.
  - Encrypt local image files on disk using AES-256 stream encryption.

---

## ⏰ Phase 4: Advanced Reminders & Sub-reminders Engine

- [ ] **Task 4.1: Local Notifications Setup & Timezones**
  - Integrate `flutter_local_notifications` and `timezone` packages.
  - Configure native notification channels for Android and permissions for iOS.

- [ ] **Task 4.2: Primary Reminder Scheduling Engine**
  - Implement date recurrence calculator (`none`, `daily`, `weekly`, `monthly`, `yearly`, `custom_days`).
  - Build native notification scheduler for primary reminders.
  - Add Android boot receiver (`RECEIVE_BOOT_COMPLETED`) to reschedule notifications upon device reboot.

- [ ] **Task 4.3: Secondary Sub-reminders Engine (Up to 10)**
  - Implement sub-reminder time calculator (`offset_minutes` & `exact_time`).
  - Schedule sub-reminders alongside primary reminder triggers.
  - Enforce cascading deletion/cancellation of sub-reminders when primary reminder is removed.

---

## 🔒 Phase 5: Biometric Security & Protected Folders

- [ ] **Task 5.1: Biometric Authentication & Session Manager**
  - Integrate `local_auth` for Face ID / Touch ID / Fingerprint / System PIN authentication.
  - Implement `SessionManager` to track global biometric unlock states.

- [ ] **Task 5.2: Protected Folders UI & Access Control**
  - Add folder lock toggle and 🔒 status indicator.
  - Filter out notes in protected folders from general note lists and global search when locked.
  - Prompt biometric unlock when tapping to open a protected folder.

---

## ☁️ Phase 6: End-to-End Encrypted Google Drive Sync

- [ ] **Task 6.1: Google Authentication & Drive API Setup**
  - Integrate `google_sign_in` requesting `appDataFolder` scope.
  - Implement authentication state management and token refresh handlers.

- [ ] **Task 6.2: E2EE Key Derivation Engine (HKDF)**
  - Implement `HKDF-SHA256` key generator using `Google User ID` + App Salt.
  - Build `AES-256-GCM` encryption/decryption utility for sync payloads.

- [ ] **Task 6.3: Item-Level Sync Engine (Last-Write-Wins)**
  - Build `DriveSyncService` to upload and download encrypted `.enc` item blobs to Google Drive `appDataFolder`.
  - Implement Last-Write-Wins (LWW) conflict resolution strategy using UTC `updatedAt` timestamps and tombstone deletion flags.
  - Implement media attachment sync to Google Drive.

---

## 🎨 Phase 7: UI Theme, Global Search & Final Polish

- [ ] **Task 7.1: Minimalist UI Theme & Color Palette**
  - Implement Material 3 light theme featuring crisp white (`#FFFFFF`, `#FAFAFA`) backgrounds and light warm cream accents.
  - Implement dark mode theme.

- [ ] **Task 7.2: Global Search & Filter System**
  - Build instant search engine across note titles and content (respecting folder lock states).
  - Add quick filter chips (e.g. "Has Reminders", "Pinned").

- [ ] **Task 7.3: Testing & Quality Assurance**
  - Write unit tests for reminder recurrence logic, CTE queries, and E2EE key derivation.
  - Conduct end-to-end testing of offline behavior and Google Drive sync recovery.
