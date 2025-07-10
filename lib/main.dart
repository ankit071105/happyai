import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:weather/weather.dart';



void main() {
  runApp(const HappyAIApp());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class HappyAIApp extends StatelessWidget {
  const HappyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HappyAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (_, __, ___) => const GetStartedScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assistant, size: 100, color: Color(0xFF380B6A)),
              SizedBox(height: 20),
              Text(
                'HappyAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF380B6A),
                ),
              ),
              Text(
                'Your Voice Assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF380B6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  int _currentPermissionStep = 0;
  final List<Permission> _requiredPermissions = [
    Permission.microphone,
    Permission.contacts,
    Permission.location,
  ];
  bool _allPermissionsGranted = false;

  String get _currentPermissionName {
    switch (_currentPermissionStep) {
      case 0:
        return 'Microphone';
      case 1:
        return 'Contacts';
      case 2:
        return 'Location';
      default:
        return '';
    }
  }

  String get _currentPermissionDescription {
    switch (_currentPermissionStep) {
      case 0:
        return 'For voice commands';
      case 1:
        return 'To make calls and send messages';
      case 2:
        return 'For weather and navigation';
      default:
        return '';
    }
  }

  Future<void> _requestCurrentPermission() async {
    final status = await _requiredPermissions[_currentPermissionStep].request();

    if (status.isGranted) {
      if (_currentPermissionStep < _requiredPermissions.length - 1) {
        setState(() {
          _currentPermissionStep++;
        });
        await _requestCurrentPermission();
      } else {
        setState(() {
          _allPermissionsGranted = true;
        });
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainVoiceScreen()),
          );
        }
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: Text(
                '${_currentPermissionName} permission is required for this feature. '
                    'Please enable it in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      if (_currentPermissionStep < _requiredPermissions.length - 1) {
        setState(() {
          _currentPermissionStep++;
        });
        await _requestCurrentPermission();
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainVoiceScreen()),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCurrentPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.assistant_navigation, size: 120, color: Colors.deepPurple),
            const SizedBox(height: 30),
            Text(
              'HappyAI needs ${_currentPermissionName} permission',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _currentPermissionDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            PermissionRequestDialog(
              permissionName: _currentPermissionName,
              onAllow: _requestCurrentPermission,
              onDeny: () {
                if (_currentPermissionStep < _requiredPermissions.length - 1) {
                  setState(() {
                    _currentPermissionStep++;
                  });
                  _requestCurrentPermission();
                } else {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainVoiceScreen()),
                    );
                  }
                }
              },
            ),
            const Spacer(flex: 2),
            Text(
              'Step ${_currentPermissionStep + 1} of ${_requiredPermissions.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class PermissionRequestDialog extends StatelessWidget {
  final String permissionName;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const PermissionRequestDialog({
    super.key,
    required this.permissionName,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Allow HappyAI to access your $permissionName?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: onDeny,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Deny'),
            ),
            ElevatedButton(
              onPressed: onAllow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Allow'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'This permission is required for core features',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class MainVoiceScreen extends StatefulWidget {
  const MainVoiceScreen({super.key});

  @override
  State<MainVoiceScreen> createState() => _MainVoiceScreenState();
}



class _MainVoiceScreenState extends State<MainVoiceScreen> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _tts;
  bool _isListening = false;
  String _lastWords = '';
  String _responseText = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: 'AIzaSyA0dr_zXm5Bl-Vr1gizLi4tFBpekPpO3wA',
  );
  final WeatherFactory _weatherFactory = WeatherFactory("004d992c7e1a4aebd0c408ff6e800b05");
  int _currentIndex = 0;
  bool _contactsPermissionGranted = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _tts = FlutterTts();
    _initSpeech();
    _initTTS();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _contactsPermissionGranted = await Permission.contacts.isGranted;
    _locationPermissionGranted = await Permission.location.isGranted;
    if (mounted) setState(() {});
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _responseText = 'TTS Error: $msg');
      }
    });
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_isListening && !_isSpeaking) {
      final available = await _speechToText.initialize();
      if (available && mounted) {
        setState(() {
          _isListening = true;
          _responseText = '';
          _lastWords = '';
        });
        _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() => _lastWords = result.recognizedWords);
            }
            if (result.finalResult) {
              _processCommand(_lastWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          listenMode: stt.ListenMode.dictation,
          onDevice: true,
          cancelOnError: false,
          partialResults: false,
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _processCommand(String command) async {
    if (command.isEmpty) return;

    if (mounted) {
      setState(() => _isProcessing = true);
    }
    await _stopListening();

    try {
      // Handle compound commands first
      if (await _handleCompoundCommands(command)) {
        return;
      }

      // Then handle individual commands
      if (await _handleSpecialCommands(command)) {
        return;
      }

      // Fallback to Gemini for general queries
      final response = await _model.generateContent([Content.text(command)]);
      if (mounted) {
        setState(() => _responseText = response.text ?? 'Sorry, I didn\'t understand.');
      }
      await _tts.speak(_responseText);
    } catch (e) {
      if (mounted) {
        setState(() => _responseText = 'Error: Please try again.');
      }
      await _tts.speak(_responseText);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _handleCompoundCommands(String command) async {
    // Handle "open X and do Y" commands
    if (command.toLowerCase().contains('open') && command.toLowerCase().contains('and')) {
      final parts = command.split('and');
      if (parts.length >= 2) {
        final openCommand = parts[0].trim();
        final actionCommand = parts[1].trim();

        // Process the open command first
        if (await _handleAppLaunchCommand(openCommand)) {
          // Then process the action command after a short delay
          await Future.delayed(const Duration(seconds: 1));
          return await _processActionAfterOpen(actionCommand);
        }
      }
    }
    return false;
  }

  Future<bool> _processActionAfterOpen(String command) async {
    if (command.toLowerCase().contains('play')) {
      return _handlePlayCommand(command);
    }
    if (command.toLowerCase().contains('text') || command.toLowerCase().contains('message')) {
      return _handleMessageCommand(command);
    }
    return false;
  }

  Future<bool> _handleSpecialCommands(String command) async {
    final lowerCommand = command.toLowerCase();

    // Call commands
    if (lowerCommand.contains('call') || lowerCommand.contains('phone')) {
      return _handleCallCommand(command);
    }

    // Media playback
    if (lowerCommand.contains('play') &&
        (lowerCommand.contains('youtube') ||
            lowerCommand.contains('song') ||
            lowerCommand.contains('music'))) {
      return _handlePlayCommand(command);
    }

    // App launch
    if (lowerCommand.contains('open')) {
      return _handleAppLaunchCommand(command);
    }

    // Messaging
    if (lowerCommand.contains('text') || lowerCommand.contains('message')) {
      return _handleMessageCommand(command);
    }

    return false;
  }

  Future<bool> _handleCallCommand(String command) async {
    try {
      final contactName = command
          .replaceAll('call', '')
          .replaceAll('phone', '')
          .replaceAll('dial', '')
          .trim();

      if (contactName.isEmpty) {
        if (mounted) {
          setState(() => _responseText = 'Who would you like to call?');
        }
        await _tts.speak(_responseText);
        return true;
      }

      if (!_contactsPermissionGranted) {
        final status = await Permission.contacts.request();
        if (!status.isGranted) {
          if (mounted) {
            setState(() => _responseText = 'Contacts permission required to make calls');
          }
          await _tts.speak(_responseText);
          return true;
        }
        _contactsPermissionGranted = true;
      }

      // Get all contacts (not just query) to better handle name variations
      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
      );

      // Find best matching contact using fuzzy matching
      Contact? bestMatch;
      int bestScore = 0;

      for (final contact in contacts) {
        final displayName = contact.displayName ?? '';
        final givenName = contact.givenName ?? '';
        final familyName = contact.familyName ?? '';

        // Calculate match score
        int score = 0;

        // Check if contact name contains the spoken name
        if (displayName.toLowerCase().contains(contactName.toLowerCase())) {
          score += 10;
        }

        // Check if spoken name contains parts of contact name
        if (contactName.toLowerCase().contains(givenName.toLowerCase()) ||
            contactName.toLowerCase().contains(familyName.toLowerCase())) {
          score += 5;
        }

        // Check initials
        if (givenName.isNotEmpty && contactName[0].toLowerCase() == givenName[0].toLowerCase()) {
          score += 3;
        }

        // Update best match
        if (score > bestScore) {
          bestScore = score;
          bestMatch = contact;
        }
      }

      if (bestMatch == null || bestScore < 3) {
        if (mounted) {
          setState(() => _responseText = 'Contact "$contactName" not found');
        }
        await _tts.speak(_responseText);
        return true;
      }

      final phones = bestMatch.phones;

      if (phones == null || phones.isEmpty) {
        if (mounted) {
          setState(() => _responseText = 'No phone number found for ${bestMatch?.displayName}');
        }
        await _tts.speak(_responseText);
        return true;
      }

      // Use the first phone number
      final phone = phones.first.value?.replaceAll(RegExp(r'[^0-9+]'), '');

      if (phone == null || phone.isEmpty) {
        if (mounted) {
          setState(() => _responseText = 'Invalid phone number for ${bestMatch?.displayName}');
        }
        await _tts.speak(_responseText);
        return true;
      }

      if (mounted) {
        setState(() => _responseText = 'Calling ${bestMatch?.displayName}');
      }
      await _tts.speak(_responseText);

      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      }

      if (mounted) {
        setState(() => _responseText = 'Failed to make the call');
      }
      await _tts.speak(_responseText);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _responseText = 'Error making call: ${e.toString()}');
      }
      await _tts.speak(_responseText);
      return true;
    }
  }

  Future<bool> _handlePlayCommand(String command) async {
    try {
      // Extract just the song name, ignoring "happy" and "youtube"
      final songQuery = command
          .replaceAll(RegExp(r'(?:happy\s*)?(?:play\s*(?:a|the))?\s*(?:song|music)?\s*(?:on|in)?\s*youtube?\s*', caseSensitive: false), '')
          .trim();

      if (songQuery.isEmpty) {
        if (mounted) {
          setState(() => _responseText = 'What would you like me to play?');
        }
        await _tts.speak(_responseText);
        return true;
      }

      if (mounted) {
        setState(() => _responseText = 'Playing $songQuery on YouTube');
      }
      await _tts.speak(_responseText);

      // First try to open directly in YouTube app
      try {
        final intent = AndroidIntent(
          action: 'action_view',
          data: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(songQuery)}',
          package: 'com.google.android.youtube',
        );
        await intent.launch();
        return true;
      } catch (e) {
        // Fallback to browser
        final url = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(songQuery)}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return true;
        }
      }

      if (mounted) {
        setState(() => _responseText = 'Could not open YouTube');
      }
      await _tts.speak(_responseText);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _responseText = 'Error playing media: ${e.toString()}');
      }
      await _tts.speak(_responseText);
      return true;
    }
  }

  Future<bool> _handleAppLaunchCommand(String command) async {
    try {
      // Extract the app name, ignoring "happy" and "open"
      final appName = command
          .replaceAll(RegExp(r'(?:happy\s*)?open\s*'), '')
          .replaceAll('launch', '')
          .trim();

      if (appName.isEmpty) {
        if (mounted) {
          setState(() => _responseText = 'Which app would you like to open?');
        }
        await _tts.speak(_responseText);
        return true;
      }

      // More specific package mapping with better matching
      final packageMap = {
        'whatsapp': 'com.whatsapp',
        'instagram': 'com.instagram.android',
        'facebook': 'com.facebook.katana',
        'youtube': 'com.google.android.youtube',
        'maps': 'com.google.android.apps.maps',
        'google maps': 'com.google.android.apps.maps',
        'gmail': 'com.google.android.gm',
        'chrome': 'com.android.chrome',
        'google': 'com.android.chrome',
        'photos': 'com.google.android.apps.photos',
        'settings': 'com.android.settings',
        'play store': 'com.android.vending',
        'calculator': 'com.android.calculator2',
        'calendar': 'com.google.android.calendar',
        'camera': 'com.android.camera',
        'clock': 'com.android.deskclock',
        'contacts': 'com.android.contacts',
        'messages': 'com.android.mms',
        'message': 'com.android.mms', // For "open messages"
        'sms': 'com.android.mms',    // For "open sms"
        'phone': 'com.android.dialer',
      };

      // Find the best matching app using startsWith for better accuracy
      String? package;
      String? matchedApp;

      final lowerAppName = appName.toLowerCase();

      for (final entry in packageMap.entries) {
        if (lowerAppName.startsWith(entry.key)) {
          package = entry.value;
          matchedApp = entry.key;
          break;
        }
      }

      // If no direct match, try contains as fallback
      if (package == null) {
        for (final entry in packageMap.entries) {
          if (lowerAppName.contains(entry.key)) {
            package = entry.value;
            matchedApp = entry.key;
            break;
          }
        }
      }

      if (package == null) {
        if (mounted) {
          setState(() => _responseText = 'I don\'t know how to open $appName');
        }
        await _tts.speak(_responseText);
        return true;
      }

      if (mounted) {
        setState(() => _responseText = 'Opening ${matchedApp ?? appName}');
      }
      await _tts.speak(_responseText);

      try {
        final intent = AndroidIntent(
          action: 'action_view',
          package: package,
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return true;
      } catch (e) {
        if (mounted) {
          setState(() => _responseText = 'Failed to open ${matchedApp ?? appName}');
        }
        await _tts.speak(_responseText);
        return true;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _responseText = 'Error opening app: ${e.toString()}');
      }
      await _tts.speak(_responseText);
      return true;
    }
  }

  Future<bool> _handleMessageCommand(String command) async {
    try {
      // Handle "text [contact] [message]" format
      final regex = RegExp(r'(?:text|message)\s(.+?)\s(?:that|to say|message)?\s?(.+)', caseSensitive: false);
      final match = regex.firstMatch(command.toLowerCase());

      if (match != null) {
        final contactName = match.group(1)?.trim();
        final message = match.group(2)?.trim();

        if (contactName == null || contactName.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'Who would you like to message?');
          }
          await _tts.speak(_responseText);
          return true;
        }

        if (message == null || message.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'What would you like to say?');
          }
          await _tts.speak(_responseText);
          return true;
        }

        if (!_contactsPermissionGranted) {
          final status = await Permission.contacts.request();
          if (!status.isGranted) {
            if (mounted) {
              setState(() => _responseText = 'Contacts permission required to send messages');
            }
            await _tts.speak(_responseText);
            return true;
          }
          _contactsPermissionGranted = true;
        }

        // Get all contacts for better matching
        final contacts = await ContactsService.getContacts(
          withThumbnails: false,
        );

        // Find best matching contact
        Contact? bestMatch;
        int bestScore = 0;

        for (final contact in contacts) {
          final displayName = contact.displayName ?? '';
          final givenName = contact.givenName ?? '';
          final familyName = contact.familyName ?? '';

          // Calculate match score
          int score = 0;

          if (displayName.toLowerCase().contains(contactName.toLowerCase())) {
            score += 10;
          }

          if (contactName.toLowerCase().contains(givenName.toLowerCase()) ||
              contactName.toLowerCase().contains(familyName.toLowerCase())) {
            score += 5;
          }

          if (givenName.isNotEmpty && contactName[0].toLowerCase() == givenName[0].toLowerCase()) {
            score += 3;
          }

          if (score > bestScore) {
            bestScore = score;
            bestMatch = contact;
          }
        }

        if (bestMatch == null || bestScore < 3) {
          if (mounted) {
            setState(() => _responseText = 'Contact "$contactName" not found');
          }
          await _tts.speak(_responseText);
          return true;
        }

        final phones = bestMatch.phones;

        if (phones == null || phones.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'No phone number found for ${bestMatch?.displayName}');
          }
          await _tts.speak(_responseText);
          return true;
        }

        final phone = phones.first.value?.replaceAll(RegExp(r'[^0-9+]'), '');

        if (phone == null || phone.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'Invalid phone number for ${bestMatch?.displayName}');
          }
          await _tts.speak(_responseText);
          return true;
        }

        if (mounted) {
          setState(() => _responseText = 'Sending message to ${bestMatch?.displayName}');
        }
        await _tts.speak(_responseText);

        // Open default SMS app with the contact's number and message
        final url = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return true;
        }

        if (mounted) {
          setState(() => _responseText = 'Failed to send message');
        }
        await _tts.speak(_responseText);
        return true;
      }

      // Simple message format: "text John hello"
      final parts = command.split(' ');
      if (parts.length >= 3 && (parts[0].toLowerCase() == 'text' || parts[0].toLowerCase() == 'message')) {
        final contactName = parts[1];
        final message = parts.sublist(2).join(' ');

        if (!_contactsPermissionGranted) {
          final status = await Permission.contacts.request();
          if (!status.isGranted) {
            if (mounted) {
              setState(() => _responseText = 'Contacts permission required to send messages');
            }
            await _tts.speak(_responseText);
            return true;
          }
          _contactsPermissionGranted = true;
        }

        final contacts = await ContactsService.getContacts(
          withThumbnails: false,
        );

        Contact? bestMatch;
        int bestScore = 0;

        for (final contact in contacts) {
          final displayName = contact.displayName ?? '';
          final givenName = contact.givenName ?? '';
          final familyName = contact.familyName ?? '';

          int score = 0;

          if (displayName.toLowerCase().contains(contactName.toLowerCase())) {
            score += 10;
          }

          if (contactName.toLowerCase().contains(givenName.toLowerCase()) ||
              contactName.toLowerCase().contains(familyName.toLowerCase())) {
            score += 5;
          }

          if (givenName.isNotEmpty && contactName[0].toLowerCase() == givenName[0].toLowerCase()) {
            score += 3;
          }

          if (score > bestScore) {
            bestScore = score;
            bestMatch = contact;
          }
        }

        if (bestMatch == null || bestScore < 3) {
          if (mounted) {
            setState(() => _responseText = 'Contact "$contactName" not found');
          }
          await _tts.speak(_responseText);
          return true;
        }

        final phones = bestMatch.phones;

        if (phones == null || phones.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'No phone number found for ${bestMatch?.displayName}');
          }
          await _tts.speak(_responseText);
          return true;
        }

        final phone = phones.first.value?.replaceAll(RegExp(r'[^0-9+]'), '');

        if (phone == null || phone.isEmpty) {
          if (mounted) {
            setState(() => _responseText = 'Invalid phone number for ${bestMatch?.displayName}');
          }
          await _tts.speak(_responseText);
          return true;
        }

        if (mounted) {
          setState(() => _responseText = 'Sending message to ${bestMatch?.displayName}');
        }
        await _tts.speak(_responseText);

        final url = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return true;
        }

        if (mounted) {
          setState(() => _responseText = 'Failed to send message');
        }
        await _tts.speak(_responseText);
        return true;
      }

      if (mounted) {
        setState(() => _responseText = 'Please specify who to message and what to say');
      }
      await _tts.speak(_responseText);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _responseText = 'Error sending message: ${e.toString()}');
      }
      await _tts.speak(_responseText);
      return true;
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HappyAI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Available Commands'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCommandExample('Call [contact]', 'Call mom'),
                      _buildCommandExample('Play [song]', 'Play Despacito'),
                      _buildCommandExample('Open [app]', 'Open WhatsApp'),
                      _buildCommandExample('Text [contact] [message]', 'Text John "I\'m on my way"'),
                      _buildCommandExample('Open [app] and [action]', 'Open YouTube and play a song'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_responseText.isNotEmpty) ...[
                      _buildSpeechBubble(_responseText, false),
                      const SizedBox(height: 16),
                    ],
                    if (_lastWords.isNotEmpty) ...[
                      _buildSpeechBubble(_lastWords, true),
                      const SizedBox(height: 16),
                    ],
                    if (_isProcessing) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Processing...', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isListening ? 100 : 80,
                height: _isListening ? 100 : 80,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.green : Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? 'Listening...' : 'Tap to speak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isListening ? Colors.green : Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            if (_isSpeaking)
              const Text('Speaking...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Voice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.assistant, color: Colors.white),
            ),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 60 : 8,
                right: isUser ? 8 : 60,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF000000) : Color(0xFF000000),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : 'Happy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUser ? Color(0xFFC0ABEF): Color(0xFFA1EAEA),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Color(0xFFCACAFB)),
            ),
        ],
      ),
    );
  }

  Widget _buildCommandExample(String command, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            command,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'Example: "$example"',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}