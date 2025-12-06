import 'dart:typed_data';

abstract class UserHomeStates {}

class UserHomeInitialState extends UserHomeStates {}

class UserHomeLoadingState extends UserHomeStates {}

class UserHomeBarcodeReadyState extends UserHomeStates {
  final String id;
  UserHomeBarcodeReadyState(this.id);
}

class UserHomeSuccessState extends UserHomeStates {
  final bool canPrint;

  UserHomeSuccessState({this.canPrint = true});
}

class PrintSuccessState extends UserHomeStates {}
class PrintErrorState extends UserHomeStates {
  final String error;

  PrintErrorState({required this.error});
}


// ✅ PRINTING STATE
class UserHomePrintingState extends UserHomeStates {}
class PrintPreparingState extends UserHomeStates {
  final String id;

  PrintPreparingState({required this.id});
}
class PrintRunningState extends UserHomeStates {}

class UserHomeErrorState extends UserHomeStates {
  final String message;
  UserHomeErrorState(this.message);
}

// when IDs list is loading
class UserHomeIdsLoadingState extends UserHomeStates {}

// when IDs loaded successfully
class UserHomeIdsLoadedState extends UserHomeStates {

}

// when an error occurs while loading
class UserHomeIdsErrorState extends UserHomeStates {
  final String message;
  UserHomeIdsErrorState(this.message);
}