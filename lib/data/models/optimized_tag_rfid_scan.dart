import 'package:water_boiler_rfid_labeler/data/models/db_tag.dart';
import 'package:water_boiler_rfid_labeler/data/models/tag_epc.dart';

// This class is for connecting the scanned tags and the database tags.
// When tag is scanned, then processRfidScanTags is run.
// originalTag is TagEpc type which come from RFID scanned tag.
// originalDBTag is Database tag comes from Database.
// Other bool variables ara calculated in processRfidScanTags function.
//

class OptimizedTagRfidScan {
  final TagEpc originalTag;
  final DBTag? originalDBTag;
  final bool existsInDB;
  final bool isMaster;
  final bool isMasterAssigned;
  final bool isExpired;

  OptimizedTagRfidScan(this.originalTag, this.originalDBTag,
      {required this.existsInDB,
      this.isMaster = false,
      this.isMasterAssigned = true,
      this.isExpired = false});
}

// processRfidScanTags functions parameter are tags, dbTags, foundInDBTags and notFoundInDBTags.
// tags are List coming from rfid.
// dbTags are coming from database.
// foundInDBTags and notFoundInDBTags are sets. They are created from outside. But in this function
// elements are added to this sets.
// Set is used for overcome duplication. Tags are comming from Rfid Scan. And when scanning same TagEpc
// is coming. So not to add the duplicated tags to foundInDBTags and notFoundInDBTags, sets are used.
//

List<OptimizedTagRfidScan> processRfidScanTags({
  required List<TagEpc> tags,
  required List<DBTag> dbTags,
  required Set<DBTag> foundInDBTags,
  required Set<TagEpc> notFoundInDBTags,
}) {
  final optimizedTags = <OptimizedTagRfidScan>[];

  for (final tag in tags) {
    final foundDBTag = tag.isExisInDB(dbTags);
    final isExist = foundDBTag != null;
    bool isMaster = false;
    bool isMasterAssigned = true;
    bool isExpired = false;

    if (isExist) {
      isMaster = foundDBTag.isMaster();
      isMasterAssigned = foundDBTag.isMasterAssigned();
      isExpired = foundDBTag.isExpired();
      foundInDBTags.add(foundDBTag);
    } else {
      notFoundInDBTags.add(tag);
    }
    final optimizedTag = OptimizedTagRfidScan(
      tag,
      foundDBTag,
      existsInDB: isExist,
      isMaster: isMaster,
      isMasterAssigned: isMasterAssigned,
      isExpired: isExpired,
    );

    optimizedTags.add(optimizedTag);
  }

  return optimizedTags;
}
