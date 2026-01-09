import 'package:flutter/cupertino.dart';

import 'package:bb_meet/core/constants/constants.dart';

class ShimmerList extends StatelessWidget {
  final Widget child;
  final int itemCount;
  const ShimmerList({
    super.key,
    required this.child,
    this.itemCount = defaultLengthOfShimmerList,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return child;
      },
    );
  }
}
