// import 'dart:developer';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
// import 'package:water_boiler_rfid_labeler/business_logic/blocs/rfid_tag/rfid_tag_bloc.dart';
// import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';
// import 'package:water_boiler_rfid_labeler/java_comm/rfid_c72_plugin.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class RfidDBActinButtons extends StatelessWidget {
//   const RfidDBActinButtons({super.key});

//   @override
//   Widget build(BuildContext context) {
//     int clickCount = 0;
//     bool addButtonPressed = false;
//     bool isStarted = false;
//     return FittedBox(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           // BlocListener<DBTagBloc, DBTagState>(
//           //   listener: (context, state) {
//           //     if (state is DBTagLoaded &&
//           //         clickCount < 300 &&
//           //         addButtonPressed) {
//           //       clickCount++; // Increment only on DBTagLoaded and within limit
//           //       log('State is DBTagLoaded. Click count: $clickCount');
//           //       context
//           //           .read<DBTagBloc>()
//           //           .add(DBAddTag(tag: createInitialRfidTag));
//           //     }
//           //     if (clickCount >= 300 && addButtonPressed) {
//           //       clickCount = 0;
//           //       addButtonPressed = false;
//           //     }
//           //   },
//           //   child: TextButton(
//           //     onPressed: () {
//           //       context
//           //           .read<DBTagBloc>()
//           //           .add(DBAddTag(tag: createInitialRfidTag));
//           //       addButtonPressed = true;
//           //     },
//           //     child: const Row(
//           //       children: [
//           //         Icon(Icons.add),
//           //         Padding(padding: EdgeInsets.all(10)),
//           //         Text('Add'),
//           //       ],
//           //     ),
//           //   ),
//           // ),
//           BlocBuilder<RfidTagBloc, RfidTagState>(
//             builder: (context, state) {
//               if (state is RfidScanning) {
//                 log('State is TagReading');
//               }

//               return Column(
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       context.read<RfidTagBloc>().add(RfidInit());
//                       if (state is RfidInitializing) {
//                         // log(state.state.status);
//                       }
//                       // //context.read<DBTagBloc>().add(DBGetTags());
//                       // final isconnected = await RfidC72Plugin.isConnected;
//                       // log('isConnected = ${isconnected.toString()}');

//                       // if (isconnected == false) {
//                       //   data.clear();
//                       //   await RfidC72Plugin.clearData;
//                       //   final result = await RfidC72Plugin.connect;
//                       //   log(result.toString());
//                       // }
//                       // final platformName = isconnected!
//                       //     ? await RfidC72Plugin.platformVersion
//                       //     : 'Could not get the platform name';
//                       // log('platform Name = $platformName');

//                       // isconnected && !isStarted
//                       //     ? await RfidC72Plugin.setPowerLevel('5')
//                       //     : null;

//                       // try {
//                       //   final getPowerLevel = isconnected && !isStarted
//                       //       ? await RfidC72Plugin.getPowerLevel
//                       //       : 'Could not get power';
//                       //   log('get Power Level = $getPowerLevel');
//                       // } catch (e) {
//                       //   log('Get Power Error ${e.toString()}');
//                       // }
//                       // try {
//                       //   final getTemperature = isconnected && !isStarted
//                       //       ? await RfidC72Plugin.getTemperature
//                       //       : 'Could not get temperature';
//                       //   log('get Temperature = $getTemperature');
//                       // } catch (e) {
//                       //   log('Get Temperature ${e.toString()}');
//                       // }

//                       // try {
//                       //   final getFrequencyMode = isconnected && !isStarted
//                       //       ? await RfidC72Plugin.getFrequencyMode
//                       //       : 'Could not get frequency mode';
//                       //   log('get Frequency Mode = $getFrequencyMode');
//                       // } catch (e) {
//                       //   log('Get Power Error ${e.toString()}');
//                       // }

//                       // try {
//                       //   if (!isStarted) {
//                       //     await RfidC72Plugin.clearData;
//                       //     await RfidC72Plugin.startContinuous;
//                       //   }
//                       //   isStarted
//                       //       ? await RfidC72Plugin.stop
//                       //       : null; //await RfidC72Plugin.startContinuous;

//                       //   isStarted = !isStarted;
//                       // } catch (e) {
//                       //   log('Start Continuous Error ${e.toString()}');
//                       // }

//                       // try {
//                       //   if (isStarted) {
//                       //     RfidC72Plugin.tagsStatusStream
//                       //         .receiveBroadcastStream()
//                       //         .listen(updateTags);
//                       //   }
//                       //   isStarted ? null : null;
//                       // } catch (e) {
//                       //   log('Tag Stream ${e.toString()}');
//                       // }

//                       // try {
//                       //   RfidC72Plugin.playSound;
//                       // } catch (e) {
//                       //   log('Play Sound Error ${e.toString()}');
//                       // }
//                     },
//                     child: const Row(
//                       children: [
//                         Icon(Icons.refresh),
//                         Padding(padding: EdgeInsets.all(10)),
//                         Text('Refresh'),
//                       ],
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       try {
//                         //await RfidC72Plugin.writeTag('Deneme');
//                         await RfidC72Plugin.writeTag2;
//                       } catch (e) {
//                         log(e.toString());
//                       }
//                     },
//                     child: const Text('Write'),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// List<TagEpc> data = [];
// final List<String> EPC = [];
// int _totalEPC = 0, _invalidEPC = 0, _scannedEPC = 0;
// void updateTags(dynamic result) async {
//   data = TagEpc.parseTags(result);
//   _totalEPC = data.toSet().toList().length;
//   //log('_totalEPC ${_totalEPC.toString()}');
//   //log('data ${data.first.rssi}');
//   //log('data ${result.toString()}');
// }

// bool _isConnected = false;
// void updateIsConnected(dynamic isConnected) {
// //setState(() {
//   _isConnected = isConnected;
// //});
// }
