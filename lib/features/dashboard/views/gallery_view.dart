import 'package:app_lock/features/dashboard/view_models/gallery_view_model.dart';
import 'package:app_lock/features/dashboard/views/settings_view.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
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
            leading: const SizedBox(), // Empty leading widget
            centerTitle: true,
            title: const Text("Gallery"),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.menu),
              ),
            ],
          ),
          body: _buildBody(galleryViewModel, context),
        );
      },
    );
  }

  Widget _buildBody(GalleryViewModel viewModel, BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.cyan),
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(viewModel.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.fetchImages(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (viewModel.images.isEmpty) {
      return const Center(child: Text("Gallery is empty"));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: viewModel.images.length,
      itemBuilder: (context, index) {
        return FutureBuilder<dynamic>(
          future: viewModel.images[index]
              .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return const Icon(Icons.error_outline);
              }
              if (snapshot.hasData) {
                return CachedMemoryImage(
                  uniqueKey: snapshot.data!.icon.toString(),
                  bytes: snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                );
              }
            }
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyan),
              ),
            );
          },
        );
      },
    );
  }
}
