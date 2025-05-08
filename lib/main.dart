import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
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
      home: const SplashScreen(), // Start with splash screen
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

// Add the Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late GifController controller;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the GIF controller
    controller = GifController(vsync: this);
    
    // Add a delay to show the splash screen for some time
    Timer(const Duration(milliseconds: 300), () {
      controller.repeat(
        min: 0,
        max: 100,
        period: const Duration(milliseconds: 1000),
      );
    });
    
    // Navigate to main screen after delay
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const VpnHomePage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 122, 100),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi, // Or use your custom icon
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Secret X",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Loading indicator
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter for cloud shapes and VpnHomePage classes remain the same
class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Cloud data class
class Cloud {
  late double x;
  late double y;
  late double size;
  late double baseSpeed;
  late double currentSpeed;
  late double opacity;
  
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

class _VpnHomePageState extends State<VpnHomePage> with TickerProviderStateMixin  {
  bool isConnected = false;
  bool isConnecting = false;
  bool hasCredentials = false;
  String username = "";
  String password = "";
  
  late AnimationController _animationController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColor1Animation;
  late Animation<Color?> _backgroundColor2Animation;
  late List<Cloud> clouds;
  final _random = math.Random();
  
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
  
    // Initialize color animations properly
    _backgroundColor1Animation = ColorTween(
      begin: _getStaticBackgroundColor1(),
      end: _getStaticBackgroundColor1(),
    ).animate(_colorAnimationController);
    
    _backgroundColor2Animation = ColorTween(
      begin: _getStaticBackgroundColor2(),
      end: _getStaticBackgroundColor2(),
    ).animate(_colorAnimationController);
    
    // Initialize clouds
    clouds = List.generate(15, (_) => _generateCloud());
    
    // Start cloud animation
    _loadCredentials();
    _startCloudAnimation();
  }

  void _updateColorAnimations() {
    // Create new animation with current color as begin and target color as end
    _backgroundColor1Animation = ColorTween(
      begin: _backgroundColor1Animation.value ?? _getStaticBackgroundColor1(),
      end: _getStaticBackgroundColor1(),
    ).animate(_colorAnimationController);
    
    _backgroundColor2Animation = ColorTween(
      begin: _backgroundColor2Animation.value ?? _getStaticBackgroundColor2(),
      end: _getStaticBackgroundColor2(),
    ).animate(_colorAnimationController);
    
    // Reset and run the animation
    _colorAnimationController.reset();
    _colorAnimationController.forward();
  }

  Color _getCurrentBackgroundColor1() {
    return _backgroundColor1Animation.value ?? _getStaticBackgroundColor1();
  }

  Color _getCurrentBackgroundColor2() {
    return _backgroundColor2Animation.value ?? _getStaticBackgroundColor2();
  }

  // Add this method to load saved credentials
  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "";
      password = prefs.getString('password') ?? "";
      hasCredentials = username.isNotEmpty && password.isNotEmpty;
    });
  }

  Future<void> _saveCredentials(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user);
    await prefs.setString('password', pass);
  }
  
  Cloud _generateCloud() {
    return Cloud(
      x: _random.nextDouble() * 2 - 0.5, // Start slightly off-screen
      y: _random.nextDouble(),
      size: _random.nextDouble() * 0.3 + 0.1, // Size between 0.1 and 0.4
      baseSpeed: _random.nextDouble()  * 0.001 + 0.0005, // Speed between 0.0005 and 0.0015
      opacity: _random.nextDouble() * 0.4 + 0.1, // Opacity between 0.1 and 0.5
    );
  }
  
  void _startCloudAnimation() {
    Future.delayed(const Duration(milliseconds: 16), () { // ~60fps
      if (mounted) {
        setState(() {
          for (var cloud in clouds) {
            // Move clouds horizontally with increased speed
            cloud.x += cloud.currentSpeed * 3; // Additional multiplier for extra speed
            
            // Reset cloud when it goes off-screen
            if (cloud.x > 1.5) {
              cloud.x = -0.5 - _random.nextDouble();
              cloud.y = _random.nextDouble() * 0.8;
            }
          }
        });
        _startCloudAnimation();
      }
    });
  }
  
  void _accelerateClouds() {
    setState(() {
      for (var cloud in clouds) {
        // Multiply base speed by a factor (e.g., 5x faster when connected)
        cloud.currentSpeed = cloud.baseSpeed * 5;
      }
    });
  }

  void _decelerateClouds() {
    setState(() {
      for (var cloud in clouds) {
        // Return to base speed
        cloud.currentSpeed = cloud.baseSpeed;
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!hasCredentials) {
      _showCredentialsDialog();
      return;
    }
    
    setState(() {
      isConnecting = true;
    });
    // Update colors immediately after state change
    _updateColorAnimations();
    
    // Simulate connection process
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isConnecting = false;
        isConnected = true;
      });
      // Update colors immediately after state change
      _updateColorAnimations();
      _accelerateClouds();
    });
  }
  
  void _disconnect() {
    setState(() {
      isConnecting = true;
    });
    // Update colors immediately after state change
    _updateColorAnimations();
    
    // Simulate disconnection process
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isConnecting = false;
        isConnected = false;
      });
      // Update colors immediately after state change
      _updateColorAnimations();
      _decelerateClouds();
    });
  }
  
  void _showCredentialsDialog() {
    String tempUsername = username;
    String tempPassword = password;
    
    showDialog(
      context: context,
      // Prevent dialog from being dismissed when tapping outside
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter Your Account Credentials",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: username),
                  onChanged: (value) {
                    tempUsername = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    tempPassword = value;
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
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                      if (tempUsername.isNotEmpty && tempPassword.isNotEmpty) {
                        await _saveCredentials(tempUsername, tempPassword);
                        setState(() {
                          username = tempUsername;
                          password = tempPassword;
                          hasCredentials = true;
                        });
                        Navigator.pop(context);
                          _connect();
                        }
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    setState(() {
      username = "";
      password = "";
      hasCredentials = false;
    });
  }
  
  Color _getStaticBackgroundColor1() {
    if (isConnected) {
      return Colors.green.shade300;
    } else if (isConnecting) {
      return const Color(0xFFFFA726); // Amber 400
    } else {
      return const Color.fromARGB(255, 246, 122, 100);
    }
  }

  Color _getStaticBackgroundColor2() {
    if (isConnected) {
      return Colors.lightGreen.shade500;
    } else if (isConnecting) {
      return const Color(0xFFFB8C00); // Orange 600
    } else {
      return const Color.fromARGB(255, 244, 39, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use resizeToAvoidBottomInset to prevent keyboard from causing layout shifts
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1 (Bottom): Animated Background
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
          
          // Cloud Animations
          ...clouds.map((cloud) {
              return Positioned(
                left: MediaQuery.of(context).size.width * cloud.x,
                top: MediaQuery.of(context).size.height * cloud.y,
                child: Opacity(
                  opacity: cloud.opacity,
                  child: Transform.scale(
                    scale: 1 + (cloud.size * 0.5), // Larger clouds appear closer
                    child: CustomPaint(
                      size: Size(
                        MediaQuery.of(context).size.width * cloud.size,
                        MediaQuery.of(context).size.width * cloud.size * 0.6,
                      ),
                      painter: CloudPainter(),
                    ),
                  ),
                ),
              );
            }).toList(),
                      
          // Layer 2: Connection Button
          Positioned.fill(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Circles
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final double size = 150.0 + (index * 40.0);
                        final double offset = index * 0.2;
                        final double value = ((_animationController.value + offset) % 1.0);
                        final double opacity = (1.0 - value) * 0.6;
                        
                        return Container(
                          width: size * value * 1.5,
                          height: size * value * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(255, 66, 65, 65).withOpacity(opacity),
                          ),
                        );
                      },
                    );
                  }),
                  
                  // Connection Button
                  GestureDetector(
                    onTap: isConnecting ? null : (isConnected ? _disconnect : _connect),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? const Color.fromARGB(255, 28, 68, 29): const Color.fromARGB(255, 88, 25, 20) ,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? const Color.fromARGB(255, 124, 179, 126):  const Color.fromARGB(255, 240, 130, 122)).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isConnecting
                            ? const CircularProgressIndicator(
                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                            )         
                            : Icon(
                                isConnected ? Icons.power_settings_new : Icons.power_settings_new,
                                size: 50,
                                color: isConnected ? const Color.fromARGB(255, 129, 127, 127) : const Color.fromARGB(255, 80, 82, 80),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Layer 3 (Top): App UI (Header and Connection Card)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                          isConnected ? "Connected" : (isConnecting ? "Connecting..." : "Disconnected"),
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
          
          // Connection Info Card at bottom
          Positioned(
          bottom: 20,
          left: 20,
          right: 20,
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
                          isConnected ? "Connected" : (isConnecting ? "Connecting..." : "Disconnected"),
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
                          "Server",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
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
        ],
      ),
    );
  }
}