import 'package:flutter/material.dart';

class LowStockBanner extends StatelessWidget {
  final List<String> productNames;

  const LowStockBanner({super.key, required this.productNames});

  @override
  Widget build(BuildContext context) {
    if (productNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A3412), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${productNames.length} productos con stock bajo',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C2D12), fontSize: 13),
                ),
                Text(
                  productNames.join(', '),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}