
import 'package:flutter/material.dart';

class CarouselController extends PageController {
  CarouselController({
    int initialItem = 0,
  }) : super(initialPage: initialItem);
}

class CarouselView extends StatelessWidget {
  final List<Widget> children;
  final CarouselController? controller;
  final List<int>? flexWeights;
  final bool itemSnapping;
  final bool consumeMaxWeight;
  final double? itemExtent;
  final double? shrinkExtent;

  const CarouselView({
    super.key,
    required this.children,
    this.controller,
    this.flexWeights,
    this.itemSnapping = false,
    this.consumeMaxWeight = true,
    this.itemExtent,
    this.shrinkExtent,
  });

  factory CarouselView.weighted({
    required List<int> flexWeights,
    CarouselController? controller,
    bool itemSnapping = false,
    bool consumeMaxWeight = true,
    required List<Widget> children,
    Key? key,
  }) {
    return CarouselView(
      key: key,
      flexWeights: flexWeights,
      controller: controller,
      itemSnapping: itemSnapping,
      consumeMaxWeight: consumeMaxWeight,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      children: children,
    );
  }
}
