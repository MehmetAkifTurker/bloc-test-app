// import 'package:water_boiler_rfid_labeler/business_logic/blocs/box_check/box_check_bloc.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_filtering_bloc/bloc/db_filtering_bloc.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_bloc.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_event.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag_popup/db_tag_popup_cubit.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/cubit/navigaion_qubit_cubit.dart';
// import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
// import 'package:water_boiler_rfid_labeler/data/repositories/rfid_tag_repository.dart';
// import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
// import 'package:water_boiler_rfid_labeler/ui/router/app_router.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/main_menu/main_menu.dart';
// import 'package:water_boiler_rfid_labeler/ui/screens/splash_screen/splash_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'dart:developer';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   // 2) Connect the RFID module exactly once
//   log("Connecting RFID module at app startup...");
//   final bool? connected = await RfidC72Plugin.connect;
//   if (connected == true) {
//     log("RFID module connected successfully at startup!");
//   } else {
//     log("Failed to connect RFID module at startup.");
//   }

//   runApp(MultiBlocProvider(
//     providers: [
//       BlocProvider(
//         create: (context) => DBTagBloc(RfidTagRepository())..add(DBGetTags()),
//       ),
//       BlocProvider(
//         create: (context) => DbTagPopupCubit(),
//       ),
//       BlocProvider(
//         create: (context) => NavigationCubit(),
//       ),
//       BlocProvider(
//         create: (context) => DbFilteringBloc()
//           ..add(const DbFilterSelectionEvent(
//               filteringStates: FilteringStates.none)),
//       ),
//       BlocProvider(
//         create: (context) => RfidTagBloc(), //..add(TagScanInit()),
//       ),
//       BlocProvider(
//         create: (context) => BoxCheckBloc(),
//       )
//     ],
//     child: MyApp(),
//   ));
// }

// class MyApp extends StatelessWidget {
//   MyApp({super.key});
//   final AppRouter _appRouter = AppRouter();

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: Future.delayed(const Duration(seconds: 5)),
//       builder: ((context, snapshot) {
//         RfidC72Plugin.initializeKeyEventHandler(context);
//         if (snapshot.connectionState == ConnectionState.done) {
//           return MaterialApp(
//             title: 'RFID Scan',
//             debugShowCheckedModeBanner: false,
//             theme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
//               useMaterial3: true,
//             ),
//             home: const MainMenu(),
//             onGenerateRoute: _appRouter.onGenerateRoute,
//             //home: RfidTagListPopup(),
//             //home: MyHomePage(),
//           );
//         }
//         return const SafeArea(
//           child: MaterialApp(
//             debugShowCheckedModeBanner: false,
//             home: SplashScreen(),
//           ),
//         );
//       }),
//     );
//   }
// }

// final bloc = CounterBloc();

// sealed class CounterEvent {}

// final class CounterIncrementPressed extends CounterEvent {}

// final class CounterDecrementPressed extends CounterEvent {}

// class CounterBloc extends Bloc<CounterEvent, int> {
//   CounterBloc() : super(0) {
//     on<CounterIncrementPressed>((event, emit) {
//       emit(state + 1);
//     });
//     on<CounterDecrementPressed>((event, emit) {
//       emit(state - 1);
//     });
//   }

//   @override
//   void onEvent(CounterEvent event) {
//     super.onEvent(event);
//     print(event);
//   }

//   @override
//   void onChange(Change<int> change) {
//     super.onChange(change);
//     print(change);
//   }

//   @override
//   void onTransition(Transition<CounterEvent, int> transition) {
//     super.onTransition(transition);
//     print(transition);
//   }

//   @override
//   void onError(Object error, StackTrace stackTrace) {
//     print('$error, $stackTrace');
//     super.onError(error, stackTrace);
//   }
// }

// class SimpleBlocObserver extends BlocObserver {
//   @override
//   void onChange(BlocBase bloc, Change change) {
//     super.onChange(bloc, change);
//     print('${bloc.runtimeType} $change');
//   }

//   @override
//   void onTransition(Bloc bloc, Transition transition) {
//     super.onTransition(bloc, transition);
//     print('${bloc.runtimeType} $transition');
//   }

//   @override
//   void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
//     print('${bloc.runtimeType} $error $stackTrace');
//     super.onError(bloc, error, stackTrace);
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   List<DBTag> tags = [];
//   DBTag addingTag = DBTag(
//       epc: 'epc',
//       pn: 'pn',
//       sn: 'sn',
//       desc: 'desc',
//       type: 'type',
//       tagType: '1',
//       selectedBox: 'selectedBox',
//       expDate: '2024-06-14T11:36:15.277253',
//       note: '');
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Cubit Counter'),
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       Bloc.observer = SimpleBlocObserver();
//                       bloc.add(CounterIncrementPressed());
//                     },
//                     child: const Text('Increment'),
//                   ),
//                   const SizedBox(width: 10.0),
//                   ElevatedButton(
//                     onPressed: () {
//                       Bloc.observer = SimpleBlocObserver();
//                       bloc.add(CounterDecrementPressed());
//                     },
//                     child: const Text('Decrement'),
//                   ),
//                   const SizedBox(width: 10.0),
//                   ElevatedButton(
//                     onPressed: () async {
//                       RfidTagRepository rfidTagRepository = RfidTagRepository();
//                       tags = await rfidTagRepository.getTag();
//                       setState(() {});
//                     },
//                     child: const Text('Get Data'),
//                   ),
//                   const SizedBox(width: 10.0),
//                   ElevatedButton(
//                     onPressed: () async {
//                       RfidTagRepository rfidTagRepository = RfidTagRepository();
//                       await rfidTagRepository.addTag(tag: addingTag);
//                       setState(() {});
//                       //log(addingTag.expDate);
//                     },
//                     child: const Text('Add Data'),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//                 child: ListView.builder(
//               itemCount: tags.length,
//               itemBuilder: (context, index) {
//                 final tag = tags[index];
//                 return Card(
//                   color: tag.isExpired() ? Colors.red : null,
//                   child: ListTile(
//                     leading: tag.isMaster() ? const Icon(Icons.star) : null,
//                     title: Text('EPC: ${tag.epc}'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('ID: ${tag.id}'),
//                         Text('PN: ${tag.pn}'),
//                         Text('SN: ${tag.sn}'),
//                         Text('Desc: ${tag.desc}'),
//                       ],
//                     ),
//                     onLongPress: () async {
//                       RfidTagRepository rfidTagRepository = RfidTagRepository();
//                       await rfidTagRepository.deleteTag(uid: tag.id);
//                       setState(() {});
//                     },
//                     onTap: () async {
//                       RfidTagRepository rfidTagRepository = RfidTagRepository();
//                       await rfidTagRepository.updateTag(
//                           uid: tag.id, tag: addingTag);
//                     },
//                   ),
//                 );
//               },
//             ))
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:developer';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/box_check/box_check_bloc.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_filtering_bloc/bloc/db_filtering_bloc.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag_popup/db_tag_popup_cubit.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
import 'package:water_boiler_rfid_labeler/business_logic/cubit/navigaion_qubit_cubit.dart';
import 'package:water_boiler_rfid_labeler/data/repositories/rfid_tag_repository.dart';
import 'package:water_boiler_rfid_labeler/firebase_options.dart';
import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
import 'package:water_boiler_rfid_labeler/ui/router/app_router.dart';
import 'package:water_boiler_rfid_labeler/ui/screens/main_menu/main_menu.dart';
import 'package:water_boiler_rfid_labeler/ui/screens/splash_screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log("Connecting RFID module at app startup...");
  final bool? connected = await RfidC72Plugin.connect;
  if (connected == true) {
    log("RFID module connected successfully at startup!");
  } else {
    log("Failed to connect RFID module at startup.");
  }

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => DBTagBloc(RfidTagRepository())..add(DBGetTags()),
      ),
      BlocProvider(
        create: (context) => DbTagPopupCubit(),
      ),
      BlocProvider(
        create: (context) => NavigationCubit(),
      ),
      BlocProvider(
        create: (context) => DbFilteringBloc()
          ..add(const DbFilterSelectionEvent(
              filteringStates: FilteringStates.none)),
      ),
      BlocProvider(
        create: (context) => RfidTagBloc(),
      ),
      BlocProvider(
        create: (context) => BoxCheckBloc(),
      )
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    // Delay to allow splash screen to be shown (if desired)
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 5)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If needed, you could initialize key events here:
          // RfidC72Plugin.initializeKeyEventHandler(context);
          return MaterialApp(
            title: 'RFID App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
              useMaterial3: true,
            ),
            home: const MainMenu(),
            onGenerateRoute: _appRouter.onGenerateRoute,
          );
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      },
    );
  }
}
