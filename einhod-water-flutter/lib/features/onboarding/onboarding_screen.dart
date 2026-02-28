// lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../core/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final String role;
  const OnboardingScreen({super.key, required this.role});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<OnboardingPage> get _pages {
    if (widget.role == 'client') {
      return [
        OnboardingPage(
          icon: '🚰',
          title: 'Request Water Delivery',
          description: 'Order water with just a few taps. Track your delivery in real-time.',
        ),
        OnboardingPage(
          icon: '📊',
          title: 'Track Your Usage',
          description: 'Monitor your water consumption and manage your subscription.',
        ),
        OnboardingPage(
          icon: '🔔',
          title: 'Stay Updated',
          description: 'Get notified when your delivery is on the way.',
        ),
      ];
    } else if (widget.role == 'worker') {
      return [
        OnboardingPage(
          icon: '📍',
          title: 'GPS Tracking',
          description: 'Enable GPS to let customers track their deliveries.',
        ),
        OnboardingPage(
          icon: '✅',
          title: 'Quick Actions',
          description: 'Complete deliveries with one tap. Take photos for proof.',
        ),
        OnboardingPage(
          icon: '💰',
          title: 'Track Earnings',
          description: 'View your daily earnings and submit expenses easily.',
        ),
      ];
    }
    return [
      OnboardingPage(
        icon: '📊',
        title: 'Manage Everything',
        description: 'Control your water delivery business from one place.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.all(4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == _pages.length - 1 ? _complete : _next,
                  child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _complete() async {
    await OnboardingService.markCompleted();
    if (mounted) Navigator.of(context).pop();
  }
}

class OnboardingPage {
  final String icon;
  final String title;
  final String description;
  OnboardingPage({required this.icon, required this.title, required this.description});
}

class _PageView extends StatelessWidget {
  final OnboardingPage page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.icon, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
