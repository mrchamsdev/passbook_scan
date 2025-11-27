class BankData {
  String accountHolderName;
  String accountNumber;
  String ifscCode;
  String branchAddress;
  String branchName;

  BankData({
    this.accountHolderName = 'Not detected',
    this.accountNumber = 'Not detected',
    this.ifscCode = 'Not detected',
    this.branchAddress = 'Not detected',
    this.branchName = 'Not detected',
  });

  factory BankData.fromJson(Map<String, dynamic> json) {
    return BankData(
      accountHolderName:
          json['customerName']?.toString().trim() ?? 'Not detected',
      accountNumber: json['accountNumber']?.toString().trim() ?? 'Not detected',
      ifscCode: json['ifscCode']?.toString().trim() ?? 'Not detected',
      branchAddress: json['address']?.toString().trim() ?? 'Not detected',
      branchName: json['branchName']?.toString().trim() ?? 'Not detected',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'address': branchAddress,
    };
  }

  BankData copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? branchAddress,
    String? branchName,
  }) {
    return BankData(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      branchAddress: branchAddress ?? this.branchAddress,
      branchName: branchName ?? this.branchName,
    );
  }
}
