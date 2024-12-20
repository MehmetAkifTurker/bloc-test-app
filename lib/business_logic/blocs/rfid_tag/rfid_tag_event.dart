part of 'rfid_tag_bloc.dart';

sealed class RfidTagEvent extends Equatable {
  const RfidTagEvent();

  @override
  List<Object> get props => [];
}

class RfidInit extends RfidTagEvent {}

class RfidScanStart extends RfidTagEvent {
  final List<DBTag> dbTags;

  const RfidScanStart(this.dbTags);
  @override
  List<Object> get props => [dbTags];
}

class RfidScanStop extends RfidTagEvent {}

class RfidFilterTags extends RfidTagEvent {
  final RfidFilter filter;

  const RfidFilterTags(this.filter);

  @override
  List<Object> get props => [filter];
}

class RfidSetPower extends RfidTagEvent {
  final String powerLevel;

  const RfidSetPower({required this.powerLevel});
}
