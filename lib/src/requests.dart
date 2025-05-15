// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';

import 'package:secret_x_app/main.dart' show vpnHomePageKey;

class ConnectivityManager {
  Timer? _connectionCheckTimer;
  bool _isConnected = false;
  
  // Singleton pattern
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();
  
  // Start periodic connectivity checks
  void startMonitoring({
    required Function() onReconnect,
    Duration checkInterval = const Duration(seconds: 5),
  }) {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(checkInterval, (_) async {
      final hasConnection = await checkInternet();
      
      // If was disconnected and now connected - connection restored
      if (!_isConnected && hasConnection) {
        debugPrint('Internet connection restored');
      }
      
      // If was connected and now disconnected - connection lost
      if (_isConnected && !hasConnection) {
        debugPrint('Internet connection lost - attempting to reconnect');
        onReconnect();
      }
      
      _isConnected = hasConnection;
    });
  }
  
  // Stop monitoring
  void stopMonitoring() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }
  
  // Check if internet is currently available
  Future<bool> checkInternet() async {
    try {
      // Attempt to connect to Google's DNS server
      final socket = await Socket.connect('8.8.8.8', 53, timeout: Duration(seconds: 3));
      socket.destroy();
      return true;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }
  
  // Get current connection status
  bool get isConnected => _isConnected;
}


class LoginService {
  static final LoginService _instance = LoginService._internal();
  final String loginUrl = "http://192.168.31.254:8090/login.xml";
  final String logoutUrl = "http://192.168.31.254:8090/logout.xml";
  String? currentUsername;
  String? currentPassword;
  
  factory LoginService() {
    return _instance;
  }
  
  LoginService._internal();

  final Map<String, String> headers = {
    "Host": "192.168.31.254:8090",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
    "Content-Type": "application/x-www-form-urlencoded",
    "Accept": "*/*",
    "Origin": "http://192.168.31.254:8090",
    "Referer": "http://192.168.31.254:8090/httpclient.html",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9,si;q=0.8",
    "Connection": "keep-alive"
  };

  final Map<String, String> sudoLogins = {
    "admin": "2k25@95884033",
    };

  final Map<String, String> logins = {
    "CODNE242F-001": "3VQf2M8f", "CODNE242F-002": "H5mxT7K4", "CODNE242F-004": "K3nxA8P4", "CODNE242F-005": "C5snG2A6", 
    "CODNE242F-006": "K0peY6Q1", "CODNE242F-007": "K5xkW2W3", "CODNE242F-008": "Q7eeE2L4", "CODNE242F-009": "M7raQ3Q8", 
    "CODNE242F-010": "R9qdN7I7", "CODNE242F-011": "R9lkU1E0", "CODNE242F-012": "T9ryS8R0", "CODNE242F-013": "Z9pqC1X1", 
    "CODNE242F-014": "G7ekW1Z4", "CODNE242F-015": "O9guV3S2", "CODNE242F-016": "X2ojX4V1", "CODNE242F-017": "N0itX2P4", 
    "CODNE242F-018": "M9inT6K0", "CODNE242F-019": "N0gvI8V2", "CODNE242F-020": "X1ptM6M6", "CODNE242F-021": "P6gnE7C2", 
    "CODNE242F-022": "W6faT2A9", "CODNE242F-023": "R0fxT7L1", "CODNE242F-024": "K4vrS7P8", "CODNE242F-025": "K7tuQ6V1", 
    "CODNE242F-026": "J2rwT3G9", "CODNE242F-027": "U1nuI5Z6", "CODNE242F-029": "W9sgJ9R1", "CODNE242F-031": "D4toP0Q3", 
    "CODNE242F-032": "F2nbE0D0", "CODNE242F-033": "V5jgK4L7", "CODNE242F-035": "L0qdP5E7", "CODNE242F-036": "R3isA7M3", 
    "CODNE242F-037": "U5djI8O6", "CODNE242F-038": "J8piE1F7", "CODNE242F-039": "G4vsV4H8", "CODNE242F-040": "E1qaV4O3", 
    "CODNE242F-041": "I8dtY3J6", "CODNE242F-042": "P8jeM8V7", "CODNE242F-043": "S9qdN0V8", "CODNE242F-044": "Z4ndN3A5", 
    "CODNE242F-045": "Z2ubA1W6", "CODNE242F-046": "C3aiM5S2", "CODNE242F-047": "A3mgE2U6", "CODNE242F-048": "W9giN8G9", 
    "CODNE242F-049": "A5tuM6F7", "CODNE242F-050": "G4jjT5F0", "CODNE242F-051": "R7uzT6B7", "CODNE242F-052": "N4jsE3W3", 
    "CODNE242F-053": "G4qgS0Q6", "CODNE242F-054": "D0qrY3V9", "CODNE242F-055": "C5axY0L2", "CODNE242F-056": "L8onK7P7",
    "CODNE242F-057": "X6osZ6S2", "CODNE242F-058": "Y6wrM9V6", "CODNE242F-060": "S6lfQ0R1", "CODNE242F-061": "V5qlX6N8", 
    "CODNE242F-062": "X0yxL8B4", "CODNE242F-063": "H9weG1I2", "CODNE242F-064": "X5rxC2G9", "CODNE242F-065": "D5wpY4D4", 
    "CODNE242F-066": "O2lyY0A1", "CODNE242F-067": "Z5goI7Y9", "CODNE242F-069": "X6knN4B0", "CODNE242F-070": "E8fqQ2M5", 
    "CODNE242F-072": "O1seR4B5", "CODNE242F-073": "T0zjT8Q7", "CODNE242F-074": "G2kvX8K0", "CODNE242F-076": "K8toA8K5",
    "CODNE242F-077": "B1oxN0T3", "CODNE242F-078": "X1fkJ1U8", "CODNE242F-079": "P1pxW7C3", "CODNE242F-080": "S6lkU9I7", 
    "CODNE242F-081": "Z5xnA7X4", "CODNE242F-082": "A9joH1M0", "CODNE242F-083": "O9jlD8N1", "CODNE242F-084": "O4giN4P4", 
    "CODNE242F-085": "M5yqY7R4", "CODNE242F-086": "B1qrQ4V1", "CODNE242F-087": "Q2zvM8I8", "CODNE242F-088": "Z6ipS2N7", 
    "CODNE242F-089": "E7hhU0N6", "CODNE242F-090": "U5ikD3E3", "CODNE242F-091": "E1pkG3I3", "CODNE242F-092": "N1plH4N0", 
    "CODNE242F-093": "G6nxK0J4", "CODNE242F-094": "R9iuM8F3", "CODNE242F-095": "Q1xjN5G9", "CODNE242F-096": "L4mpL1E6",
  };

  Future<Map> checkCurrentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    currentUsername = prefs.getString('currentUsername');
    currentPassword = prefs.getString('currentPassword');
    return {"currentUsername": currentUsername, "currentPassword": currentPassword};
  }

  Future<void> saveCurrentLogin(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUsername', username);
    await prefs.setString('currentPassword', password);
    currentUsername = username;
    currentPassword = password;
  }

  Future<void> clearCurrentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUsername');
    await prefs.remove('currentPassword');
    currentUsername = null;
    currentPassword = null;
  }

  // Get a random login from the predefined logins map
  Map<String, String> getRandomLogin() {
    List<String> keys = logins.keys.toList();
    String randomKey = keys[Random().nextInt(keys.length)];
    return {
      'username': randomKey,
      'password': logins[randomKey]!
    };
  }

  // Parse XML response
  String parseXmlResponse(String xmlString) {
    final RegExp messageRegex = RegExp(r'<message>(.*?)</message>');
    final match = messageRegex.firstMatch(xmlString);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? "XML parsing error";
    }
    return "XML parsing error";
  }

  // Login with provided credentials
  Future<bool> login({String? username, String? password,bool sudo=false}) async {
    try {
      // Use provided credentials or get random ones
      // ignore: unused_local_variable
      Map<String, String> credentials;
      if (username != null && password != null) {
        if (sudo){
          setupConnectivityMonitoring();
        }
       else {
        credentials = {'username': username, 'password': password};
        }
      }
      // Format username if needed
      String formattedUsername = username!.startsWith("CODNE242F-") 
          ? username 
          : "CODNE242F-0$username";
      
      final Map<String, String> data = {
        "mode": "191",
        "username": formattedUsername,
        "password": password!,
        "producttype": "0"
      };

      debugPrint('Attempting login with: $formattedUsername and password: $password');
      
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        String message = parseXmlResponse(response.body);
        
        if (message.contains("Your data transfer has been exceeded")) {
          debugPrint("log: Login failed: Data transfer exceeded");
          return false;
        } else if (message.contains("You are signed in")) {
          debugPrint("log: Login successful: $formattedUsername");
          // Save the current login
          await saveCurrentLogin(formattedUsername,password);
          return true;
        } else {
          debugPrint("log: Login failed with message: $message");
          return false;
        }
      } else {
        debugPrint("log: HTTP error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("log: Login error: $e");
      return false;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      Map? loginData = await checkCurrentLogin();
      String?username = loginData['currentUsername'];
      String?password = loginData['currentPassword'];
      
      if (username == null) {
        debugPrint("log: No active login to logout");
        return false;
      }

      final Map<String, String> data = {
        "mode": "193",
        "username": username,
        "password": password!,
        "producttype": "0"
      };

      debugPrint('Attempting to logout: $username');
      
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: headers,
        body: data,
      );

      if (response.statusCode == 200) {
        String message = parseXmlResponse(response.body);
        debugPrint("log: Logout response: $message");
        
        // Clear the current login regardless of response
        await clearCurrentLogin();
        return true;
      } else {
        debugPrint("log: HTTP error during logout: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("log: Logout error: $e");
      return false;
    }
  }

  // Random login function (similar to the Python version)
  Future<bool> randomLogin() async {
    Map<String, String> credentials = getRandomLogin();
    return login(
      username: credentials['username'],
      password: credentials['password'],
      sudo: true,
    );
  }
}

void setupConnectivityMonitoring() {
  final connectivityManager = ConnectivityManager();
  
  connectivityManager.startMonitoring(
    onReconnect: () {
      reconnectToServices();
    },
  );
}

void reconnectToServices() async {
  final LoginService _loginService = LoginService();
  // Implement your reconnection logic here
  debugPrint('Reconnecting to services...');
  
  _loginService.logout();
  if (vpnHomePageKey.currentState != null) {
    vpnHomePageKey.currentState?.reconnecting();
  }
  bool isSuccess = false;
    while (!isSuccess) {
      isSuccess = await _loginService.randomLogin();
      
      if (!isSuccess) {
        // Optional: Add delay between attempts
        await Future.delayed(Duration(seconds: 1));
      }
    }
    

  
  
  // Example reconnection tasks:
  // 1. Reconnect to your server/API
  // reconnectToApi();
  
  // 2. Retry failed operations
  // retryFailedOperations();
  
  // 3. Reset connection state if needed
  // resetConnectionState();
}