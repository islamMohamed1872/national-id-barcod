
import '../../../models/search_ids_model.dart';

abstract class SearchIdsStates {}

class SearchIdsInitialState extends SearchIdsStates {}

class SearchLoadingState extends SearchIdsStates {}

class SearchSuccessState extends SearchIdsStates {
  final SearchResultModel model;
  SearchSuccessState(this.model);
}

class SearchEmptyState extends SearchIdsStates {}

class SearchErrorState extends SearchIdsStates {
  final String message;
  SearchErrorState(this.message);
}

class AdminIdErrorState extends SearchIdsStates {
  final String message;
  AdminIdErrorState(this.message);
}

class PrintSuccessState extends SearchIdsStates {}
class PrintPreparingState extends SearchIdsStates {
  final String nationalId;

  PrintPreparingState({required this.nationalId});
}
class PrintRunningState extends SearchIdsStates {}


class CheckToggleSuccessState extends SearchIdsStates {
  final bool isChecked;
  CheckToggleSuccessState(this.isChecked);
}