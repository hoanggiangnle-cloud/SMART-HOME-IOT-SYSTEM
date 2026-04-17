import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const RoomCard({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 100,
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)]),
        child: Center(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:20))),
      ),
    );
  }
}