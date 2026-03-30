
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ARDemo());
}

class ARDemo extends StatelessWidget {
  const ARDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ARHomePage(),
    );
  }
}

class ARHomePage extends StatefulWidget {
  const ARHomePage({super.key});

  @override
  State<ARHomePage> createState() => _ARHomePageState();
}

class _ARHomePageState extends State<ARHomePage> {
  // ── AR managers ──────────────────────────────────────────────────
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  // ── UI state ─────────────────────────────────────────────────────
  bool _arStarted = false;
  bool _nodeAdded = false;
  bool _isPlacing = false;
  String? _statusMessage;

  // ── Placed objects ───────────────────────────────────────────────
  ARNode? _placedNode;
  ARAnchor? _placedAnchor;

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // AR initialisation
  // ─────────────────────────────────────────────────────────────────

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;
    _arAnchorManager = anchorManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: false,
      handleRotation: false,
    );

    _arObjectManager!.onInitialize();

    _arSessionManager!.onError = (error) {
      if (mounted) {
        setState(() => _statusMessage = 'AR error: $error');
      }
    };

    setState(() => _statusMessage = 'Move your camera over a flat surface.');
  }

  // ─────────────────────────────────────────────────────────────────
  // Place model
  // ─────────────────────────────────────────────────────────────────

  Future<void> _placeModel() async {
    if (_arObjectManager == null || _arAnchorManager == null) {
      setState(() => _statusMessage = 'AR session not ready — please wait.');
      return;
    }
    if (_nodeAdded) {
      setState(() => _statusMessage = 'Model already placed. Remove it first.');
      return;
    }
    if (_isPlacing) return;

    setState(() {
      _isPlacing = true;
      _statusMessage = 'Placing model…';
    });

    try {
      // Create a plane anchor 1 m in front of the world origin.
      final anchor = ARPlaneAnchor(
        transformation: Matrix4.translation(Vector3(0, 0, -1)),
      );
      final anchorAdded = await _arAnchorManager!.addAnchor(anchor);
      if (anchorAdded == true) {
        _placedAnchor = anchor;
      }

      // Create the node using the local GLB asset.
      final node = ARNode(
        type: NodeType.localGLTF2,
        uri: 'assets/glbs/Fox.glb',
        scale: Vector3(0.01, 0.01, 0.01),
        position: Vector3(0, 0, -1),
        rotation: Vector4(1, 0, 0, 0),
      );

      final nodeAdded = await _arObjectManager!.addNode(
        node,
        planeAnchor: _placedAnchor as ARPlaneAnchor?,
      );

      if (nodeAdded != true) {
        // Clean up the anchor if the node couldn't be added.
        if (_placedAnchor != null) {
          await _arAnchorManager!.removeAnchor(_placedAnchor!);
          _placedAnchor = null;
        }
        setState(() {
          _statusMessage = 'Failed to add 3D model.';
          _isPlacing = false;
        });
        return;
      }

      _placedNode = node;
      setState(() {
        _nodeAdded = true;
        _isPlacing = false;
        _statusMessage = 'Fox placed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error placing model: $e';
        _isPlacing = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Remove model
  // ─────────────────────────────────────────────────────────────────

  Future<void> _removeModel() async {
    if (_arObjectManager == null || _arAnchorManager == null) return;
    if (!_nodeAdded) return;

    try {
      if (_placedNode != null) {
        await _arObjectManager!.removeNode(_placedNode!);
        _placedNode = null;
      }
      if (_placedAnchor != null) {
        await _arAnchorManager!.removeAnchor(_placedAnchor!);
        _placedAnchor = null;
      }
      setState(() {
        _nodeAdded = false;
        _statusMessage = 'Model removed.';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error removing model: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Start AR
  // ─────────────────────────────────────────────────────────────────

  void _startAR() {
    setState(() {
      _arStarted = true;
      _statusMessage = 'Initialising AR…';
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _arStarted ? _buildARView() : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 24),
          const Text(
            'AR Fox Demo',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Point your camera at a flat surface, then tap "Place Fox" '
              'to see the 3D model in augmented reality.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startAR,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start AR'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_statusMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: (_nodeAdded || _isPlacing) ? null : _placeModel,
                    icon: const Icon(Icons.add),
                    label: const Text('Place Fox'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _nodeAdded ? _removeModel : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
