import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/data/models/tag_epc.dart';
import 'package:bloc_test_app/ui/popups/rfid_tag_list_popup.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

void showDialogBoxUpdate({
  required BuildContext context,
  required DBTag tag,
}) {
  showDialog(
    context: context,
    builder: (context) => RfidTagListPopup(
      dbTag: tag,
      isExist: true,
    ),
  );
}

void showDialogBoxNew({
  required BuildContext context,
  required TagEpc tag,
}) {
  showDialog(
    context: context,
    builder: (context) => RfidTagListPopup(
      rfidTag: tag,
      isExist: false,
    ),
  );
}

bool shouldRebuild<T extends Object>(
    List<T> previousList, List<T> currentList) {
  final previousHash = const ListEquality().hash(previousList);
  final currentHash = const ListEquality().hash(currentList);
  return previousHash != currentHash;
}
