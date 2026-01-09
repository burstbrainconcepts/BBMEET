import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:waterbus_sdk/types/index.dart';

import 'package:bb_meet/core/app/lang/data/localization.dart';
import 'package:bb_meet/core/navigator/app_router.dart';
import 'package:bb_meet/core/utils/modal/show_bottom_sheet.dart';
import 'package:bb_meet/features/app/bloc/bloc.dart';
import 'package:bb_meet/features/chats/presentation/widgets/bottom_sheet_delete.dart';
import 'package:bb_meet/features/conversation/bloc/message_bloc.dart';
import 'package:bb_meet/features/conversation/xmodels/option_model.dart';

extension MessageX on Message {
  String get dataX => isDeleted
      ? "${isMe ? Strings.you.i18n : createdBy?.fullName ?? Strings.user.i18n} ${Strings.unsentAMessage.i18n}"
      : data;

  List<OptionModel> get getOptions {
    final List<OptionModel> options = [];

    if (isMe) {
      options.add(
        OptionModel(
          title: Strings.editMessage.i18n,
          handlePressed: () {
            AppBloc.messageBloc.add(MessageSelected(message: this));
          },
          iconData: PhosphorIcons.pencil(),
        ),
      );

      options.add(
        OptionModel(
          iconData: PhosphorIcons.trash(),
          title: Strings.retrieve.i18n,
          isDanger: true,
          handlePressed: () {
            showBottomSheetWaterbus(
              context: AppRouter.context!,
              enableDrag: false,
              builder: (context) {
                return BottomSheetDelete(
                  description: Strings.sureDeleteMessage.i18n,
                  handlePressed: () {
                    AppBloc.messageBloc.add(MessageDeleted(messageId: id));
                  },
                );
              },
            );
          },
        ),
      );
    }

    return options;
  }

  bool get isMe => createdBy?.id == AppBloc.userBloc.user?.id;
}
