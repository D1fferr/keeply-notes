import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/utils/logger.dart';

/// Helper methods for converting between Drift `content_json` strings and
/// `flutter_quill` [Document] / [Delta] structures.
abstract final class QuillDeltaHelper {
  /// Default empty Delta JSON representing an empty note.
  static const String emptyDeltaJson = '[{"insert":"\\n"}]';

  /// Deserializes a [contentJson] string into a Quill [Document].
  ///
  /// Returns a clean empty document if [contentJson] is null, empty,
  /// or malformed.
  static Document parseDocument(String? contentJson) {
    if (contentJson == null || contentJson.trim().isEmpty) {
      return Document();
    }

    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (e, st) {
      AppLogger.warning('Failed to parse Delta JSON: $e\n$st');
    }

    return Document();
  }

  /// Serializes a Quill [Document] to a compact Delta JSON string.
  static String documentToJson(Document document) {
    final delta = document.toDelta();
    final jsonList = delta.toJson();
    return jsonEncode(jsonList);
  }

  /// Extracts a plain text summary from a [contentJson] string for previews.
  static String extractPlainText(String? contentJson, {int maxLength = 120}) {
    if (contentJson == null || contentJson.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is List) {
        final doc = Document.fromJson(decoded);
        final plainText = doc.toPlainText().replaceAll('\n', ' ').trim();
        if (plainText.length <= maxLength) {
          return plainText;
        }
        return '${plainText.substring(0, maxLength)}...';
      }
    } catch (_) {
      // Fallback: return as-is or empty if non-parsable
    }

    return '';
  }

  /// Checks whether a [Document] has meaningful content (more than just a blank line).
  static bool isDocumentEmpty(Document document) {
    final plainText = document.toPlainText().trim();
    return plainText.isEmpty;
  }
}
