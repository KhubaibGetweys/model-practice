import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key, required this.title});
  final String title;

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  final O3DController controller = O3DController();

  @override
  void initState() {
    super.initState();
    // o3d doesn't expose an onModelLoaded listener like flutter_3d_controller.
    // Instead, it gives you a `logger` callback that reports internal events
    // (including load progress/errors) as raw strings.
    controller.logger = (data) {
      log('o3d log: $data');
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: O3D.asset(
              src: 'assets/models/racing.glb',
              controller: controller,
              // --- Common configuration options ---
              ar: false, // set true to allow launching the system AR viewer
              autoRotate: false, // auto-spin the model when idle
              autoPlay: true, // auto-play the first animation on load
              cameraControls: true, // let the user drag/pinch to orbit & zoom
              disableZoom: false, // set true to lock zoom level
              backgroundColor: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Play animation',
                  onPressed: () => controller.play(),
                  icon: const Icon(Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Pause animation',
                  onPressed: () => controller.pause(),
                  icon: const Icon(Icons.pause),
                ),
                IconButton(
                  tooltip: 'List available animations',
                  onPressed: () async {
                    final animations = await controller.availableAnimations();
                    log('Available animations: $animations');
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                ),
                IconButton(
                  tooltip: 'Set camera orbit (angle down, zoomed out)',
                  // (theta)deg, (phi)deg, (radius)m
                  // theta  = horizontal angle
                  // phi    = vertical angle from top (90 = eye-level)
                  // radius = distance from target -- push this WAY up for
                  //          large scenes like a race track (start big,
                  //          dial down; small models use ~1-5, big outdoor
                  //          scenes may need hundreds+)
                  onPressed: () => controller.cameraOrbit(20, 70, 800),
                  icon: const Icon(Icons.threed_rotation),
                ),
                IconButton(
                  tooltip: 'Set camera target (recenter)',
                  onPressed: () => controller.cameraTarget(0, 0, 0),
                  icon: const Icon(Icons.center_focus_strong),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
