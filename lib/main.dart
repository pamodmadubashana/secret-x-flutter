import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

// import 'package:device_preview/device_preview.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// import 'basic.dart';
// import 'custom_plugin.dart';

// void main() {
//   runApp(
//     DevicePreview(
//       enabled: true,
//       tools: const [
//         ...DevicePreview.defaultTools
//       ],
//       builder: (context) => const MyApp(),
//     ),
//   );
// }


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

class _VpnHomePageState extends State<VpnHomePage> with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
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
  
  // Cached UI properties
  late final Size _screenSize;
  
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
      _screenSize = MediaQuery.of(context).size;
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
      isConnecting = true;
    });
    _updateColorAnimations();
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        _updateColorAnimations();
        _decelerateClouds();
      }
    });
  }
  
  void _showCredentialsDialog() {
    String tempUsername = username;
    String tempPassword = password;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(  // Added SingleChildScrollView here
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
                      child: const Text("OK"),
                      ),
                    ],
                  ),
                ],
              ),
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

  // Pre-build the animated circles for better performance
  List<Widget> _buildAnimatedCircles() {
    return List.generate(3, (index) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      // Change this line from false to true
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
          
          // Cloud Animations with RepaintBoundary
          RepaintBoundary(
            child: Stack(
              children: _buildCloudWidgets(screenSize),
            ),
          ),
          
          // Center Button
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Circles
                ..._buildAnimatedCircles(),
                
                // Connection Button with RepaintBoundary
                RepaintBoundary(
                  child: GestureDetector(
                    onTap: isConnecting ? null : (isConnected ? _disconnect : _connect),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? const Color.fromARGB(255, 17, 100, 20): const Color.fromARGB(255, 114, 19, 13),
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? const Color.fromARGB(255, 124, 179, 126) : const Color.fromARGB(255, 240, 130, 122)).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isConnecting
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
                                    size: 50,
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
              ],
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
          ),
          
          // Bottom Info Card with BlurFilter - Modified to handle keyboard
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: 10 + bottomPadding,  // Add bottomPadding here to adjust position
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
    );
  }
}
