import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerContainer extends StatelessWidget {
  final bool enableShimmer;
  final double? width;
  final double? height;
  final Widget? widget;
  const ShimmerContainer({super.key, this.enableShimmer = false, this.widget, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return enableShimmer ? wrapWidgetWithShimmer(widget ?? defaultCard()) : widget ?? defaultCard();
  }

  Widget defaultCard() {
    return Card(
      elevation: 2.0,
      color: Colors.grey[350],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
      child: SizedBox(width: width ?? screenWidth(100), height: height ?? screenHeight(27)),
    );
  }

  Widget wrapWidgetWithShimmer(Widget child) {
    return Shimmer.fromColors(baseColor: shimmerBaseColor, highlightColor: shimmerHighlightColor, child: child);
  }

  Widget text({double? width, double? height}) {
    Widget child = Container(
      width: width ?? screenWidth(10),
      height: height ?? 20,
      decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(5)), color: Colors.grey[350]),
    );

    return enableShimmer ? wrapWidgetWithShimmer(child) : child;
  }

  Widget getGridContainer(context) {
    Widget child = GridView.count(
      padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, screenPadding / 2),
      childAspectRatio: 2.3,
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 1.0,
      mainAxisSpacing: 2.0,
      primary: false,
      children: [
        for (int index = 0; index < 6; index++)
          Card(
            elevation: 2.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(color: Colors.grey.withAlpha(opacityCalculation(.4)), width: 1),
            ),
            child: Container(
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: screenPadding),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Shimmer Container',
                      softWrap: true,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.headlineMedium!.apply(color: Colors.white),
                    ),
                  ),
                  AppPadding.horizontal(),
                ],
              ),
            ),
          ),
      ],
    );
    return enableShimmer ? wrapWidgetWithShimmer(child) : child;
  }
}
