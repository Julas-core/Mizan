import 'package:flutter/material.dart';
import 'create_custom_goal_screen.dart';

class DefineYourGoalScreen extends StatefulWidget {
  const DefineYourGoalScreen({super.key});

  @override
  State<DefineYourGoalScreen> createState() => _DefineYourGoalScreenState();
}

class _DefineYourGoalScreenState extends State<DefineYourGoalScreen> {
  String? _selectedGoal;
  String? _selectedGoalImageUrl;

  void _onContinue() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a goal or choose Custom Goal.'),
        ),
      );
      return;
    }

    if (_selectedGoal == 'Custom Goal') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const CreateCustomGoalScreen(isCustomGoal: true),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateCustomGoalScreen(
            isCustomGoal: false,
            initialGoalName: _selectedGoal,
            initialGoalImageUrl: _selectedGoalImageUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Set Your Goal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),

            // Progress Bar (3 of 4)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ONBOARDING PROGRESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '3 of 4',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: surfaceDark,
                    color: primaryColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Header Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  Text(
                    'What are you saving for?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pick a primary goal to help our AI calculate your opportunity costs and personalize your path.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Goals Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                children: [
                  _buildGoalCard(
                    'New Laptop',
                    Icons.laptop_mac,
                    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=500&auto=format&fit=crop',
                  ),
                  _buildGoalCard(
                    'Dream Trip',
                    Icons.beach_access,
                    'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?q=80&w=500&auto=format&fit=crop',
                  ),
                  _buildGoalCard(
                    'Emergency Fund',
                    Icons.savings,
                    'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?q=80&w=500&auto=format&fit=crop',
                  ),
                  _buildGoalCard(
                    'Home Downpayment',
                    Icons.home,
                    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=500&auto=format&fit=crop',
                  ),
                  _buildGoalCard(
                    'New Car',
                    Icons.directions_car,
                    'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?q=80&w=500&auto=format&fit=crop',
                  ),
                  _buildCustomGoalCard(),
                ],
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bgDark, bgDark.withOpacity(0.0)],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Choosing a goal now doesn't lock you in. You can change your focus at any time from your dashboard settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, IconData icon, String imageUrl) {
    final isSelected = _selectedGoal == title;
    const primaryColor = Color(0xFF30e8c9);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = title;
          _selectedGoalImageUrl = imageUrl;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isSelected ? 0.4 : 0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(Icons.check_circle, color: primaryColor, size: 24),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: primaryColor, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGoalCard() {
    final isSelected = _selectedGoal == 'Custom Goal';
    const primaryColor = Color(0xFF30e8c9);
    const surfaceDark = Color(0xFF1e293b);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = 'Custom Goal';
          _selectedGoalImageUrl = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? surfaceDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : surfaceDark,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_circle,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Custom Goal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
