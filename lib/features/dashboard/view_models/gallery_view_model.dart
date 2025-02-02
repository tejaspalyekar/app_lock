import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryViewModel extends ChangeNotifier {
  List<AssetEntity> _images = [];
  bool _isLoading = true;

  get images => _images;
  get isLoading => _isLoading;

  Future<void> fetchImages() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
            androidPermission:
                AndroidPermission(type: RequestType.all, mediaLocation: true)));
    if (ps.hasAccess) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      if (albums.isNotEmpty) {
        List<AssetEntity> media =
            await albums.first.getAssetListPaged(page: 0, size: 100);
        _images = media;
        _isLoading = false;
      }
    }

    notifyListeners();
  }
}
