part of 'db_tag_popup_cubit.dart';

//enum DbTagPopupState { box, tool }

abstract class DbTagPopupState extends Equatable {
  const DbTagPopupState();

  @override
  List<Object> get props => [];
}

class Box extends DbTagPopupState {}

class Tool extends DbTagPopupState {}

class SelectedDate extends DbTagPopupState {
  final DateTime selectedDateTime;

  const SelectedDate(this.selectedDateTime);
}
