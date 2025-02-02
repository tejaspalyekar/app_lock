import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/features/dashboard/view_models/gallery_view_model.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryViewModel>(
        builder: (context, galleryViewModel, child) {
      // Call fetchImages() when the widget is first rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (galleryViewModel.isLoading && galleryViewModel.images.isEmpty) {
          galleryViewModel.fetchImages();
        }
      });

      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Gallery"),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () => pushScreen(context, '/homeScreen'),
              icon: const Icon(Icons.menu),
            ),
          ],
        ),
        body: galleryViewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.cyan),
                ),
              )
            : galleryViewModel.images.isEmpty
                ? const Center(child: Text("Gallery is empty"))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: galleryViewModel.images.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<dynamic>(
                        future: galleryViewModel.images[index]
                            .thumbnailDataWithSize(
                                const ThumbnailSize(200, 200))
                            .then((data) {
                          if (data != null) {
                            return Image.memory(data, fit: BoxFit.cover);
                          }
                          return const Icon(Icons.image_not_supported);
                        }),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return snapshot.data ??
                                const Icon(Icons.image_not_supported);
                          }
                          return const Center(
                              child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.cyan),
                          ));
                        },
                      );
                    },
                  ),
      );
    });
  }
}
