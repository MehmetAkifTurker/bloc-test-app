part of 'db_filtering_bloc.dart';

sealed class DbFilteringEvent extends Equatable {
  const DbFilteringEvent();

  @override
  List<Object> get props => [];
}

class DbFilterSelectionEvent extends DbFilteringEvent {
  final FilteringStates filteringStates;

  const DbFilterSelectionEvent({required this.filteringStates});
}
