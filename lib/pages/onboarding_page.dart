// lib/pages/onboarding_page.dart (COMPLETE CODE)

import 'package:flutter/material.dart';
import '../services/profile_service.dart'; // To save the data
import 'home_page.dart'; // Final destination

// ----------------------------------------------------
// --- STEP 1: USERNAME SETUP ---
// ----------------------------------------------------

class UsernameSetup extends StatefulWidget {
  final Function(String username) onNext;
  final VoidCallback onSkip;

  const UsernameSetup({
    Key? key,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<UsernameSetup> createState() => _UsernameSetupState();
}

class _UsernameSetupState extends State<UsernameSetup> {
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // --- Validation Logic ---
  void _handleNext() {
    setState(() {
      _error = null;
    });

    final String username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _error = 'Please enter a username';
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _error = 'Username must be at least 3 characters';
      });
      return;
    }

    if (username.length > 20) {
      setState(() {
        _error = 'Username must be less than 20 characters';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _error = 'Username can only contain letters, numbers, and underscores';
      });
      return;
    }

    widget.onNext(username);
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background Gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFFAF5FF), // purple-50
              Color(0xFFFDF2F8), // pink-50
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                // Card style
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress Indicator
                      Row(
                        children: [
                          // Step 1 Active
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA), // purple-600
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Step 2 Inactive
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB), // gray-200
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // purple-500 to blue-500
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_outline, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              'Set Up Your Profile',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), 
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose a username to personalize your experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)), 
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username Input
                      const Text(
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151)), 
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        onChanged: (value) {
                          if (_error != null) {
                            setState(() {
                              _error = null;
                            });
                          }
                        },
                        maxLength: 20,
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          counterText: "",
                          errorText: _error,
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      if (_error != null) const SizedBox(height: 8),

                      const SizedBox(height: 24),

                      // Next Button
                      ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: const Color(0xFF9333EA), // purple-600
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Next', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 12),

                      // Skip Button
                      TextButton(
                        onPressed: widget.onSkip,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Color(0xFF4B5563), // gray-600
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // Step Indicator outside the main card
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 20.0),
        child: const Text(
          'Step 1 of 2',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)), // gray-600
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// --- STEP 2: GENRE SETUP ---
// ----------------------------------------------------

class GenreSetup extends StatefulWidget {
  final Function(List<String> genres) onComplete;

  const GenreSetup({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<GenreSetup> createState() => _GenreSetupState();
}

class _GenreSetupState extends State<GenreSetup> {
  List<String> _preferredGenres = [];
  
  final List<String> _allGenres = [
    'Strategy', 'Eurogame', 'Deck Building', 
    'Cooperative', 'Party Game', 'Thematic', 
    'Abstract', 'Miniatures', 'Legacy', 
    'Dice Rolling', 'Worker Placement'
  ];

  void _toggleGenre(String genre) {
    setState(() {
      if (_preferredGenres.contains(genre)) {
        _preferredGenres.remove(genre);
      } else if (_preferredGenres.length < 5) {
        _preferredGenres.add(genre);
      }
    });
  }

  // --- UI Components ---
  Widget _buildGenreTag(String genre) {
    final isSelected = _preferredGenres.contains(genre);
    return InkWell(
      onTap: () => _toggleGenre(genre),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9333EA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9333EA) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Text(
          genre,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), 
              Color(0xFFFAF5FF),
              Color(0xFFFDF2F8),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Indicator (Step 2 Active)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA), // purple-600 (Completed)
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA), // purple-600 (Active)
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_border, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Choose Your Genres',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select up to 5 genres you enjoy most.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Genre Tags
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allGenres.map(_buildGenreTag).toList(),
                    ),
                    
                    const SizedBox(height: 32),

                    // Complete Button
                    ElevatedButton(
                      onPressed: () => widget.onComplete(_preferredGenres),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFF9333EA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Finish Onboarding', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Text(
          'Step 2 of 2 (Selected: ${_preferredGenres.length})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// --- ONBOARDING PAGE CONTAINER (Main Widget) ---
// ----------------------------------------------------

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  String _tempUsername = '';
  List<String> _tempGenres = [];

  void _onUsernameSetupComplete(String username) {
    setState(() {
      _tempUsername = username;
      _currentStep = 1;
    });
  }
  
  // This function is called when the user finishes all steps
  void _onOnboardingComplete(List<String> genres) async { // Added 'async'
    _tempGenres = genres;
    
    // 💡 CORE: Call the service to save data to Firestore
    if (_tempUsername.isNotEmpty) {
      await ProfileService.saveOnboardingData(
        username: _tempUsername,
        preferredGenres: _tempGenres,
      );
    }
    
    // Redirect to HomePage (final destination)
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          // Pass the new username to HomePage for display in the AppBar
          builder: (context) => HomePage(_tempUsername), 
        ),
        (Route<dynamic> route) => false,
      );
    }
  }
  
  // This function is called if the user skips Step 1
  void _onSkip() {
    _onOnboardingComplete([]); 
  }


  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentStep,
      children: [
        // Step 1: Username Setup
        UsernameSetup( 
          onNext: _onUsernameSetupComplete,
          onSkip: _onSkip,
        ),
        
        // Step 2: Genre Setup
        GenreSetup(
          onComplete: _onOnboardingComplete,
        ),
      ],
    );
  }
}