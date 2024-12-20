part of 'rfid_tag_bloc.dart';

abstract class RfidTagState extends Equatable {
  const RfidTagState();

  @override
  List<Object> get props => [];

  get status => null;
}

class RfidIdle extends RfidTagState {}

class RfidInitializing extends RfidTagState {
  final RfidStatus status;

  const RfidInitializing({required this.status});

  @override
  List<Object> get props => [status];
}

class RfidScanning extends RfidTagState {
  final List<TagEpc> tags;
  final List<OptimizedTagRfidScan> optimizedTag;
  final RfidFilter selectedFilter;
  final Set<DBTag> foundInDBTags;
  final Set<TagEpc> notFoundInDBTags;

  const RfidScanning({
    required this.tags,
    required this.optimizedTag,
    this.selectedFilter = RfidFilter.all,
    required this.foundInDBTags,
    required this.notFoundInDBTags,
  });

  @override
  List<Object> get props => [tags, selectedFilter];
}

class RfidStopped extends RfidTagState {}

class RfidError extends RfidTagState {}

class RfidDisconnected extends RfidTagState {}

enum RfidFilter { all, saved, newTags }
