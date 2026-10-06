import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/usecases/attachment_usecases.dart';

/// Renders an AES-256 encrypted image from local disk by decrypting it in-memory.
///
/// Features:
/// - In-memory decrypted byte caching for smooth scrolling
/// - Shimmer / progress placeholder during decryption
/// - Error handling for missing or unreadable files
class EncryptedImageView extends StatefulWidget {
  const EncryptedImageView({
    super.key,
    required this.localPath,
    required this.getDecryptedAttachmentBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final String localPath;
  final GetDecryptedAttachmentBytesUseCase getDecryptedAttachmentBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  State<EncryptedImageView> createState() => _EncryptedImageViewState();
}

class _EncryptedImageViewState extends State<EncryptedImageView> {
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAndDecrypt();
  }

  @override
  void didUpdateWidget(covariant EncryptedImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath) {
      _loadAndDecrypt();
    }
  }

  Future<void> _loadAndDecrypt() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await widget.getDecryptedAttachmentBytes(widget.localPath);
      if (mounted) {
        setState(() {
          _decryptedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.primaryWarmLight.withOpacity(0.5),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_hasError || _decryptedBytes == null) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    } else {
      content = Image.memory(
        _decryptedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: content,
    );
  }
}
