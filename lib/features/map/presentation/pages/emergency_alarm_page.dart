import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class EmergencyAlarmPage extends StatefulWidget {
  final String reportId;
  const EmergencyAlarmPage({super.key, required this.reportId});

  @override
  State<EmergencyAlarmPage> createState() => _EmergencyAlarmPageState();
}

class _EmergencyAlarmPageState extends State<EmergencyAlarmPage> {
  @override
  void initState() {
    super.initState();
    _playLoudSiren();
  }

  void _playLoudSiren() {
    FlutterRingtonePlayer().playAlarm(
      looping: true,
      asAlarm: true,
      volume: 1.0,
    );
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 120, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'BAHAYA BANJIR!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Anda berada dalam radius kurang dari 50 meter dari lokasi banjir aktif. Segera menjauh dan cari rute yang lebih aman!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton.icon(
                onPressed: () {
                  FlutterLocalNotificationsPlugin().cancel(widget.reportId.hashCode + 100);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 10,
                ),
                icon: const Icon(LucideIcons.power, size: 32),
                label: const Text(
                  'TUTUP PERINGATAN',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
