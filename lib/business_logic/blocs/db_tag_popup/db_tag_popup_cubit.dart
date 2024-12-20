import 'package:bloc/bloc.dart';
import 'package:bloc_test_app/data/models/const.dart';
import 'package:equatable/equatable.dart';

part 'db_tag_popup_state.dart';

class DbTagPopupCubit extends Cubit<DbTagPopupState> {
  DbTagPopupCubit() : super(Box());

  void changeVisibility(int tagType) {
    emit(tagType == toolTagNo ? Tool() : Box());
  }

  void updateSelectedDate(DateTime selectedDateTime) {
    emit(SelectedDate(selectedDateTime));
  }
}
