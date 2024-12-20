part of 'db_filtering_bloc.dart';

sealed class DbFilteringState extends Equatable {
  const DbFilteringState();
  
  @override
  List<Object> get props => [];
}

final class DbFilteringInitial extends DbFilteringState {}
