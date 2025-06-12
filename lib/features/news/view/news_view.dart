import 'package:app_lock/features/news/view_model/news_view_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Google',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.w600),
              ),
              Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: const Row(
                    children: [
                      ContentContainer(
                          title: "Mumbai",
                          data: "31°",
                          image: Icon(
                            size: 22,
                            Icons.waves_rounded,
                            color: Colors.grey,
                          )),
                      ContentContainer(
                          title: "Air quality • 128",
                          data: "Moderate°",
                          image: CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.yellow,
                              child: Icon(
                                size: 16,
                                Icons.waves_rounded,
                                color: Colors.black,
                              ))),
                    ],
                  )),
              Consumer<NewsViewModel>(
                builder: (context, newsViewModel, child) => Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: newsViewModel.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.grey),
                            ),
                          ),
                        )
                      : newsViewModel.newsData!.isEmpty
                          ? const Center(
                              child: Text(
                                "No News Available",
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: newsViewModel.newsData == null
                                  ? 0
                                  : newsViewModel.newsData!.length,
                              itemBuilder: (context, index) => NewsContainer(
                                title:
                                    newsViewModel.newsData![index].title ?? "",
                                date: DateTime.parse(newsViewModel
                                        .newsData![index].publishedAt ??
                                    ""),
                                imageLink:
                                    newsViewModel.newsData![index].image ?? "",
                                newsUrl:
                                    newsViewModel.newsData![index].url ?? "",
                                source:
                                    newsViewModel.newsData![index].source ?? "",
                              ),
                            ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ContentContainer extends StatelessWidget {
  const ContentContainer(
      {super.key,
      required this.title,
      required this.data,
      required this.image});
  final String title;
  final String data;
  final Widget image;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2.3,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(172, 121, 121, 121)),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              image
              //Image.network(image) // Replace with your actual image URL
            ],
          )
        ],
      ),
    );
  }
}

class NewsContainer extends StatelessWidget {
  const NewsContainer(
      {super.key,
      required this.title,
      required this.source,
      required this.date,
      required this.imageLink,
      required this.newsUrl});

  final String title;
  final String source;
  final DateTime date;
  final String imageLink;
  final String newsUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color.fromARGB(190, 34, 34, 34),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (newsUrl != null && !newsUrl.isEmpty) {
            if (!await launchUrl(
              Uri.parse(newsUrl),
              mode: LaunchMode.externalApplication,
            )) {
              throw Exception('Could not launch $newsUrl');
            }
          }
        },
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              child: CachedNetworkImage(
                imageUrl: imageLink,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.grey[600]),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image,
                  color: Colors.grey,
                  size: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  maxLines: 3,
                  softWrap: true,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  title),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        source,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        ' • ${(DateTime.now().difference(date).inDays + 1).abs()}d',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.more_vert_sharp,
                    color: Colors.grey,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
