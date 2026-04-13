import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; 
class ProfilePictureService {
  static final supabase = Supabase.instance.client;
  static const String _bucketName = 'profile-pictures';

  // Initialize storage bucket if not exists
  static Future<void> initializeBucket() async {
    try {
      final buckets = await supabase.storage.listBuckets();
      final exists = buckets.any((b) => b.name == _bucketName);
      
      if (!exists) {
        await supabase.storage.createBucket(_bucketName,
          const BucketOptions(public: true)
        );
      }
    } catch (e) {
      debugPrint('Error initializing bucket: $e');
    }
  }

  // Upload profile picture
  static Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '$userId.$fileExtension';
      final filePath = fileName;
      
      await supabase.storage.from(_bucketName).upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      final publicUrl = supabase.storage.from(_bucketName).getPublicUrl(filePath);
      
      // Update user profile with picture URL
      await supabase
          .from('users')
          .update({'profile_picture_url': publicUrl})
          .eq('id', userId);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  // Delete profile picture
  static Future<bool> deleteProfilePicture(String userId) async {
    try {
      // Get current user data
      final userData = await supabase
          .from('users')
          .select('profile_picture_url')
          .eq('id', userId)
          .single();
      
      final currentUrl = userData['profile_picture_url'] as String?;
      
      if (currentUrl != null && currentUrl.isNotEmpty) {
        // Extract file name from URL
        final fileName = currentUrl.split('/').last;
        await supabase.storage.from(_bucketName).remove([fileName]);
      }
      
      // Update database
      await supabase
          .from('users')
          .update({'profile_picture_url': null})
          .eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      return false;
    }
  }

  // Get profile picture URL
  static Future<String?> getProfilePictureUrl(String userId) async {
    try {
      final userData = await supabase
          .from('users')
          .select('profile_picture_url')
          .eq('id', userId)
          .single();
      
      return userData['profile_picture_url'] as String?;
    } catch (e) {
      debugPrint('Error getting profile picture: $e');
      return null;
    }
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  // Take photo with camera
  static Future<File?> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }
}