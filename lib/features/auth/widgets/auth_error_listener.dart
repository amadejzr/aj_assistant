import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class AuthErrorListener extends StatelessWidget {
  final Widget child;

  const AuthErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppToast.show(context,
              message: state.message, type: AppToastType.error);
        }
      },
      child: child,
    );
  }
}
