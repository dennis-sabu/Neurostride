import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  static Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Check current status
      final connectStatus = await Permission.bluetoothConnect.status;
      final scanStatus = await Permission.bluetoothScan.status;
      final locationStatus = await Permission.location.status;

      if (connectStatus.isGranted &&
          scanStatus.isGranted &&
          locationStatus.isGranted) {
        return true;
      }

      // Request permissions in the exact order requested
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final allGranted =
          statuses[Permission.bluetoothConnect]?.isGranted == true &&
          statuses[Permission.bluetoothScan]?.isGranted == true &&
          statuses[Permission.location]?.isGranted == true;

      // Handle specific permission states if needed
      // (e.g. permanentlyDenied -> user can open app settings later)

      if (allGranted) {
        // Wait 500ms after permission granted before any Bluetooth action
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }
      return false;
    }

    // For iOS or other platforms assume true or handle separately
    return true;
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Bluetooth and Location permissions are required to connect to the smart shoes. Please enable them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
