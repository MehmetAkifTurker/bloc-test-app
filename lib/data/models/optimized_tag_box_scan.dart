import 'dart:developer';

import 'package:bloc_test_app/data/models/db_tag.dart';
import 'package:bloc_test_app/data/models/tag_epc.dart';

// This class is for connecting the scanned tags and the database tags.
// When tag is scanned, then processRfidScanTags is run.
// originalTag is TagEpc type which come from RFID scanned tag.
// originalDBTag is Database tag comes from Database.
// Other bool variables ara calculated in processRfidScanTags function.
//

class OptimizedTagBoxScan {
  final TagEpc originalTag;
  final DBTag originalDBTag;
  final bool existsInDB;
  final bool isMaster;
  final bool isMasterAssigned;
  final bool isExpired;
  final bool inFoundMaster;

  OptimizedTagBoxScan(
    this.originalTag,
    this.originalDBTag, {
    required this.existsInDB,
    this.isMaster = false,
    this.isMasterAssigned = true,
    this.isExpired = false,
    this.inFoundMaster = false,
  });
}

// processRfidScanTags functions parameter are tags, dbTags, foundInDBTags and notFoundInDBTags.
// tags are List coming from rfid.
// dbTags are coming from database.
// foundInDBTags and notFoundInDBTags are sets. They are created from outside. But in this function
// elements are added to this sets.
// Set is used for overcome duplication. Tags are comming from Rfid Scan. And when scanning same TagEpc
// is coming. So not to add the duplicated tags to foundInDBTags and notFoundInDBTags, sets are used.
//

List<OptimizedTagBoxScan> processBoxScanTags({
  required List<TagEpc> tags,
  required List<DBTag> dbTags,
  required String masterTagName,
  required Set<DBTag> allSlaveTagInDBOfFoundMaster,
  required Set<DBTag> foundSlaveTagsOfFoundMaster,
  required Set<DBTag> unfoundSlaveTagsOfFoundMaster,
  required Set<DBTag> foundSlaveTagsOfOtherMaster,
}) {
  final optimizedTags = <OptimizedTagBoxScan>[];

  for (final tag in tags) {
    final foundDBTag = tag.isExisInDB(dbTags);
    final isExist = foundDBTag != null;
    bool isMaster = false;
    bool isMasterAssigned = true;
    bool isExpired = false;
    bool inFoundMaster = false;

    if (isExist) {
      isMaster = foundDBTag.isMaster();
      isMasterAssigned = foundDBTag.isMasterAssigned();
      isExpired = foundDBTag.isExpired();
      if (!isMaster) {
        if (foundDBTag.selectedBox == masterTagName) {
          inFoundMaster = true;
          foundSlaveTagsOfFoundMaster.add(foundDBTag);
          log('***************3 Found Masters Slave Tags Before Remove : ${allSlaveTagInDBOfFoundMaster.toString()}');
          unfoundSlaveTagsOfFoundMaster.remove(foundDBTag);
          log('***************4 Found Masters Slave Tags After Remove : ${allSlaveTagInDBOfFoundMaster.toString()}');
          log('Found Master Tags : ${foundSlaveTagsOfFoundMaster.toString()}');
        } else {
          if (masterTagName != '') {
            foundSlaveTagsOfOtherMaster.add(foundDBTag);
            log('Other Tags : ${foundSlaveTagsOfOtherMaster.toString()}');
          }
        }
      }

      final optimizedTag = OptimizedTagBoxScan(
        tag,
        foundDBTag,
        existsInDB: isExist,
        isMaster: isMaster,
        isMasterAssigned: isMasterAssigned,
        isExpired: isExpired,
        inFoundMaster: inFoundMaster,
      );
      optimizedTags.add(optimizedTag);
    } else {}
  }

  return optimizedTags;
}
