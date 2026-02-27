import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Handles picking/capturing a profile image and uploading it to Firebase Storage.
///
/// Storage path: workers/{uid}/profile_{timestamp}.jpg
///
/// Required packages (add to pubspec.yaml):
///   firebase_storage: ^12.0.0
///   image_picker: ^1.1.2
///
/// Android — add to android/app/src/main/AndroidManifest.xml inside <manifest>:
///   <uses-permission android:name="android.permission.CAMERA"/>
///
/// iOS — add to ios/Runner/Info.plist:
///   <key>NSCameraUsageDescription</key>
///   <string>Used to take your profile photo</string>
///   <key>NSPhotoLibraryUsageDescription</key>
///   <string>Used to pick your profile photo</string>

class ProfileImageService {
  static final _picker = ImagePicker();
  static final _storage = FirebaseStorage.instance;

  /// Pick image from gallery.
  static Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Capture image from camera.
  static Future<File?> captureFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload [file] to Firebase Storage and return the download URL.
  /// Path: workers/{uid}/profile_{timestamp}.jpg
  /// [onProgress] receives 0.0-1.0 upload progress.
  static Future<String> uploadProfileImage({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('workers/$uid/profile_$timestamp.jpg');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    await uploadTask;
    return await ref.getDownloadURL();
  }

  /// Delete old profile image from Storage by URL (best-effort, ignores errors).
  static Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Old image not found or already deleted — safe to ignore
    }
  }
}
