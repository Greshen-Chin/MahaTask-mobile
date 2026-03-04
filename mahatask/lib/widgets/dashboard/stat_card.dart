import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String footer;
  final Color color;
  final double progress;

  const StatCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.footer, 
    required this.color,
    this.progress = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60, width: 60,
                child: CircularProgressIndicator(
                  value: progress, 
                  strokeWidth: 4, 
                  color: color, 
                  backgroundColor: Colors.white12
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(footer, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    );
  }
}