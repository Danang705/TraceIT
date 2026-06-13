import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status; // 'hilang', 'ditemukan', 'selesai'

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'hilang':
      case 'lost':
        bgColor = AppColors.tagLostBg;
        textColor = AppColors.tagLostText;
        text = 'Hilang';
        break;
      case 'ditemukan':
      case 'found':
        bgColor = AppColors.tagFoundBg;
        textColor = AppColors.tagFoundText;
        text = 'Ditemukan';
        break;
      case 'selesai':
      case 'resolved':
        bgColor = AppColors.tagResolvedBg;
        textColor = AppColors.tagResolvedText;
        text = 'Selesai';
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
