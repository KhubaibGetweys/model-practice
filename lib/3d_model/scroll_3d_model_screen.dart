// SCROLL-DRIVEN 3D MODEL — Flutter example
//
// Mimics the effect on rebdihvacservice.vercel.app: a 3D model that
// rotates / translates as the user scrolls the page.
//
// SETUP:
// 1. flutter create my_app
// 2. Add to pubspec.yaml:
//      dependencies:
//        flutter_cube: ^0.1.1
// 3. Put a .obj model (+ .mtl + textures) in assets/models/, e.g.
//      assets/models/ac_unit.obj
//    and register the folder in pubspec.yaml:
//      flutter:
//        assets:
//          - assets/models/
//    (Free/cheap AC-unit .obj models: Sketchfab, TurboSquid, CGTrader.
//     If you only have a .glb, convert to .obj+.mtl with Blender:
//     File > Import glTF, then File > Export Wavefront (.obj))
// 4. Replace the body of your app with Scroll3DModelPage below.
//
// HOW IT WORKS:
// - A ScrollController reports scroll pixel offset every frame.
// - We map that offset to rotationY (spin), a small rotationX (tilt),
//   and a vertical position offset (rise/fall) on the 3D object.
// - The 3D scene sits pinned in a Stack while normal scrollable content
//   flows underneath/around it — same visual trick the website uses
//   (fixed/sticky 3D canvas, scrolling text beside or over it).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class Scroll3DModelPage extends StatefulWidget {
  const Scroll3DModelPage({super.key});
  @override
  State<Scroll3DModelPage> createState() => _Scroll3DModelPageState();
}

class _Scroll3DModelPageState extends State<Scroll3DModelPage> {
  final ScrollController _scrollController = ScrollController();
  Object? _model;
  Scene? _scene;

  // Tune these to match how dramatic you want the movement to be.
  static const double _rotationSpeed =
      0.3; // degrees of spin per pixel scrolled
  static const double _tiltRange = 15.0; // max tilt in degrees
  static const double _riseRange = 40.0; // max vertical shift in logical px

  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
    _applyTransform();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _model = Object(
      fileName: 'assets/models/old_air_conditioner.glb',
      scale: Vector3(1.0, 1.0, 1.0),
      position: Vector3(0, 0, 0),
    );
    scene.world.add(_model!);
    scene.camera.position.z = 6;
    scene.update();
  }

  void _applyTransform() {
    if (_model == null || _scene == null) return;

    // Continuous spin tied to scroll — this is the "moving while
    // scrolling" feel from the reference site.
    final double spin = (_scrollOffset * _rotationSpeed) % 360;

    // Gentle back-and-forth tilt using a sine wave over scroll distance,
    // so it doesn't just tilt one direction forever.
    final double tilt = _tiltRange * (0.5 - 0.5 * _cos(_scrollOffset / 300));

    _model!.rotation.setValues(tilt, spin, 0);

    // Optional: let the model rise as you scroll down a hero section,
    // then hold — clamp so it stops moving after some scroll distance.
    final double clampedScroll = _scrollOffset.clamp(0, 600);
    final double rise = (clampedScroll / 600) * _riseRange;
    _model!.position.setValues(0, -rise / 100, 0);

    _model!.updateTransform();
    _scene!.update();
  }

  double _cos(double radians) {
    // tiny helper so we don't need dart:math import clutter above
    return math.cos(radians);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          // Pinned 3D canvas — stays fixed while page content scrolls.
          Positioned.fill(child: Cube(onSceneCreated: _onSceneCreated)),

          // Scrollable content on top; the model reacts as this scrolls.
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Center(
                    child: Text(
                      'Scroll down',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                    height: 300,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Section ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  childCount: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
