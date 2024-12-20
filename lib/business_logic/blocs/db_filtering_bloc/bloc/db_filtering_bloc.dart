import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

part 'db_filtering_event.dart';
part 'db_filtering_state.dart';

class DbFilteringBloc extends Bloc<DbFilteringEvent, FilteringStates> {
  DbFilteringBloc() : super(FilteringStates.none) {
    on<DbFilterSelectionEvent>((event, emit) {
      emit(event.filteringStates);
    });
  }
}

enum FilteringStates {
  none,
  pn,
  sn,
  desc,
  type,
  tagType,
  selectedBox,
  expCheck,
}
