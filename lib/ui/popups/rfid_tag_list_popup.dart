import 'dart:developer';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_event.dart';
import 'package:intl/intl.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_bloc.dart';
import 'package:water_boiler_rfid_labeler/business_logic/blocs/db_tag/db_tag_state.dart';
import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/blocs/db_tag_popup/db_tag_popup_cubit.dart';
import '../../data/models/const.dart';

class RfidTagListPopup extends StatelessWidget {
  final DBTag? dbTag;
  final TagEpc? rfidTag;
  final bool isExist;

  RfidTagListPopup({
    super.key,
    this.dbTag,
    this.rfidTag,
    required this.isExist,
  });

  final _idTxtCtrl = TextEditingController();
  final _epcTxtCtrl = TextEditingController();
  final _pnTxtCtrl = TextEditingController();
  final _snTxtCtrl = TextEditingController();
  final _descTxtCtrl = TextEditingController();
  final _typeTxtCtrl = TextEditingController();
  final _noteTxtCtrl = TextEditingController();
  String _selectedDateString = 'Select Date';
  String _selectedBox = '';
  DateTime? selectedDate;
  int _selectedTagType = boxTagNo;

  @override
  Widget build(BuildContext context) {
    if (isExist == true && dbTag != null) {
      _idTxtCtrl.text = 'DB ID : ${dbTag!.id}';
      _epcTxtCtrl.text = dbTag!.epc;
      _pnTxtCtrl.text = dbTag!.pn;
      _snTxtCtrl.text = dbTag!.sn;
      _descTxtCtrl.text = dbTag!.desc;
      _typeTxtCtrl.text = dbTag!.type;
      _noteTxtCtrl.text = dbTag!.note;
      _selectedBox = dbTag!.selectedBox;
      log('Rfid Tag List Popup - DB Tag Selected Box is : ${dbTag!.selectedBox}');
      try {
        _selectedTagType = int.parse(dbTag!.tagType);
      } catch (e) {
        log('Rfid Tag List Popup - Error when selected tag type trying to convert integer : ${e.toString()} ');
      }
      try {
        selectedDate = DateTime.parse(dbTag!.expDate);
        _selectedDateString = DateFormat('dd/MM/yyyy').format(selectedDate!);
        log('Rfid Tag List Popup - Selected Date String is $_selectedDateString');
      } catch (e) {
        log('Rfid Tag List Popup - Error when selected tag exp date trying to convert date time : ${e.toString()} ');
      }
    }
    if (isExist == false && rfidTag != null) {
      log('Rfid Tag List Popup - New Tag will be created. EPC is ${rfidTag!.epc}');
      _epcTxtCtrl.text = rfidTag!.epc.replaceAll(RegExp('EPC:'), '');
    }

    context.read<DbTagPopupCubit>().changeVisibility(_selectedTagType);
    DateTime? pickedDate;
    return AlertDialog(
      title: const Row(
        children: [Icon(Icons.list), Text('Add or Update Item')],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedTagType,
              items: tagType
                  .map((item) => DropdownMenuItem(
                        value: item.keys.first,
                        child: Text(item.values.first),
                      ))
                  .toList(),
              decoration: const InputDecoration(
                helperText: 'Select the type for this tag (Box or Tool)',
              ),
              onChanged: ((value) {
                _selectedTagType = value!;
                context
                    .read<DbTagPopupCubit>()
                    .changeVisibility(_selectedTagType);
              }),
            ),
            TextFormField(
              controller: _idTxtCtrl,
              decoration: const InputDecoration(hintText: 'ID'),
              keyboardType: TextInputType.multiline,
              enabled: false,
            ),
            TextFormField(
              controller: _epcTxtCtrl,
              decoration: const InputDecoration(hintText: 'EPC'),
              keyboardType: TextInputType.multiline,
              enabled: false,
            ),
            TextFormField(
              controller: _pnTxtCtrl,
              decoration: const InputDecoration(
                  hintText: 'Please Enter PN for this product'),
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
              controller: _snTxtCtrl,
              decoration: const InputDecoration(
                  hintText: 'Please Enter SN for this product'),
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
              controller: _descTxtCtrl,
              decoration: const InputDecoration(
                  hintText: 'Please Enter Description for this product'),
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
              controller: _typeTxtCtrl,
              decoration: const InputDecoration(
                  hintText: 'Please Enter Type for this product'),
              keyboardType: TextInputType.multiline,
            ),
            // Popup Cubit Builder
            onlyToolSection(pickedDate),
            TextFormField(
              controller: _noteTxtCtrl,
              decoration: const InputDecoration(hintText: 'Enter note'),
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              DBTag tag = DBTag(
                  epc: _epcTxtCtrl.text,
                  pn: _pnTxtCtrl.text,
                  sn: _snTxtCtrl.text,
                  desc: _descTxtCtrl.text,
                  type: _typeTxtCtrl.text,
                  tagType: _selectedTagType.toString(),
                  selectedBox: _selectedBox,
                  expDate: selectedDate != null
                      ? selectedDate!.toIso8601String()
                      : _selectedDateString,
                  note: _noteTxtCtrl.text);
              if (tag.isMasterAssigned()) {
                isExist
                    ? context
                        .read<DBTagBloc>()
                        .add(DBUpdateTag(uid: dbTag!.id, tag: tag))
                    : context.read<DBTagBloc>().add(DBAddTag(tag: tag));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Box tag is not assigned for ${tag.pn}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.yellow,
                  ),
                );
              }
            },
            child: isExist ? const Icon(Icons.update) : const Icon(Icons.add))
      ],
    );
  }

  BlocBuilder<DbTagPopupCubit, DbTagPopupState> onlyToolSection(
      DateTime? pickedDate) {
    return BlocBuilder<DbTagPopupCubit, DbTagPopupState>(
      builder: (context, popupState) {
        // Check if "State" is "Tool" or "SelectedDate". In both cases visibility will be true.
        // "pickedDate ?? DateTime.now()"" section checks if the "pickedDate" is null. If null then "now" will be sent to state.
        return popupState is Tool || popupState is SelectedDate
            ? Column(
                children: [
                  BlocBuilder<DBTagBloc, DBTagState>(
                    builder: (context, dbTagState) {
                      if (dbTagState is DBTagLoaded) {
                        if (dbTagState.masters.isNotEmpty) {
                          _selectedBox == ''
                              ? _selectedBox = dbTagState.masters.first
                              : null;
                        }
                        try {
                          log('Rfid Tag List Popup - Selected Box is $_selectedBox');
                          log('Rfid Tag List Popup - Masters are : ${dbTagState.masters}');
                          return DropdownButtonFormField<String>(
                            value: dbTagState.masters.contains(_selectedBox) &&
                                    _selectedBox != ''
                                ? _selectedBox
                                : null,
                            items: dbTagState.masters
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ))
                                .toList(),
                            decoration: const InputDecoration(
                              helperText: 'Select a box for this tool',
                            ),
                            onChanged: ((value) {
                              _selectedBox = value!;
                              log('Rfid Tag List Popup - Selected Box is : $value');
                              log('Rfid Tag List Popup - Masters list is :${dbTagState.masters.toString()}');
                              // context
                              //     .read<DbTagPopupCubit>()
                              //     .changeVisibility(_selectedTagType);
                              // if (value == boxTagNo) {}
                            }),
                          );
                        } catch (e) {
                          log('Rfid Tag List Popup - There is an error when creating dropdown box. ${e.toString()}');
                          return const SizedBox.shrink();
                        }
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  Row(
                    children: [
                      const Icon(Icons.date_range),
                      const Text('Expire Date : '),
                      TextButton(
                        onPressed: () async {
                          pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2018, 1),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            selectedDate = pickedDate;
                            _selectedDateString =
                                DateFormat('dd/MM/yyyy').format(pickedDate!);
                            context
                                .read<DbTagPopupCubit>()
                                .updateSelectedDate(selectedDate!);
                          }
                          log('Rfid Tag List Popup - $_selectedDateString');
                        },
                        child: Text(
                          selectedDate != null
                              ? _selectedDateString
                              : 'Select Date',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  )
                ],
              )
            : const SizedBox.shrink();
      },
    );
  }
}
