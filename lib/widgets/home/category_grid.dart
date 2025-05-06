import 'package:flutter/material.dart';
import 'category_item.dart';
import 'category_item_widget.dart';

import 'package:carousel_slider/carousel_slider.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryItem> categories;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final int itemsPerPage = 6;
    final int pageCount = (categories.length / itemsPerPage).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: CarouselSlider(
            options: CarouselOptions(
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
              viewportFraction: 0.95,
              onPageChanged: (index, reason) {
                _currentPageNotifier.value = index;
              },
            ),
            items: List.generate(pageCount, (pageIndex) {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex =
                  (startIndex + itemsPerPage) > categories.length
                      ? categories.length
                      : startIndex + itemsPerPage;

              final pageItems = categories.sublist(startIndex, endIndex);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Column(
                  children: [
                    GridView(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 40,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 100,
                          ),
                      shrinkWrap: true,
                      children:
                          pageItems
                              .map((item) => CategoryItemWidget(category: item))
                              .toList(),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        categories.length > 6
            ? ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pageCount, (index) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.only(
                        top: 0,
                        bottom: 8.0,
                        left: 2.0,
                        right: 2.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            index == currentPage
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      ),
                    );
                  }),
                );
              },
            )
            : const SizedBox.shrink(),
      ],
    );
  }
}
