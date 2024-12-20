// import 'dart:developer';
// import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_bloc.dart';
// import 'package:bloc_test_app/business_logic/blocs/db_tag/db_tag_event.dart';
// import 'package:bloc_test_app/data/models/db_tag.dart';
// import 'package:bloc_test_app/ui/screens/rfid_db_tag_list_screen/_rfid_db_tag_list_methods.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Widget buildDBTagListTile(BuildContext context, int index, DBTag tag) {
//   final isExpired = tag.isExpired();
//   final isMasterAssigned = tag.isMasterAssigned();
//   final isMaster = tag.isMaster();
//   final isNoteExist = tag.note == '' ? false : true;

//   return Card(
//     color: isExpired ? Colors.red : null,
//     child: ListTile(
//       leading: isMaster
//           ? const Icon(
//               FontAwesomeIcons.box,
//               color: Colors.grey,
//             )
//           : Icon(
//               Icons.build,
//               color:
//                   (isMasterAssigned && !isExpired) ? Colors.grey : Colors.amber,
//             ),
//       title: Text('PN: ${tag.pn}'),
//       //Text('EPC: ${tag.epc}'),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           //Text('ID: ${tag.id}'),
//           //Text('PN: ${tag.pn}'),
//           Text('SN: ${tag.sn}'),
//           Text('Desc: ${tag.desc}'),
//         ],
//       ),
//       trailing: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Flexible(child: Text('No : ${(index + 1).toString()}')),
//           Flexible(
//             child: isMasterAssigned
//                 ? Text(tag.selectedBox)
//                 : const Text('No box assigned'),
//           ),
//           Flexible(
//             child: isExpired
//                 ? Text(
//                     'Exp day no : ${DateTime.now().difference(DateTime.parse(tag.expDate)).inDays.toString()}')
//                 : const SizedBox.shrink(),
//           ),
//           Flexible(
//               child: isNoteExist
//                   ? const Icon(Icons.notes)
//                   : const SizedBox.shrink()),
//         ],
//       ),
//       onLongPress: () {
//         log('_RFID DB Tag List List - Tag ID = ${tag.id}');

//         context.read<DBTagBloc>().add(DBDeleteTag(uid: tag.id));
//       },
//       onTap: () {
//         log('_RFID DB Tag List List - ${tag.id.toString()}');
//         showDialogBoxUpdate(context: context, tag: tag);
//       },
//     ),
//   );
// }
