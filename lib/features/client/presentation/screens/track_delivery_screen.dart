// lib/features/client/presentation/screens/track_delivery_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrackDeliveryScreen extends ConsumerWidget {
  final String orderId;

  const TrackDeliveryScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // This would be a real map widget in a real app
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
               image: DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCsicL1gWy6UmZv6y9hI9clgXB-4Kbiik4LY_5xaVZybdOOSjlc7DMeYx-15WRMVPciqBZxuKJNHxN6zP1Fjio4nX9VzH6aZzMIlBpjmZCQz9PJOhgqTQUY61sXYahSZ0hjPKppOLANtOH6omR9qhvM-uewENUONfTPsazVqIICU045ctXpo9PLQW8ZHNFKL6cX34gGZTjeoBefgey1DkxYKHUCDii16fgo_hu8sK9YbSAE-OQsr5XTzDJ7O6_0EWqYjlqb7MyOociN'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context, icon: Icons.arrow_back, onTap: () => context.pop()),
                   _buildGlassChip(context, label: 'Order #$orderId'),
                  _buildGlassButton(context, icon: Icons.support_agent, onTap: () {}),
                ],
              ),
            ),
          ),

          _DraggableSheet(orderId: orderId),
        ],
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            )
          ]
        ),
        child: Icon(icon, color: Colors.grey[800]),
      ),
    );
  }
   Widget _buildGlassChip(BuildContext context, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          )
        ]
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _DraggableSheet extends StatelessWidget {
  final String orderId;
  const _DraggableSheet({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            border: Border.all(color: Colors.white.withOpacity(0.5))
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arriving Soon', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Estimated Arrival', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('10:45 AM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                         Chip(
                          label: Text('On Time', style: TextStyle(color: Colors.blue)),
                          backgroundColor: Colors.blue.shade50,
                        )
                      ],
                    )
                  ],
                ),
                 const SizedBox(height: 16),
                _DriverCard(),
                 const SizedBox(height: 16),
                _Timeline(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
             const CircleAvatar(
              radius: 24,
              // backgroundImage: NetworkImage('...'), // TODO
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ahmed Al-Rashid', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('4.9 • Delivery Expert', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call),
              color: Colors.green,
              onPressed: () {},
            ),
             IconButton(
              icon: const Icon(Icons.sms),
               color: Colors.blue,
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
           _TimelineTile(
            icon: Icons.inventory_2,
            title: 'Dispatched',
            subtitle: '09:30 AM',
            isFirst: true,
            isCompleted: true,
          ),
           _TimelineTile(
            icon: Icons.local_shipping,
            title: 'En Route',
            subtitle: 'Driver is on the way',
            isCompleted: true,
          ),
           _TimelineTile(
            icon: Icons.home,
            title: 'Arriving',
            subtitle: 'Expected in 2 mins',
            isLast: true,
            isActive: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final bool isActive;

  const _TimelineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.isCompleted = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.blue : (isCompleted ? Colors.grey[300] : Colors.white),
                border: Border.all(color: isActive ? Colors.blue : Colors.grey[300]!)
              ),
              child: Icon(icon, color: isActive ? Colors.white : (isCompleted ? Colors.white : Colors.grey[400])),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.grey[300] : Colors.grey[200],
              )
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.blue : Colors.black)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        )
      ],
    );
  }
}
