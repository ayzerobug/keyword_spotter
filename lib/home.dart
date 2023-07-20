import 'dart:async';
import 'dart:developer';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:johnson_project/words.dart';
import 'package:livespeechtotext/livespeechtotext.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController controller;
  bool recording = false;
  bool microphoneGranted = false;
  String _recognisedText = "";
  String? lastDetected;
  late Livespeechtotext _livespeechtotextPlugin;
  StreamSubscription<dynamic>? onSuccessEvent;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat();

    _livespeechtotextPlugin = Livespeechtotext();
    binding();
  }

  @override
  void dispose() {
    onSuccessEvent?.cancel();
    super.dispose();
  }

  void startRecording() {
    print("start button pressed");
    try {
      _livespeechtotextPlugin.start();
      recording = true;
      setState(() {});
    } on PlatformException {
      print('error');
    }
  }

  void stopRecording() {
    try {
      _livespeechtotextPlugin.stop();
      recording = false;
      setState(() {});
    } on PlatformException {
      print('error');
    }
  }

  Future<void> _playSound(String soundAssetPath) async {
    AssetsAudioPlayer.newPlayer().open(Audio(soundAssetPath),
        showNotification: true, loopMode: LoopMode.none);
  }

  Future<dynamic> binding() async {
    onSuccessEvent?.cancel();

    return Future.wait([]).then((_) async {
      // Check if the user has already granted microphone permission.
      var permissionStatus = await Permission.microphone.status;

      // If the user has not granted permission, prompt them for it.
      if (!microphoneGranted) {
        await Permission.microphone.request();

        // Check if the user has already granted the permission.
        permissionStatus = await Permission.microphone.status;

        if (!permissionStatus.isGranted) {
          return Future.error('Microphone access denied');
        }
      }

      return Future.value(true);
    }).then((value) {
      microphoneGranted = true;

      // listen to event "success"
      onSuccessEvent =
          _livespeechtotextPlugin.addEventListener("success", (value) {
        if (value.runtimeType != String) return;
        if ((value as String).isEmpty) return;

        setState(() {
          _recognisedText = value;
          List<String> splittedValue = value.split(" ");
          for (var listedWord in terroristicWords) {
            for (var word in splittedValue) {
              if (listedWord.toLowerCase() == word.toLowerCase() &&
                  lastDetected != word) {
                lastDetected = word;
                // _playSound("assets/audio/danger.wav");
                print("Word detected: " + word + " and " + listedWord);
              }
            }
          }
        });
      });
    }).onError((error, stackTrace) {
      // toast
      log(error.toString());
      // open app setting
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 224, 224),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IntrinsicHeight(
              child: Column(
                children: [
                  Text(
                    "Keyword Spotter",
                    style:
                        Theme.of(context).textTheme.headlineMedium!.copyWith(),
                  ),
                  Text(
                    "Criminal Words",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(child: _buildBody()),
            Text(_recognisedText),
            if (lastDetected != null)
              FadeTransition(
                opacity: controller,
                child: Column(
                  children: [
                    const Text("Detected Word:"),
                    Text(lastDetected!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(color: Colors.red)),
                  ],
                ),
              ),
            Text(
              "By: Samuel Johnson",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontSize: 18),
            ),
            // const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation:
          CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn),
      builder: (context, child) {
        return RecordWidget(
          recording: recording,
          onTap: microphoneGranted
              ? recording
                  ? stopRecording
                  : startRecording
              : () {},
        );
      },
    );
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(31, 255, 128, 0),
      ),
    );
  }
}

class RecordWidget extends StatelessWidget {
  const RecordWidget({Key? key, required this.recording, required this.onTap})
      : super(key: key);

  final bool recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 200,
        width: 200,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFBEBEBE),
              offset: Offset(10, 10),
              blurRadius: 30,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-10, -10),
              blurRadius: 30,
              spreadRadius: 1,
            ),
          ],
        ),
        child: recording
            ? const Iconify(
                MaterialSymbols.stop,
                color: Color.fromARGB(255, 255, 128, 0),
              )
            : const Iconify(
                Ri.mic_line,
                color: Color.fromARGB(255, 255, 128, 0),
              ),
      ),
    );
  }
}
