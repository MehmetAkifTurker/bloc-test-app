import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void navigateToPage(int index) {
    emit(index);
  }
}

abstract class NavigationEvent {
  const NavigationEvent();
}

class NavigateTo extends NavigationEvent {
  final String routeName;

  const NavigateTo(this.routeName);
}
