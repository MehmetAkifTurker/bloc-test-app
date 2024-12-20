import 'dart:convert';

import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:equatable/equatable.dart';

class TagEpc extends Equatable {
  final String id;
  final String epc;
  final String count;
  final String rssi;

  const TagEpc({
    required this.id,
    required this.epc,
    required this.count,
    required this.rssi,
  });

  @override
  List<Object?> get props => [id, epc];

  factory TagEpc.fromMap(Map<String, dynamic> json) => TagEpc(
        id: json["KEY_ID"],
        epc: json["KEY_EPC"],
        count: json["KEY_COUNT"],
        rssi: json["KEY_RSSI"],
      );

  Map<String, dynamic> toMap() => {
        "KEY_ID": id,
        "KEY_EPC": epc,
        "KEY_COUNT": count,
        "KEY_RSSI": rssi,
      };

  static List<TagEpc> parseTags(String str) =>
      List<TagEpc>.from(json.decode(str).map((x) => TagEpc.fromMap(x)));

  static String tagEpcToJson(List<TagEpc> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

  DBTag? isExisInDB(List<DBTag> dbTagList) {
    final _epc = epc.replaceAll(RegExp('EPC:'), '');

    for (DBTag _dbTag in dbTagList) {
      if (_dbTag.epc.contains(_epc)) {
        return _dbTag;
      }
    }
    return null;
  }

  bool isExisInDBAny(List<DBTag> dbTagList) {
    final _epc = epc.replaceAll(RegExp('EPC:'), '');
    return dbTagList.any((dbTag) => dbTag.epc.contains(_epc));
  }
}
