import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VpnHomePage(),
      builder: (context, child) {
        return MediaQuery(
          // ignore: deprecated_member_use
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

// Optimized CustomPainter with caching
class CloudPainter extends CustomPainter {
  final double opacity;
  
  CloudPainter({this.opacity = 0.8});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Base circle
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.6;
    final radius = size.width * 0.3;
    
    path.addOval(Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    ));
    
    // Additional circle bumps to form cloud shape
    path.addOval(Rect.fromCircle(
      center: Offset(centerX - radius * 0.8, centerY - radius * 0.2),
      radius: radius * 0.6,
    ));
    
    path.addOval(Rect.fromCircle(
      center: Offset(centerX + radius * 0.8, centerY - radius * 0.1),
      radius: radius * 0.7,
    ));
    
    path.addOval(Rect.fromCircle(
      center: Offset(centerX, centerY - radius * 0.5),
      radius: radius * 0.7,
    ));
    
    // Draw the cloud
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CloudPainter oldDelegate) => 
    oldDelegate.opacity != opacity;
}

// Cloud data class
class Cloud {
  double x;
  double y;
  double size;
  double baseSpeed;
  double currentSpeed;
  double opacity;
  
  Cloud({
    required this.x, 
    required this.y, 
    required this.size, 
    required this.baseSpeed, 
    required this.opacity
  }) : currentSpeed = baseSpeed;
}

class VpnHomePage extends StatefulWidget {
  const VpnHomePage({Key? key}) : super(key: key);

  @override
  _VpnHomePageState createState() => _VpnHomePageState();
}

class AnimatedCircles extends StatelessWidget {
  final AnimationController controller;
  
  const AnimatedCircles({Key? key, required this.controller}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final double size = 150.0 + (index * 60.0);
            final double offset = index * 0.2;
            final double value = ((controller.value + offset) % 1.0);
            final double opacity = (1.0 - value) * 0.4;
            
            return Transform.scale(
              scale: value * 1.5,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(155, 75, 75, 75).withOpacity(opacity),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
class _VpnHomePageState extends State<VpnHomePage> with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
  bool isDisconnecting = false; // New state to track disconnection
  bool hasCredentials = false;
  String username = "";
  String password = "";
  
  late AnimationController _animationController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColor1Animation;
  late Animation<Color?> _backgroundColor2Animation;
  
  // Using fewer clouds and fewer repaints
  late List<Cloud> clouds;
  final _random = math.Random();
  Timer? _cloudAnimationTimer;
  
  // Track keyboard visibility
  bool _isKeyboardVisible = false;
  FocusNode _dialogFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  
    // Initialize color animations
    _backgroundColor1Animation = ColorTween(
      begin: _getStaticBackgroundColor1(),
      end: _getStaticBackgroundColor1(),
    ).animate(_colorAnimationController);
    
    _backgroundColor2Animation = ColorTween(
      begin: _getStaticBackgroundColor2(),
      end: _getStaticBackgroundColor2(),
    ).animate(_colorAnimationController);
    
    // Fewer clouds (8 instead of 15)
    clouds = List.generate(12, (_) => _generateCloud());
    
    // Load credentials and start animations
    _loadCredentials();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCloudAnimation();
    });
  }

  void _updateColorAnimations() {
    _backgroundColor1Animation = ColorTween(
      begin: _backgroundColor1Animation.value ?? _getStaticBackgroundColor1(),
      end: _getStaticBackgroundColor1(),
    ).animate(_colorAnimationController);
    
    _backgroundColor2Animation = ColorTween(
      begin: _backgroundColor2Animation.value ?? _getStaticBackgroundColor2(),
      end: _getStaticBackgroundColor2(),
    ).animate(_colorAnimationController);
    
    _colorAnimationController.reset();
    _colorAnimationController.forward();
  }


  Color _getCurrentBackgroundColor1() {
    return _backgroundColor1Animation.value ?? _getStaticBackgroundColor1();
  }

  Color _getCurrentBackgroundColor2() {
    return _backgroundColor2Animation.value ?? _getStaticBackgroundColor2();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        username = prefs.getString('username') ?? "";
        password = prefs.getString('password') ?? "";
        hasCredentials = username.isNotEmpty && password.isNotEmpty;
      });
    }
  }

  Future<void> _saveCredentials(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user);
    await prefs.setString('password', pass);
  }
  
  Cloud _generateCloud() {
    return Cloud(
      x: _random.nextDouble() * 2 - 0.5,
      y: _random.nextDouble(),
      size: _random.nextDouble() * 0.3 + 0.1,
      baseSpeed: _random.nextDouble() * 0.001 + 0.0005,
      opacity: _random.nextDouble() * 0.4 + 0.1,
    );
  }
  
  void _startCloudAnimation() {
    // Cancel any existing timer
    _cloudAnimationTimer?.cancel();
    
    // Use Timer instead of recursive Future.delayed for better performance
    _cloudAnimationTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) {
        setState(() {
          for (var cloud in clouds) {
            cloud.x += cloud.currentSpeed * 3;
            
            if (cloud.x > 1.5) {
              cloud.x = -0.5 - _random.nextDouble();
              cloud.y = _random.nextDouble() * 0.8;
            }
          }
        });
      }
    });
  }
  
  void _accelerateClouds() {
    setState(() {
      for (var cloud in clouds) {
        cloud.currentSpeed = cloud.baseSpeed * 5;
      }
    });
  }

  void _decelerateClouds() {
    setState(() {
      for (var cloud in clouds) {
        cloud.currentSpeed = cloud.baseSpeed;
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _colorAnimationController.dispose();
    _cloudAnimationTimer?.cancel();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _connect() {
    if (!hasCredentials) {
      _showCredentialsDialog();
      return;
    }

    setState(() {
      isConnecting = true;
      isDisconnecting = false;
    });
    _updateColorAnimations();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = true;
        });
        _updateColorAnimations();
        _accelerateClouds();
      }
    });
  }
  
  void _disconnect() {
    setState(() {
      isDisconnecting = true;
      isConnecting = false;
      isConnected = false; // Set this to false immediately to trigger background color change
    });
    _updateColorAnimations(); // Update animations to apply color change
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isDisconnecting = false;
        });
        _updateColorAnimations(); // Update animations again
        _decelerateClouds();
      }
    });
  }
  
  void _showCredentialsDialog() {
    String tempUsername = username;
    String tempPassword = password;
    bool passwordVisible = false; // Add this variable to control password visibility
    
    // Define a theme color variable for easy editing
    Color theme_color = const Color.fromARGB(255, 176, 177, 179); // You can change this to any color you want
    
    // Create controllers for the text fields
    final TextEditingController usernameController = TextEditingController(text: username);
    final TextEditingController passwordController = TextEditingController(text: password);
    
    // Use FocusScope to handle keyboard properly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Get the available screen height
        final double screenHeight = MediaQuery.of(context).size.height;
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return GestureDetector(
              // This allows tapping outside of text fields to dismiss keyboard
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5), // Reduced opacity for the base color
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                        // Apply a blur effect using BackdropFilter
                        backgroundBlendMode: BlendMode.overlay,
                      ),
                      // Wrap with BackdropFilter for the blur effect
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enter Your Account Credentials",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme_color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.person, color: theme_color),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme_color, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.85),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                style: TextStyle(fontSize: 16),
                                onChanged: (value) {
                                  tempUsername = value;
                                },
                                // Automatically focus on the first field
                                autofocus: true,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.lock, color: theme_color),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        passwordVisible = !passwordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme_color, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.85),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                style: TextStyle(fontSize: 16),
                                obscureText: !passwordVisible,
                                onChanged: (value) {
                                  tempPassword = value;
                                },
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) async {
                                  if (tempUsername.isNotEmpty && tempPassword.isNotEmpty) {
                                    await _saveCredentials(tempUsername, tempPassword);
                                    if (mounted) {
                                      setState(() {
                                        username = tempUsername;
                                        password = tempPassword;
                                        hasCredentials = true;
                                      });
                                      Navigator.pop(context);
                                      _connect();
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme_color,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel", 
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (tempUsername.isNotEmpty && tempPassword.isNotEmpty) {
                                        await _saveCredentials(tempUsername, tempPassword);
                                        if (mounted) {
                                          setState(() {
                                            username = tempUsername;
                                            password = tempPassword;
                                            hasCredentials = true;
                                          });
                                          Navigator.pop(context);
                                          _connect();
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                      backgroundColor: theme_color,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      "Login", 
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    if (mounted) {
      setState(() {
        username = "";
        password = "";
        hasCredentials = false;
      });
    }
  }
  
  Color _getStaticBackgroundColor1() {
    if (isConnected) {
      return Colors.green.shade300;
    } else if (isConnecting || isDisconnecting) {
      return const Color(0xFFFFA726);
    } else {
      return const Color.fromARGB(255, 246, 122, 100); // Default red
    }
  }

  Color _getStaticBackgroundColor2() {
    if (isConnected) {
      return Colors.lightGreen.shade500;
    } else if (isConnecting || isDisconnecting) {
      return const Color(0xFFFB8C00); // Orange 600
    } else {
      return const Color.fromARGB(255, 244, 39, 3); // Default dark red
    }
  }

  // We separate the clouds builder to avoid rebuilding the entire widget tree
  List<Widget> _buildCloudWidgets(Size screenSize) {
    return clouds.map((cloud) {
      return Positioned(
        left: screenSize.width * cloud.x,
        top: screenSize.height * cloud.y,
        child: Opacity(
          opacity: cloud.opacity,
          child: Transform.scale(
            scale: 1 + (cloud.size * 0.5),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(
                  screenSize.width * cloud.size,
                  screenSize.width * cloud.size * 0.6,
                ),
                painter: CloudPainter(opacity: cloud.opacity),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and keyboard metrics
    final Size screenSize = MediaQuery.of(context).size;
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardVisible = bottomPadding > 0;
    
    // Calculate safe bottom padding (to prevent overflow)
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Wrap the scaffold in a GestureDetector to dismiss keyboard when tapping outside
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // This ensures the scaffold resizes when keyboard appears
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background Gradient
            AnimatedBuilder(
              animation: Listenable.merge([_animationController, _colorAnimationController]),
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCurrentBackgroundColor1(),
                        _getCurrentBackgroundColor2(),
                      ],
                      stops: const [0.0, 1.0],
                      transform: GradientRotation(_animationController.value * 2 * math.pi),
                    ),
                  ),
                );
              },
            ),
            
            // Cloud Animations with RepaintBoundary (not affected by keyboard)
            RepaintBoundary(
              child: Stack(
                children: _buildCloudWidgets(screenSize),
              ),
            ),
            
            // Center Button - Adjusted position when keyboard is visible
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: screenSize.height * 0.4,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none, // Allow children to overflow without affecting layout
                  children: [
                    // Connection Button - Kept separate from animations
                    RepaintBoundary(
                      child: GestureDetector(
                        onTap: (isConnecting || isDisconnecting) ? null : (isConnected ? _disconnect : _connect),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Add a specific color for disconnecting state
                            color: isConnecting 
                                ? const Color.fromARGB(255, 207, 159, 0)  // Yellow/amber color for connecting
                                : (isDisconnecting
                                    ? const Color.fromARGB(255, 207, 159, 0)   // Blue for disconnecting
                                    : (isConnected 
                                        ? const Color.fromARGB(255, 17, 100, 20)  // Green for connected
                                        : const Color.fromARGB(255, 114, 19, 13))), // Red for disconnected
                            boxShadow: [
                              BoxShadow(
                                // Also update the shadow color for disconnecting state
                                color: (isConnecting
                                    ? const Color.fromARGB(255, 245, 215, 66)  // Yellow/amber glow
                                    : (isDisconnecting
                                        ? const Color.fromARGB(255, 245, 215, 66) // Blue glow
                                        : (isConnected 
                                            ? const Color.fromARGB(255, 124, 179, 126)  // Green glow
                                            : const Color.fromARGB(255, 240, 130, 122))  // Red glow
                                        )).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: (isConnecting || isDisconnecting)
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Glow effect
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: isConnected 
                                                  ? const Color.fromARGB(255, 44, 163, 44).withOpacity(0.7)
                                                  : const Color.fromARGB(255, 224, 71, 71).withOpacity(0.7),
                                              spreadRadius: 5,
                                              blurRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // The actual icon
                                      Icon(
                                        Icons.power_settings_new,
                                        size: keyboardVisible ? 40 : 50,
                                        color: isConnected 
                                            ? const Color.fromARGB(255, 44, 163, 44) 
                                            : const Color.fromARGB(255, 224, 71, 71),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Animated Circles - Now in a separate widget with absolute positioning
                    if (!keyboardVisible)
                      Positioned.fill(
                        child: IgnorePointer( // Make sure circles don't interfere with button taps
                          child: AnimatedCircles(controller: _animationController),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Header with BlurFilter
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        left: 20,
                        right: 20,
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 71, 71, 71).withOpacity(0.4),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Secret X",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isConnected 
                                ? "Connected" 
                                : (isConnecting 
                                    ? "Connecting..." 
                                    : (isDisconnecting 
                                        ? "Disconnecting..." 
                                        : "Disconnected")),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
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
            
            // Bottom Info Card with BlurFilter - Improved keyboard handling
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              // Properly adjust position based on keyboard and safe area
              bottom: keyboardVisible 
                 ? bottomPadding + 10
                 : safeBottomPadding + 10,
              left: 20,
              right: 20,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // This helps prevent overflow
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                hasCredentials ? username : "Not set",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Status",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                isConnected 
                                  ? "Connected" 
                                  : (isConnecting 
                                      ? "Connecting..." 
                                      : (isDisconnecting 
                                          ? "Disconnecting..." 
                                          : "Disconnected")),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Server",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Default Server",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
