# Keeply Notes — Technical Specification & Development Architecture

## 📱 1. Project Overview
**Keeply Notes** is a fully autonomous (Offline-First) mobile application for Android and iOS designed for note-taking, organizing notes into multi-level hierarchical folders, setting flexible reminders, and performing end-to-end encrypted synchronization via Google Drive.

---

## 🛠 2. Tech Stack
* **Framework:** Flutter (Dart)
* **Local Database:** Drift (SQLite) with disk encryption via `sqflite_sqlcipher`
* **Local Notifications:** `flutter_local_notifications` + `timezone`
* **Authentication & Cloud:** `google_sign_in` + `googleapis` (Google Drive `appDataFolder`)
* **Biometrics:** `local_auth` (Face ID / Touch ID / Fingerprint / System PIN)
* **Rich Text Editor:** `flutter_quill` (supports bold, italic, lists, checkboxes, and inline image attachments)

---

## 🗄 3. Database Schema & Data Models

### Database Tables (Drift / SQLite):

1. **`folders`** (Folders):
   - `id` (Text UUID, PK)
   - `parent_id` (Text UUID, FK, Nullable) — Reference to parent folder for multi-level hierarchy
   - `name` (Text)
   - `is_protected` (Boolean) — Flag indicating biometric protection
   - `created_at` (DateTime), `updated_at` (DateTime), `is_deleted` (Boolean)

2. **`notes`** (Notes):
   - `id` (Text UUID, PK)
   - `folder_id` (Text UUID, FK, Nullable) — A note belongs strictly to 1 folder
   - `title` (Text)
   - `content_json` (Text) — Rich Text formatted as Delta JSON
   - `is_pinned` (Boolean)
   - `created_at` (DateTime), `updated_at` (DateTime), `is_deleted` (Boolean)

3. **`reminders`** (Primary Reminders):
   - `id` (Text UUID, PK)
   - `note_id` (Text UUID, FK, Unique) — Exactly 1 primary reminder per note
   - `start_date_time` (DateTime) — Base trigger time
   - `repeat_type` (Enum: `none`, `daily`, `weekly`, `monthly`, `yearly`, `custom_days`)
   - `custom_days_interval` (Int, Nullable) — E.g., repeat every 3 days
   - `is_enabled` (Boolean)

4. **`sub_reminders`** (Secondary / Snooze Reminders):
   - `id` (Text UUID, PK)
   - `reminder_id` (Text UUID, FK - CASCADE ON DELETE) — Up to 10 sub-reminders per primary reminder
   - `type` (Enum: `offset_minutes`, `exact_time`)
   - `offset_minutes` (Int, Nullable) — E.g., +10 min, +20 min
   - `exact_time` (Text, Nullable) — E.g., "20:00" on the same day

5. **`attachments`** (Media Attachments):
   - `id` (Text UUID, PK)
   - `note_id` (Text UUID, FK)
   - `local_path` (Text)
   - `file_size` (Int)

---

## ⚙️ 4. Subsystem Architecture & Business Rules

### A. Multilevel Folders & Recursive Query
- Supports arbitrary folder nesting depth via `parent_id`.
- Selecting a folder retrieves all notes in that folder AND all subfolders within its subtree using a recursive SQLite Common Table Expression (CTE) query:
  ```sql
  WITH RECURSIVE SubFolders AS (
      SELECT id FROM folders WHERE id = :targetFolderId
      UNION ALL
      SELECT f.id FROM folders f
      INNER JOIN SubFolders sf ON f.parent_id = sf.id
  )
  SELECT * FROM notes WHERE folder_id IN (SELECT id FROM SubFolders) AND is_deleted = 0;
  ```

### B. Reminders Engine & Secondary Reminders Logic
- **Entity Rules:**
  - Note without a reminder: `Valid`.
  - Primary reminder without sub-reminders: `Valid`.
  - Sub-reminders without a primary reminder: `Invalid` (Foreign Key `ON DELETE CASCADE`).
- **Maximum Sub-reminders:** Up to 10 sub-reminders per note/day.
- **Recurrence Lifecycle:** When a recurring primary reminder triggers (e.g. weekly), the next trigger date $D_{next}$ is computed, automatically rescheduling both the primary notification and all associated sub-reminders for that date.
- **OS Native Integration:** Uses Android Exact Alarms (`SCHEDULE_EXACT_ALARM`) and iOS `UNUserNotificationCenter`. Reschedules all active alarms upon device reboot (`RECEIVE_BOOT_COMPLETED`).

### C. Folder Protection (Biometrics & Access Control)
- Folders can be locked using system biometrics or system PIN/Passcode via `local_auth`.
- **Sync Behavior:** The `isProtected: true` flag syncs across devices. On a new device, the folder remains locked until authenticated via that device's local biometrics.
- **UI Isolation:** Notes from protected folders are hidden from general list views and global search results until the user unlocks the session.

### D. End-to-End Encryption & Google Drive Sync (E2EE & Sync)
- **Storage Strategy:** Item-level differential sync storing encrypted JSON blobs (`note_id.enc`, `folder_id.enc`) in Google Drive's hidden `appDataFolder`.
- **Conflict Resolution:** **Last-Write-Wins (LWW)** algorithm using UTC timestamps (`updatedAt`) and tombstone flags (`isDeleted`).
- **Key Derivation (Zero User Friction):**
  - Encryption Key is generated deterministically: `HKDF-SHA256(Google_User_ID + App_Salt)`.
  - No master passwords or manual PINs required from the user.
  - Logging into the same Google Account on any device deterministically derives the identical 256-bit AES-256-GCM key.
- **Disk Security:** The SQLite database is encrypted via SQLCipher (`AES-256`), and media attachments are stored as encrypted binary blobs on local storage.

### E. UI/UX Design Philosophy & Visual Identity
- **Minimalist Aesthetic:** Clean, decluttered, content-first interface with intuitive navigation and ample whitespace.
- **Color Palette & Tone:** Primary emphasis on crisp white backgrounds (`#FFFFFF`, `#FAFAFA`) complemented by soft, light warm color accents (warm cream, soft beige, subtle warm pastel highlights).
- **Typography & Components:** Material 3 and iOS Human Interface Guidelines compliance, featuring clean modern typography, subtle cards, soft rounded corners, and unobtrusive micro-interactions.

---

## 🚀 5. Implementation Roadmap

1. **Phase 1: Local Core & Database**
   - Initialize Flutter project.
   - Configure Drift DB + SQLCipher, define schemas, foreign keys, and indexes.
2. **Phase 2: Rich Text & Multilevel Folders**
   - Implement folder tree data structures and recursive CTE queries.
   - Integrate `flutter_quill`, image attachment handling, and local storage.
3. **Phase 3: Advanced Reminders Engine**
   - Integrate `flutter_local_notifications` and `timezone`.
   - Implement scheduling engine for primary recurrence and sub-reminders (up to 10).
4. **Phase 4: Security & Folder Protection**
   - Integrate `local_auth` (Face ID / Fingerprint / System PIN).
   - Implement folder lock state, session manager, and UI isolation.
5. **Phase 5: E2E Encryption & Google Drive Sync**
   - Integrate Google Sign-In and HKDF key generator.
   - Build `DriveSyncService` for item-level LWW sync and encrypted blob transfer.
6. **Phase 6: UI/UX & Polish**
   - Implement minimalist design theme (white & light warm colors), Dark/Light mode support, global search, and integration testing.
