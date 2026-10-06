import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keeply_notes/features/notes/presentation/utils/quill_delta_helper.dart';

void main() {
  group('QuillDeltaHelper Unit Tests', () {
    test('parseDocument with null returns empty document', () {
      final doc = QuillDeltaHelper.parseDocument(null);
      expect(doc, isNotNull);
      expect(QuillDeltaHelper.isDocumentEmpty(doc), isTrue);
    });

    test('parseDocument with empty string returns empty document', () {
      final doc = QuillDeltaHelper.parseDocument('');
      expect(doc, isNotNull);
      expect(QuillDeltaHelper.isDocumentEmpty(doc), isTrue);
    });

    test('parseDocument with malformed json returns fallback document', () {
      final doc = QuillDeltaHelper.parseDocument('{ invalid json');
      expect(doc, isNotNull);
      expect(QuillDeltaHelper.isDocumentEmpty(doc), isTrue);
    });

    test('parseDocument with valid Delta JSON loads content correctly', () {
      final deltaJson = jsonEncode([
        {'insert': 'Hello Keeply Notes!\\n'}
      ]);

      final doc = QuillDeltaHelper.parseDocument(deltaJson);
      expect(doc, isNotNull);
      expect(QuillDeltaHelper.isDocumentEmpty(doc), isFalse);
      expect(doc.toPlainText().contains('Hello Keeply Notes!'), isTrue);
    });

    test('documentToJson serializes Delta correctly', () {
      final doc = Document()..insert(0, 'Rich text content');
      final jsonString = QuillDeltaHelper.documentToJson(doc);

      expect(jsonString, isNotEmpty);
      final decoded = jsonDecode(jsonString);
      expect(decoded, isA<List>());
      expect(decoded.first['insert'], contains('Rich text content'));
    });

    test('extractPlainText returns clean snippet and truncates', () {
      final deltaJson = jsonEncode([
        {'insert': 'First line of note\\nSecond line of note\\n'}
      ]);

      final snippet = QuillDeltaHelper.extractPlainText(deltaJson, maxLength: 20);
      expect(snippet.startsWith('First line of note'), isTrue);
      expect(snippet.endsWith('...'), isTrue);
      expect(snippet.contains('\n'), isFalse);
    });

    test('extractPlainText with null or invalid JSON returns empty string', () {
      expect(QuillDeltaHelper.extractPlainText(null), equals(''));
      expect(QuillDeltaHelper.extractPlainText(''), equals(''));
      expect(QuillDeltaHelper.extractPlainText('not json'), equals(''));
    });
  });
}
