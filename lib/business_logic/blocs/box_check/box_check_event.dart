part of 'box_check_bloc.dart';

class BoxCheckEvent extends Equatable {
  const BoxCheckEvent();

  @override
  List<Object> get props => [];
}

class BoxCheckInit extends BoxCheckEvent {}

class BoxCheckStart extends BoxCheckEvent {
  final List<DBTag> dbTags;

  const BoxCheckStart(this.dbTags);
  @override
  List<Object> get props => [dbTags];
}

class BoxCheckStop extends BoxCheckEvent {}

class BoxCheckFilter extends BoxCheckEvent {
  final FilterBoxCheck filter;

  const BoxCheckFilter(this.filter);

  @override
  List<Object> get props => [filter];
}

class BoxCheckSetPower extends BoxCheckEvent {
  final String powerLevel;

  const BoxCheckSetPower({required this.powerLevel});
}
