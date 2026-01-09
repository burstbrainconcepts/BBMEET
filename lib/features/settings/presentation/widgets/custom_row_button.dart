import 'package:flutter/material.dart';

import 'package:bb_meet/core/utils/sizer/sizer.dart';
import 'package:bb_meet/features/common/styles/style.dart';
import 'package:bb_meet/features/common/widgets/gesture_wrapper.dart';

class CustomRowButton extends StatelessWidget {
  final Function() onTap;
  final dynamic value;
  final String text;
  final bool showDivider;
  final String? groupValue;
  const CustomRowButton({
    super.key,
    required this.onTap,
    this.value,
    required this.text,
    required this.showDivider,
    this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureWrapper(
          onTap: () => onTap.call(),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 2.sp, horizontal: 10.sp),
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  value == groupValue
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: value == groupValue
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  size: 20.sp,
                ),
                SizedBox(width: 8.sp),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 36.sp),
            child: divider,
          ),
      ],
    );
  }
}
