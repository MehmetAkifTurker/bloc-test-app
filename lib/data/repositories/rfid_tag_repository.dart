import 'dart:developer';
import 'package:water_boiler_rfid_labeler/data/models/const.dart';
import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RfidTagRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTag({required DBTag tag}) async {
    await _firestore.collection(collectionPath).add(tag.toMap());
  }

  Future<List<DBTag>> getTag() async {
    try {
      final rfidTags = await _firestore
          .collection(collectionPath)
          //.where(epcColumn, isNotEqualTo: 'epc')
          .get()
          .then((value) => value.docs.map((doc) {
                final DBTag tag = DBTag.fromMap(doc.data());
                tag.id = doc.id;
                return tag;
              }).toList());
      return rfidTags;
    } catch (e) {
      log('RfidTagRepository - There is and error when getting tags from firebase : ${e.toString()}');
      return [];
    }
  }

  Future<List<DBTag>> getTagFiltered(
      {required String columnName, required String value}) async {
    try {
      final rfidFilteredTags = await _firestore
          .collection(collectionPath)
          .where(columnName, isEqualTo: value)
          .get()
          .then((value) => value.docs.map((doc) {
                final DBTag tag = DBTag.fromMap(doc.data());
                tag.id = doc.id;
                return tag;
              }).toList());
      return rfidFilteredTags;
    } catch (e) {
      log('RfidTagRepository - There is and error when getting filtered tags from firebase : ${e.toString()}');
      return [];
    }
  }

  Future<void> deleteTag({required String uid}) async {
    try {
      await _firestore.collection(collectionPath).doc(uid).delete();
    } catch (e) {
      log('RfidTagRepository - There is and error when deleting tags from firebase : ${e.toString()}');
    }
  }

  Future<void> updateTag({required String uid, required DBTag tag}) async {
    try {
      await _firestore.collection(collectionPath).doc(uid).update(tag.toMap());
    } catch (e) {
      log('RfidTagRepository - There is and error when updating tags from firebase : ${e.toString()}');
    }
  }
}
