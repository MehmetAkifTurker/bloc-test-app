import 'dart:developer';

import 'package:equatable/equatable.dart';

class DBTag extends Equatable {
  late final String id;
  final String epc;
  final String pn;
  final String sn;
  final String desc;
  final String type;
  final String tagType;
  String selectedBox;
  String expDate;
  final String note;

  DBTag(
      { //required this.id,
      required this.epc,
      required this.pn,
      required this.sn,
      required this.desc,
      required this.type,
      required this.tagType,
      required this.selectedBox,
      required this.expDate,
      required this.note});

  @override
  List<Object?> get props =>
      [id, epc, pn, sn, desc, type, tagType, selectedBox, expDate, note];

  bool isExpired() {
    try {
      DateTime? expiryDate = DateTime.tryParse(expDate);
      return expiryDate != null &&
          expiryDate.isBefore(DateTime.now()) &&
          !isMaster();
    } catch (e) {
      log('DB Tag - There is an error when calculating is expired : ${e.toString()}');
      return true;
    }
  }

  bool isMaster() {
    try {
      return int.parse(tagType) == boxTagTypeNo;
    } catch (e) {
      log('DB Tag - There is an error when calculating is master : ${e.toString()}');
      return false;
    }
  }

  bool isMasterAssigned() {
    if (isMaster() == false) {
      if (selectedBox == '') {
        return false;
      } else {
        return true;
      }
    } else {
      selectedBox = '';
      expDate = '';
      return true;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      //idColumn: id,
      epcColumn: epc,
      pnColumn: pn,
      snColumn: sn,
      descColumn: desc,
      typeColumn: type,
      tagTypeColumn: tagType,
      selectedBoxColumn: selectedBox,
      expDateColumn: expDate,
      noteColumn: note,
    };
  }

  factory DBTag.fromMap(Map<String, dynamic> map) {
    return DBTag(
      //id: map[idColumn].toString(),
      epc: map[epcColumn].toString(),
      pn: map[pnColumn].toString(),
      sn: map[snColumn].toString(),
      desc: map[descColumn].toString(),
      type: map[typeColumn].toString(),
      tagType: map[tagTypeColumn].toString(),
      selectedBox: map[selectedBoxColumn].toString(),
      expDate: map[expDateColumn].toString(),
      note: map[noteColumn].toString(),
    );
  }

  DBTag copyWith({
    String? id,
    String? epc,
    String? pn,
    String? sn,
    String? desc,
    String? type,
    String? tagType,
    String? selectedBox,
    String? expDate,
    String? note,
  }) {
    return DBTag(
      //id: id ?? this.id,
      epc: epc ?? this.epc,
      pn: pn ?? this.pn,
      sn: sn ?? this.sn,
      desc: desc ?? this.desc,
      type: type ?? this.type,
      tagType: tagType ?? this.tagType,
      selectedBox: selectedBox ?? this.selectedBox,
      expDate: expDate ?? this.expDate,
      note: note ?? this.note,
    );
  }
}

//const String idColumn = 'id';
const String epcColumn = 'epc';
const String pnColumn = 'pn';
const String snColumn = 'sn';
const String descColumn = 'desc';
const String typeColumn = 'type';
const String tagTypeColumn = 'tagType';
const String selectedBoxColumn = 'selectedBox';
const String expDateColumn = 'expDate';
const String noteColumn = 'note';
const int boxTagTypeNo = 1;
const int toolTagTypeNo = 2;

const masterTag = Set<DBTag>;
