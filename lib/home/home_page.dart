import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controller to control the 3D model (animations, camera, textures, etc.)
  final Flutter3DController controller = Flutter3DController();

  @override
  void initState() {
    super.initState();
    // Listen for when the model finishes loading.
    controller.onModelLoaded.addListener(() {
      if (controller.onModelLoaded.value) {
        // IMPORTANT: for large outdoor scenes, auto-framing often places the
        // camera inside the terrain/sky mesh. Set the camera explicitly
        // instead of trusting the default framing.
        //
        // setCameraOrbit(theta, phi, radius):
        //   theta  = horizontal angle in degrees (0 = facing you)
        //   phi    = vertical angle in degrees from top (90 = eye-level, <90 = looking down)
        //   radius = distance from target -- for a km-scale scene this needs
        //            to be MUCH larger than the package examples (which use
        //            small single-object models). Start big and dial down.
        controller.setCameraOrbit(0, 70, 800);
        controller.setCameraTarget(0, 0, 0);
      }
    });
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
            child: Flutter3DViewer(
              // Adds a gesture interceptor to stop pinch/rotate gestures
              // from misbehaving on iOS and some Android devices.
              activeGestureInterceptor: true,
              progressBarColor: Colors.deepPurple,
              enableTouch: true,
              controller: controller,
              src: 'assets/models/airplane.glb',
              // src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
              onProgress: (double progressValue) {},
              onLoad: (String modelAddress) {},
              onError: (String error) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                IconButton(
                  tooltip: 'Play animation',
                  onPressed: () => controller.playAnimation(),
                  icon: const Icon(Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Pause animation',
                  onPressed: () => controller.pauseAnimation(),
                  icon: const Icon(Icons.pause),
                ),
                IconButton(
                  tooltip: 'Reset animation',
                  onPressed: () => controller.resetAnimation(),
                  icon: const Icon(Icons.replay),
                ),
                IconButton(
                  tooltip: 'Start rotation',
                  onPressed: () => controller.startRotation(rotationSpeed: 30),
                  icon: const Icon(Icons.threed_rotation),
                ),
                IconButton(
                  tooltip: 'Stop rotation',
                  onPressed: () => controller.stopRotation(),
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
                IconButton(
                  tooltip: 'Zoom out (escape a bad default view)',
                  onPressed: () => controller.setCameraOrbit(0, 70, 1500),
                  icon: const Icon(Icons.zoom_out_map),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
