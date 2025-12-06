class SearchResultModel {
  final String nationalId;
  final String userName;
  final String state;
  final String barcodeNumber;
  final int time;
  final bool isChecked;
  SearchResultModel({
    required this.nationalId,
    required this.userName,
    required this.state,
    required this.barcodeNumber, required this.time, required this.isChecked,
  });
}
