import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:waterbus_sdk/types/index.dart';

import 'package:bb_meet/core/app/colors/app_color.dart';
import 'package:bb_meet/core/app/lang/data/localization.dart';
import 'package:bb_meet/core/navigator/app_router.dart';
import 'package:bb_meet/core/navigator/routes.dart';
import 'package:bb_meet/core/types/extensions/context_extensions.dart';
import 'package:bb_meet/core/utils/modal/show_dialog.dart';
import 'package:bb_meet/core/utils/sizer/sizer.dart';
import 'package:bb_meet/features/app/bloc/bloc.dart';
import 'package:bb_meet/features/chats/presentation/bloc/chat_bloc.dart';
import 'package:bb_meet/features/chats/presentation/widgets/avatar_chat.dart';
import 'package:bb_meet/features/chats/presentation/widgets/icon_button.dart';
import 'package:bb_meet/features/common/widgets/gesture_wrapper.dart';
import 'package:bb_meet/features/conversation/screens/detail_group_screen.dart';
import 'package:bb_meet/features/room/presentation/bloc/room/room_bloc.dart';

class ConversationHeader extends StatelessWidget {
  final Function()? onBackScreen;
  const ConversationHeader({super.key, required this.onBackScreen});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (bf, at) {
        if (bf is ChatActived && at is ChatActived) {
          return bf.conversationCurrent != at.conversationCurrent;
        }

        return true;
      },
      builder: (context, state) {
        if (state is ChatActived) {
          final Room? room = state.conversationCurrent;

          return room == null
              ? const SizedBox()
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.sp),
                  child: Row(
                    children: [
                      Visibility(
                        visible: AppRouter.canPop || context.isDesktop,
                        child: GestureWrapper(
                          onTap: () {
                            if (context.isDesktop) {
                              onBackScreen?.call();
                            } else {
                              AppRouter.pop();
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12.sp).add(
                              EdgeInsets.only(right: 10.sp),
                            ),
                            child: Icon(
                              PhosphorIcons.caretLeft(PhosphorIconsStyle.light),
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureWrapper(
                          onTap: () {
                            if (context.isMobile) {
                              DetailGroupRoute().push(context);
                            } else {
                              showScreenAsDialog(
                                route: Routes.archivedRoute,
                                child: DetailGroupScreen(),
                              );
                            }
                          },
                          child: ColoredBox(
                            color: Colors.transparent,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AvatarChat(room: room, size: 30.sp),
                                SizedBox(width: 10.sp),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        room.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        "${room.members.length} ${(room.members.length < 2 ? Strings.member.i18n : Strings.members.i18n).toLowerCase()}",
                                        style: TextStyle(
                                          color: fCL,
                                          height: 0.75.sp,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20.sp),
                      IconButtonCustom(
                        onTap: () {
                          AppBloc.roomBloc
                              .add(RoomJoinedEvent(room: room, isMember: true));
                        },
                        icon: PhosphorIcons.broadcast(PhosphorIconsStyle.fill),
                        sizeIcon: 22.sp,
                        padding: EdgeInsets.all(3.sp),
                        margin: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
        }

        return const SizedBox();
      },
    );
  }
}
