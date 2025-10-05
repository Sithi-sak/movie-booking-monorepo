import 'package:flutter/material.dart';
import 'package:movie_booking_app/core/theme/app_theme.dart';
import 'package:movie_booking_app/data/developer_data.dart';
import 'package:movie_booking_app/data/models/developer_model.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: DeveloperData.teamMembers.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final dev = DeveloperData.teamMembers[index];
            return _AnimatedDeveloperCard(
              developer: dev,
              delay: index * 150,
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedDeveloperCard extends StatefulWidget {
  final DeveloperModel developer;
  final int delay;

  const _AnimatedDeveloperCard({
    required this.developer,
    required this.delay,
  });

  @override
  State<_AnimatedDeveloperCard> createState() => _AnimatedDeveloperCardState();
}

class _AnimatedDeveloperCardState extends State<_AnimatedDeveloperCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final developer = widget.developer;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 26, 26, 26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundImage: AssetImage(developer.imageUrl),
                backgroundColor: Colors.grey[850],
              ),
              const SizedBox(height: 14),
              Text(
                developer.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                developer.role,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                developer.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              _socialRow(developer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialRow(DeveloperModel dev) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconButton(Icons.email, dev.email),
        const SizedBox(width: 14),
        _iconButton(Icons.code, dev.github),
      ],
    );
  }

  Widget _iconButton(IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {}, // Add link logic here
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: AppTheme.primaryRed, size: 20),
      ),
    );
  }
}
