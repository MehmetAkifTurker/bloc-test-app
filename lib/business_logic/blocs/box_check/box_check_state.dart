part of 'box_check_bloc.dart';

abstract class BoxCheckState extends Equatable {
  const BoxCheckState();

  @override
  List<Object> get props => [];
}

class BoxCheckIdle extends BoxCheckState {}

class BoxCheckInitializing extends BoxCheckState {
  final RfidStatus status;

  const BoxCheckInitializing({required this.status});

  @override
  List<Object> get props => [status];
}

class BoxCheckMasterNotFoundYet extends BoxCheckState {}

class BoxCheckScanning extends BoxCheckState {
  final List<TagEpc> tags;
  final List<OptimizedTagBoxScan> optimizedTags;
  final FilterBoxCheck selectedFilter;
  final String foundMaster;
  final Set<DBTag> allSlaveTagInDBOfFoundMaster;
  final Set<DBTag> foundSlaveTagsOfFoundMaster;
  final Set<DBTag> unfoundSlaveTagsOfFoundMaster;
  final Set<DBTag> foundSlaveTagsOfOtherMasters;
  final int allSlaveTagInDBOfFoundMasterLenght;

  const BoxCheckScanning({
    required this.tags,
    required this.optimizedTags,
    required this.foundMaster,
    required this.foundSlaveTagsOfFoundMaster,
    required this.unfoundSlaveTagsOfFoundMaster,
    required this.foundSlaveTagsOfOtherMasters,
    required this.allSlaveTagInDBOfFoundMaster,
    this.selectedFilter = FilterBoxCheck.foundBoxFoundTools,
    this.allSlaveTagInDBOfFoundMasterLenght = 0,
  });

  @override
  List<Object> get props => [tags, selectedFilter, foundMaster];
}

class BoxCheckStoppped extends BoxCheckState {}

class BoxCheckError extends BoxCheckState {}

class BoxCheckDisconnected extends BoxCheckState {}

enum FilterBoxCheck {
  foundBoxTotalTools,
  foundBoxFoundTools,
  foundBoxUnfoundTools,
  otherBoxesFoundTools
}
