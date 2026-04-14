import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/di/di_container.dart';

class AutoLockSettingsScreen extends ConsumerStatefulWidget {
  const AutoLockSettingsScreen({super.key});

  @override
  ConsumerState<AutoLockSettingsScreen> createState() => _AutoLockSettingsScreenState();
}

class _AutoLockSettingsScreenState extends ConsumerState<AutoLockSettingsScreen> {
  double _autoLockSeconds = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load from app config or local storage
    setState(() {
      _autoLockSeconds = 30.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Auto-Lock'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            CupertinoIcons.timer,
            size: 64,
            color: AppTheme.systemOrange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Auto-Lock Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically lock the vault after a period of inactivity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lock after inactivity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_autoLockSeconds.toInt()}s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.systemOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _autoLockSeconds,
                    min: 10,
                    max: 300,
                    divisions: 29,
                    label: '${_autoLockSeconds.toInt()}s',
                    activeColor: AppTheme.systemOrange,
                    inactiveColor: Colors.grey.shade700,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _autoLockSeconds = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '10s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '5 min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickOption(15, '15 seconds'),
          _buildQuickOption(30, '30 seconds'),
          _buildQuickOption(60, '1 minute'),
          _buildQuickOption(300, '5 minutes'),
        ],
      ),
    );
  }

  Widget _buildQuickOption(int seconds, String label) {
    return Card(
      color: _autoLockSeconds == seconds ? AppTheme.systemOrange : Colors.grey.shade900,
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            color: _autoLockSeconds == seconds ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: _autoLockSeconds == seconds
            ? const Icon(CupertinoIcons.checkmark, color: Colors.black)
            : null,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _autoLockSeconds = seconds.toDouble();
          });
        },
      ),
    );
  }
}
