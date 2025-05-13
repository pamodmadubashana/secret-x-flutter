import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  // Notification IDs
  static const int connectedNotificationId = 1001;
  
  // Notification channels
  static const String vpnStatusChannel = 'vpn_status';
  
  // Uptime tracking
  Timer? _uptimeTimer;
  Duration _uptime = Duration.zero;

  Function? _disconnectCallback;
  
  // Register disconnect callback
  void registerDisconnectCallback(Function callback) {
    _disconnectCallback = callback;
  }
  // Initialization
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, //'resource://drawable/app_icon', // Use your icon resource
      [
        NotificationChannel(
          channelKey: vpnStatusChannel,
          channelName: 'VPN Status',
          channelDescription: 'Notifications about VPN connection status',
          playSound: true,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultColor: Colors.green,
          ledColor: Colors.green,
          enableVibration: true,
          locked: true, // This makes the notification persistent by default
        )
      ],
      debug: true, // Set to false in production
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'vpn_status_group',
          channelGroupName: 'VPN Status'
        )
      ]
    );
    
    await initializeIsolateReceivePort();
    await startListeningNotificationEvents();
  }
  
  // Setup port for communication between isolates
  static ReceivePort? receivePort;
  Future<void> initializeIsolateReceivePort() async {
    // Cancel any existing port first
    IsolateNameServer.removePortNameMapping('vpn_notification_action_port');
    
    receivePort = ReceivePort('VPN notification action port')
      ..listen((data) => onActionReceived(data));

    IsolateNameServer.registerPortWithName(
      receivePort!.sendPort, 
      'vpn_notification_action_port'
    );
  }
  
  // Listen for notification actions
  Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod
    );
  }
  
  // These static methods are required for handling events in background/terminated state
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }
  
  // Handle notification actions
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // This gets called when a notification action is tapped
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('vpn_notification_action_port');
    
    if (sendPort != null) {
      // Send to main isolate
      sendPort.send(receivedAction);
    } else {
      debugPrint('Send port not found for vpn_notification_action_port');
      
      // Handle action directly if in background/terminated state
      if (receivedAction.channelKey == 'vpn_status' && 
          receivedAction.buttonKeyPressed == 'DISCONNECT') {
        // Implement any direct handling here if needed
        debugPrint('Disconnect pressed from notification in background');
      }
    }
  }
  
  // Handle actions in main isolate
  void onActionReceived(dynamic data) {
    if (data is ReceivedAction) {
      debugPrint('Notification action received in main isolate: ${data.buttonKeyPressed}');
      
      if (data.channelKey == vpnStatusChannel && 
          data.buttonKeyPressed == 'DISCONNECT') {
        // Call your VPN disconnect method here
        _disconnectCallback!();
        debugPrint('User requested VPN disconnect from notification');
      }
    }
  }
  
  // Request notification permissions
  Future<bool> requestPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  
  // Show the connected notification
  Future<void> showConnectedNotification({String? serverName}) async {
    // Reset uptime
    _uptime = Duration.zero;
    
    // Check permissions
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestPermission();
      if (!isAllowed) {
        debugPrint('Notification permission denied');
        return;
      }
    }
    
    final String serverText = serverName != null ? ' to $serverName' : '';
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: connectedNotificationId,
        channelKey: vpnStatusChannel,
        title: 'Secret X VPN',
        body: 'Connected$serverText - Uptime: ${_formatDuration(_uptime)}',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Service,
        locked: true, // Keep notification persistent
        criticalAlert: true, // For important notifications 
        autoDismissible: false, // User can't swipe away
        // playSound: true,
        showWhen: true, // Show the time
        payload: {'status': 'connected', 'server': serverName ?? 'unknown'}
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISCONNECT',
          label: 'Disconnect',
          color: Colors.redAccent,
          actionType: ActionType.Default, // This shows immediately
        ),
      ],
    );
    
    // Start uptime timer
    startUptimeTimer();
  }
  
  // Update notification with current uptime
  void updateUptimeNotification({String? serverName}) {
    final String serverText = serverName != null ? ' to $serverName' : '';
    
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: connectedNotificationId,
        channelKey: vpnStatusChannel,
        title: 'Secret X VPN',
        body: 'Connected$serverText - Uptime: ${_formatDuration(_uptime)}',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Service,
        locked: true,
        autoDismissible: false,
        showWhen: true,
        payload: {
          'status': 'connected', 
          'uptime': _uptime.inSeconds.toString(),
          'server': serverName ?? 'unknown'
        }
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISCONNECT',
          label: 'Disconnect',
          color: Colors.redAccent,
          actionType: ActionType.Default,
        ),
      ],
    );
  }
  
  // Show disconnected notification (optional)
  Future<void> showDisconnectedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: connectedNotificationId + 1, // Use a different ID
        channelKey: vpnStatusChannel,
        title: 'Secret X VPN',
        body: 'Disconnected - VPN session ended',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Service,
        autoDismissible: true, // Can be dismissed by user
        showWhen: true,
        payload: {'status': 'disconnected'}
      ),
    );
    
    // Stop the uptime timer since we're disconnected
    stopUptimeTimer();
  }
  
  // Remove the notification when disconnected
  Future<void> removeConnectedNotification() async {
    await AwesomeNotifications().cancel(connectedNotificationId);
    stopUptimeTimer();
  }
  
  // Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
  
  // Start the uptime timer
  void startUptimeTimer({String? serverName}) {
    // Cancel any existing timer
    stopUptimeTimer();
    
    // Create a new timer
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _uptime += const Duration(seconds: 1);
      updateUptimeNotification(serverName: serverName);
    });
  }
  
  // Stop the uptime timer
  void stopUptimeTimer() {
    _uptimeTimer?.cancel();
    // _uptimeTimer = null;
  }
  
  // Get current uptime
  Duration get uptime => _uptime;
  
  // Clean up resources
  void dispose() {
    stopUptimeTimer();
    IsolateNameServer.removePortNameMapping('vpn_notification_action_port');
    receivePort?.close();
  }
}
