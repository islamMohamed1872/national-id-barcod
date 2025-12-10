class SearchResultModel {
  final String nationalId;
  final String userName;
  final String state;
  final int time;
  final String barcodeNumber;
  final bool isChecked;

  /// NEW FIELDS
  final String? checkedById;
  final int? checkedAt;

  SearchResultModel({
    required this.nationalId,
    required this.userName,
    required this.state,
    required this.time,
    required this.barcodeNumber,
    required this.isChecked,

    this.checkedById,
    this.checkedAt,
  });
}
