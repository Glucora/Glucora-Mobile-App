import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:glucora_ai_companion/services/profile_picture_service.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
class ProfilePicture extends StatefulWidget {
  final String userId;
  final String? imageUrl;
  final double size;
  final bool isEditable;
  final VoidCallback? onPictureChanged;
  final bool showInitials;
  final String? displayName;

  const ProfilePicture({
    super.key,
    required this.userId,
    this.imageUrl,
    this.size = 90,
    this.isEditable = false,
    this.onPictureChanged,
    this.showInitials = true,
    this.displayName,
  });

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
  }

  String get _initials {
    if (!widget.showInitials || widget.displayName == null) return '';
    final nameParts = widget.displayName!.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return widget.displayName![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: widget.isEditable ? _showImagePickerOptions : null,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildContent(colors),
            ),
          ),
          if (widget.isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

Widget _buildContent(dynamic colors) {  // ✅ Changed from GlucoraColors to dynamic
  if (_imageUrl != null && _imageUrl!.isNotEmpty) {
    return Image.network(
      _imageUrl!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback(colors);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
  return _buildFallback(colors);
}

Widget _buildFallback(dynamic colors) {  // ✅ Changed from GlucoraColors to dynamic
  if (widget.showInitials && _initials.isNotEmpty) {
    return Center(
      child: TranslatedText(
        _initials,
        style: TextStyle(
          fontSize: widget.size * 0.35,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }
  return Icon(
    Icons.person_rounded,
    size: widget.size * 0.5,
    color: colors.primary,
  );
}
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const TranslatedText('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const TranslatedText('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            if (_imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const TranslatedText(
                  'Remove Picture',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _removePicture();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    
    File? imageFile;
    if (source == ImageSource.gallery) {
      imageFile = await ProfilePictureService.pickImageFromGallery();
    } else {
      imageFile = await ProfilePictureService.takePhoto();
    }
    
    if (imageFile != null) {
      final url = await ProfilePictureService.uploadProfilePicture(
        imageFile,
        widget.userId,
      );
      
      if (url != null && mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
        widget.onPictureChanged?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Failed to update picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removePicture() async {
    setState(() => _isLoading = true);
    
    final success = await ProfilePictureService.deleteProfilePicture(widget.userId);
    
    if (success && mounted) {
      setState(() {
        _imageUrl = null;
        _isLoading = false;
      });
      widget.onPictureChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Profile picture removed'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Failed to remove picture'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}