import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/dimensions.dart';
import '../network/supabase_storage_service.dart';
import 'app_select_field.dart';
import 'app_tappable.dart';
import 'custom_dialog.dart';

/// Tap-to-upload image field: opens a "Kameradan / Galereyadan" sheet,
/// shows the picked image immediately, uploads it to Supabase Storage in
/// the background, then reports the public URL via [onUploaded].
///
/// Used for product photos, the profile avatar and the company logo —
/// pass [bucket]/[folder]/[fileNameHint] to route each into its place
/// (see `supabase/storage_setup.sql` for the buckets themselves).
class AppImagePickerField extends StatefulWidget {
  const AppImagePickerField({
    super.key,
    required this.bucket,
    required this.onUploaded,
    this.folder,
    this.fileNameHint,
    this.initialUrl,
    this.size = 96,
    this.shape = BoxShape.rectangle,
    this.placeholderIcon = Icons.add_photo_alternate_outlined,
    this.placeholder,
    this.backgroundColor,
    this.borderColor,
    this.onError,
  });

  final String bucket;
  final String? folder;
  final String? fileNameHint;
  final String? initialUrl;
  final double size;
  final BoxShape shape;
  final IconData placeholderIcon;

  /// Overrides the default surface/border styling — used on the profile
  /// header where the field sits on a brand-color gradient instead of a
  /// plain page background.
  final Color? backgroundColor;
  final Color? borderColor;

  /// Shown in place of [placeholderIcon] when there's no image yet —
  /// e.g. the user's initials on the profile avatar.
  final Widget? placeholder;
  final ValueChanged<String> onUploaded;
  final VoidCallback? onError;

  @override
  State<AppImagePickerField> createState() => _AppImagePickerFieldState();
}

class _AppImagePickerFieldState extends State<AppImagePickerField> {
  String? _url;
  Uint8List? _localPreview;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  Future<void> _pick() async {
    final source = await AppPickerSheet.show<ImageSource>(
      context,
      title: 'Rasm tanlash',
      options: const [ImageSource.camera, ImageSource.gallery],
      labelOf: (s) => s == ImageSource.camera ? 'Kameradan suratga olish' : 'Galereyadan tanlash',
      iconOf: (s) => s == ImageSource.camera ? Icons.photo_camera_outlined : Icons.photo_library_outlined,
    );
    if (source == null || !mounted) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'Rasmga kirish imkoni bo‘lmadi — ruxsatlarni tekshiring', tone: ToastTone.danger);
      }
      return;
    }
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _localPreview = bytes;
      _uploading = true;
    });

    try {
      final url = await SupabaseStorageService.uploadImage(
        bucket: widget.bucket,
        bytes: bytes,
        folder: widget.folder,
        fileNameHint: widget.fileNameHint,
        extension: _extensionOf(picked.name),
      );
      if (!mounted) return;
      setState(() {
        _url = url;
        _uploading = false;
      });
      widget.onUploaded(url);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _localPreview = null;
      });
      AppToast.show(context, 'Rasm yuklanmadi — internetni tekshirib qayta urining', tone: ToastTone.danger);
      widget.onError?.call();
    }
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'jpg';
    return name.substring(dot + 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isCircle = widget.shape == BoxShape.circle;

    Widget content;
    if (_localPreview != null) {
      content = Image.memory(_localPreview!, fit: BoxFit.cover);
    } else if (_url != null) {
      content = CachedNetworkImage(
        imageUrl: _url!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Icon(widget.placeholderIcon, size: widget.size * 0.34, color: c.textTertiary),
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.textTertiary),
          ),
        ),
      );
    } else {
      content = widget.placeholder ??
          Icon(widget.placeholderIcon, size: widget.size * 0.34, color: c.textTertiary);
    }

    return AppTappable(
      onTap: _uploading ? null : _pick,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? c.surfaceMuted,
                shape: widget.shape,
                borderRadius: isCircle ? null : AppDimensions.brLarge,
                border: Border.all(color: widget.borderColor ?? c.border),
              ),
              child: Center(child: content),
            ),
            if (_uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: widget.shape,
                    borderRadius: isCircle ? null : AppDimensions.brLarge,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: isCircle ? 0 : -4,
              bottom: isCircle ? 0 : -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
