import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatalogHeader extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onAddSelected;

  const CatalogHeader({
    required this.selectedCount,
    required this.onAddSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("Game Catalog", style: GoogleFonts.poppins()),
      backgroundColor: const Color(0xFF171A21),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Center(
          child: Text(
            "$selectedCount Selected",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: onAddSelected,
          icon: const Icon(Icons.add_circle, color: Colors.white),
          tooltip: 'Add Selected Games',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
