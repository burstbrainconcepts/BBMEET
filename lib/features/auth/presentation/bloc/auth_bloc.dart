import 'package:flutter/foundation.dart';
import 'package:auth/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:injectable/injectable.dart';
import 'package:waterbus_sdk/flutter_waterbus_sdk.dart';

import 'package:bb_meet/core/navigator/app_router.dart';
import 'package:bb_meet/features/app/bloc/bloc.dart';
import 'package:bb_meet/features/chats/data/datasources/user_local_datasource.dart';
import 'package:bb_meet/features/chats/presentation/bloc/chat_bloc.dart';
import 'package:bb_meet/features/common/widgets/dialogs/dialog_loading.dart';
import 'package:bb_meet/features/profile/presentation/bloc/user_bloc.dart';
import 'package:bb_meet/features/room/presentation/bloc/recent_joined/recent_joined_bloc.dart';
import 'package:bb_meet/features/room/presentation/bloc/room/room_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserLocalDataSource _userLocal;
  final Auth _auth = Auth();
  final WaterbusSdk _waterbusSdk = WaterbusSdk.instance;

  User? _user;

  AuthBloc(this._userLocal) : super(AuthInitial()) {
    _auth.initialize();
    on<AuthEvent>((event, emit) async {
      if (event is AuthStarted) {
        await _onAuthCheck(emit);
      }

      if (event is AuthLoggedIn) {
        await _handleLogin();

        if (_user != null) emit(_authSuccess);
      }

      if (event is AuthLoggedOut) {
        await _handleLogOut();

        if (_user == null) {
          emit(_authFailure);
        }
      }

      if (event is AuthLoggedInAndJoinedRoom) {
        if (_user == null) {
          await _handleLogin(
            fullname: event.fullname,
            callbackConnected: () {
              AppBloc.roomBloc.add(
                RoomAttemptJoin(code: event.code, password: event.password),
              );
            },
          );

          if (_user != null) emit(_authSuccess);
        } else {
          AppBloc.roomBloc.add(
            RoomAttemptJoin(code: event.code, password: event.password),
          );
        }
      }
    });
  }

  Future<void> _onAuthCheck(Emitter<AuthState> emit) async {
    final User? user = _userLocal.getUser();

    if (user != null) {
      _user = user;
      await _waterbusSdk.renewToken();
    }

    FlutterNativeSplash.remove();

    emit(_user == null ? _authFailure : _authSuccess);
  }

  // MARK: state
  AuthSucceeded get _authSuccess {
    AppBloc.instance.bootstrap();

    return AuthSucceeded();
  }

  AuthFailure get _authFailure {
    return AuthFailure();
  }

  // MARK: Private methods
  Future<void> _handleLogin({
    String? fullname,
    Function()? callbackConnected,
  }) async {
    displayLoadingLayer();

    try {
      debugPrint("AuthBloc: Starting signInAnonymously");
      final String payload = await _auth.signInAnonymously();
      debugPrint("AuthBloc: signInAnonymously success, payload: $payload");

      if (payload.isEmpty) {
        debugPrint("AuthBloc: Payload empty, popping router");
        AppRouter.pop();
        return;
      }

      debugPrint("AuthBloc: Calling createToken with fullname: $fullname");
      final Result<User> result = await _waterbusSdk.createToken(
        AuthPayload(fullName: fullname ?? "Waterbus", externalId: payload),
        callbackConnected: callbackConnected,
      );
      debugPrint("AuthBloc: createToken result: ${result.isSuccess ? 'Success' : 'Failure'}");

      if (fullname == null) {
        debugPrint("AuthBloc: Popping router (fullname is null)");
        AppRouter.pop();
      }

      if (result.isSuccess) {
        debugPrint("AuthBloc: Saving user and updating state");
        _userLocal.saveUser(result.value!);
        _user = result.value;
      }
    } catch (e, stack) {
      // Ensure we dismiss the loading layer if error occurs
      if (fullname == null) {
        debugPrint("AuthBloc: Popping router due to error");
        AppRouter.pop();
      }
      // Re-throw or handle error
      debugPrint("AuthBloc login failed: $e\nStack: $stack");
    }
  }

  Future<void> _handleLogOut() async {
    _userLocal.clearUser();
    await _waterbusSdk.deleteToken();

    AppRouter.popUntilToRoot();

    _user = null;
    AppBloc.userBloc.add(UserCleaned());
    AppBloc.recentJoinedBloc.add(RecentJoinedCleaned());
    AppBloc.chatBloc.add(ChatCleaned());
  }
}
