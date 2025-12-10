import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nationalidbarcode/routing/app_router.dart';

import 'controllers/login/login_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation ONLY on mobile
  if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize:Platform.isAndroid?const Size(375, 812): const Size(1440, 1024),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LoginCubit()),
          ],
          child: MaterialApp.router(
            title: 'National Id Barcode',
            debugShowCheckedModeBanner: false,

            // FULL ARABIC SUPPORT
            locale: const Locale("ar"),
            supportedLocales: const [
              Locale("ar"),
              Locale("en"),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (_, __) => const Locale("ar"),

            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              fontFamily: "Cairo", // Arabic font
            ),

            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
