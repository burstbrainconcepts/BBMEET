import 'package:flutter/material.dart';

import 'package:bb_meet/core/app/lang/data/localization.dart';
import 'package:bb_meet/core/types/extensions/context_extensions.dart';
import 'package:bb_meet/core/utils/sizer/sizer.dart';
import 'package:bb_meet/features/profile/presentation/models/menu_items.dart';

class MenuDrawerCard extends StatelessWidget {
  final MenuItemModel item;
  const MenuDrawerCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 12.sp),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: context.isDesktop ? 21.sp : 18.sp,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 12.sp),
          Text(
            item.title.i18n,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }
}
