// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_field

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:secret_x_app/src/notification_service.dart';
import 'package:secret_x_app/src/requests.dart';

final GlobalKey<_VpnHomePageState> vpnHomePageKey = GlobalKey<_VpnHomePageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
      await NotificationService().initialize();
      runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(const MyApp(initializationFailed: true));
  }
}

class MyApp extends StatelessWidget {
  final bool initializationFailed;
  
  const MyApp({super.key, this.initializationFailed = false});

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
      home: initializationFailed 
          ? const InitializationErrorScreen() 
          : VpnHomePage.withGlobalKey(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}


class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                "Initialization Error",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "There was a problem starting the app. Please make sure notifications are enabled and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  // Restart the app
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                child: Text("Restart App"),
              ),
            ],
          ),
        ),
      ),
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
  const VpnHomePage({super.key}) : super();

  static VpnHomePage withGlobalKey() => VpnHomePage(key: vpnHomePageKey);

  @override
  _VpnHomePageState createState() => _VpnHomePageState();
}

class AnimatedCircles extends StatelessWidget {
  final AnimationController controller;
  
  const AnimatedCircles({super.key, required this.controller});
  
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
            final double opacity = (1.0 - value) * 0.2;
            
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
  bool isDisconnecting = false;
  bool hasCredentials = false;
  String username = "";
  String password = "";
  

  
  late AnimationController _animationController;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _backgroundColor1Animation;
  late Animation<Color?> _backgroundColor2Animation;
  

  final NotificationService _notificationService = NotificationService();
  final LoginService _loginService = LoginService();
  final Map<String, String> sudoLogins = {
    "admin": "2k25@95884033",
    };
  
  // Using fewer clouds and fewer repaints
  late List<Cloud> clouds;
  final _random = math.Random();
  Timer? _cloudAnimationTimer;
  
  // Track keyboard visibility
  // ignore: prefer_final_fields
  bool _isKeyboardVisible = false;
  // ignore: prefer_final_fields
  FocusNode _dialogFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();

    _notificationService.requestPermission();
    _notificationService.registerDisconnectCallback(_disconnect);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _checkNotificationPermissions();
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
  
  Future<void> _checkNotificationPermissions() async {
    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Show a dialog to ask user for permission
      if (mounted) {
        _notificationService.requestPermission();
      }
    }
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
    // _notificationService.dispose();
    _animationController.dispose();
    _colorAnimationController.dispose();
    _cloudAnimationTimer?.cancel();
    _dialogFocusNode.dispose();
    _notificationService.registerDisconnectCallback(_pass);
    super.dispose();
  }

  void _pass() {
    debugPrint('pass');
  }

  void _connect() async  {
    List<String> keys = sudoLogins.keys.toList();
    if (!hasCredentials) {
      _showCredentialsDialog();
      return;
    }

    setState(() {
      isConnecting = true;
      isDisconnecting = false;
    });
    _updateColorAnimations();

    bool loginResult = false;
    if (username!= "" && password != "") {
      if (keys.contains(username)) {
        debugPrint('sudo login');
        loginResult = await _loginService.randomLogin();
      }else{
      loginResult = await _loginService.login(username: username, password: password);
      }
    }

    if (loginResult) {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = true;
        });
        _updateColorAnimations();
        _accelerateClouds();
        await _notificationService.showConnectedNotification(serverName: 'default server');
      }
    }
    else{
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        _updateColorAnimations();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void reconnecting() {
    if (!mounted) return;
    setState(() {
      isConnecting = true;
      isConnected = false;
      isDisconnecting = false;
    });
    _updateColorAnimations();

  }
  
  void _disconnect()async {
    setState(() {
      isDisconnecting = true;
      isConnecting = false;
      isConnected = false; // Set this to false immediately to trigger background color change
    });
    _updateColorAnimations(); // Update animations to apply color change

    
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        setState(() {
          isDisconnecting = false;
        });
        _updateColorAnimations(); // Update animations again
        _decelerateClouds();
        await _notificationService.removeConnectedNotification();
        await _notificationService.showDisconnectedNotification();
      }
    });
  }



  void _showCredentialsDialog() {
    String tempUsername = username;
    String tempPassword = password;
    bool passwordVisible = false; // Add this variable to control password visibility
    
    // Define a theme color variable for easy editing
    Color themeColor = const Color.fromARGB(255, 176, 177, 179); // You can change this to any color you want
    Color inputTextColor = const Color.fromARGB(255, 159, 161, 161);
    
    // Create controllers for the text fields
    final TextEditingController usernameController = TextEditingController(text: username);
    final TextEditingController passwordController = TextEditingController(text: password);
    
    // Use FocusScope to handle keyboard properly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Get the available screen height
        // final double screenHeight = MediaQuery.of(context).size.height;
        // final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
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
                        color: const Color.fromARGB(255, 209, 79, 79).withOpacity(0.5), // Reduced opacity for the base color
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Please Log In",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                            
                                  color: themeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  labelStyle: TextStyle(color: const Color.fromARGB(221, 255, 255, 255), fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.person, color: themeColor),
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
                                    borderSide: BorderSide(color: themeColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: inputTextColor, // Set the color of typed text
                                  fontWeight: FontWeight.w500, // Optional: make text slightly bolder
                                ),
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
                                  labelStyle: TextStyle(color: const Color.fromARGB(221, 255, 255, 255), fontWeight: FontWeight.w500),
                                  prefixIcon: Icon(Icons.lock, color: themeColor),
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
                                    borderSide: BorderSide(color: themeColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: inputTextColor, // Set the color of typed text
                                  fontWeight: FontWeight.w500, // Optional: make text slightly bolder
                                ),
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
                                      // ignore: use_build_context_synchronously
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
                                      foregroundColor: themeColor,
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
                                          // ignore: use_build_context_synchronously
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
                                      backgroundColor: themeColor,
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

  // ignore: unused_element
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
            if (!keyboardVisible)
                      Positioned.fill(
                        child: IgnorePointer( // Make sure circles don't interfere with button taps
                          child: AnimatedCircles(controller: _animationController),
                        ),
                      ),
            // Center Button - Adjusted position when keyboard is visible

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: (screenSize.height - 130) * 0.5,
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
                            color: isConnecting || isDisconnecting? const Color.fromARGB(255, 207, 163, 16) 
                            :(isConnected 
                                ? const Color.fromARGB(255, 17, 100, 20) 
                                : const Color.fromARGB(255, 114, 19, 13)), 

                            boxShadow: [
                              BoxShadow(
                                // Also update the shadow color for disconnecting state
                                color: (isConnecting || isDisconnecting ? const Color.fromARGB(255, 245, 215, 66) 
                                        : (isConnected 
                                            ? const Color.fromARGB(255, 124, 179, 126)  // Green glow
                                            : const Color.fromARGB(255, 240, 130, 122))  // Red glow
                                        ).withOpacity(0.3),
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
                        top: MediaQuery.of(context).padding.top + 10,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Secret X",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,

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
              // bottom: keyboardVisible 
              //    ? safeBottomPadding - 200
              //    : safeBottomPadding + 20,

              bottom: safeBottomPadding + 20,
              // bottom: 20,
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
                                "ID",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "None",
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
