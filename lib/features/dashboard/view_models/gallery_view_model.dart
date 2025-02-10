import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryViewModel extends ChangeNotifier {
  List<AssetEntity> _images = [];
  bool _isLoading = true;
  String? _error;

  List<AssetEntity> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchImages() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      // Request permissions using the correct method
      final PermissionState permissionState =
          await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image, // Only request image access initially
            mediaLocation: false, // Don't request location by default
          ),
        ),
      );

      if (!permissionState.hasAccess) {
        _error =
            "Permission denied. Please grant access to photos in settings.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Wrap the album fetching in try-catch
      try {
        final List<AssetPathEntity> albums =
            await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );

        if (albums.isEmpty) {
          _images = [];
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Use a smaller page size initially and implement pagination
        final List<AssetEntity> media = await albums.first.getAssetListPaged(
          page: 0,
          size: 30, // Reduced from 100 to improve initial load
        );

        _images = media;
      } catch (e) {
        _error = "Error loading images: ${e.toString()}";
      }
    } catch (e) {
      _error = "Unexpected error: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add method to load more images when needed
  Future<void> loadMoreImages(int page) async {
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final List<AssetEntity> media = await albums.first.getAssetListPaged(
          page: page,
          size: 20,
        );
        _images.addAll(media);
        notifyListeners();
      }
    } catch (e) {
      // Handle pagination errors silently or show a load more error
      print("Error loading more images: $e");
    }
  }
}
