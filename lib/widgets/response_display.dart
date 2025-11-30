import 'package:flutter/material.dart';
import '../models/bank_data.dart';

class ResponseDisplay extends StatefulWidget {
  final BankData bankData;
  final VoidCallback onSave;
  final bool isProcessing;

  const ResponseDisplay({
    super.key,
    required this.bankData,
    required this.onSave,
    required this.isProcessing,
  });

  @override
  State<ResponseDisplay> createState() => _ResponseDisplayState();
}

class _ResponseDisplayState extends State<ResponseDisplay> {
  late BankData _editableBankData;
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _editableBankData = widget.bankData;
    _updateControllers();
  }

  @override
  void didUpdateWidget(covariant ResponseDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bankData != widget.bankData) {
      _editableBankData = widget.bankData;
      _updateControllers();
    }
  }

  void _updateControllers() {
    _controllers[0].text = _editableBankData.accountHolderName;
    _controllers[1].text = _editableBankData.accountNumber;
    _controllers[2].text = _editableBankData.ifscCode;
    _controllers[3].text = _editableBankData.branchName;
    _controllers[4].text = _editableBankData.branchAddress;
  }

  void _onFieldChanged(int index, String value) {
    setState(() {
      switch (index) {
        case 0:
          _editableBankData = _editableBankData.copyWith(
            accountHolderName: value,
          );
          break;
        case 1:
          _editableBankData = _editableBankData.copyWith(accountNumber: value);
          break;
        case 2:
          _editableBankData = _editableBankData.copyWith(ifscCode: value);
          break;
        case 3:
          _editableBankData = _editableBankData.copyWith(branchName: value);
          break;
        case 4:
          _editableBankData = _editableBankData.copyWith(branchAddress: value);
          break;
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 12),
              Text(
                'Extracted Bank Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildEditableFields(),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.isProcessing ? null : () => widget.onSave(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: widget.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save to Database',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEditableFields() {
    const List<Map<String, String>> fields = [
      {'emoji': '👤', 'label': 'Customer Name'},
      {'emoji': '🔢', 'label': 'Account Number'},
      {'emoji': '🏛️', 'label': 'IFSC Code'},
      {'emoji': '🏢', 'label': 'Branch Name'},
      {'emoji': '📍', 'label': 'Branch Address'},
    ];

    return List.generate(fields.length, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == fields.length - 1 ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  fields[index]['emoji']!,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  fields[index]['label']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _controllers[index],
                onChanged: (value) => _onFieldChanged(index, value),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                  hintText: 'Enter ${fields[index]['label']}',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
