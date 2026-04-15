import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cover/core/intruder/intruder_detection_service.dart';
import 'package:cover/core/media/secure_media_viewer.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/data/storage/secure_file_storage.dart';

/// Screen to view intruder detection logs
class IntruderLogsScreen extends ConsumerStatefulWidget {
  const IntruderLogsScreen({super.key});

  @override
  ConsumerState<IntruderLogsScreen> createState() => _IntruderLogsScreenState();
}

class _IntruderLogsScreenState extends ConsumerState<IntruderLogsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<IntruderLog> _logs = [];
  bool _isLoading = true;
  String? _selectedDateFilter;
  String? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadLogs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final intruderService = ref.read(intruderDetectionServiceProvider);
      final logs = await intruderService.getIntruderLogs();
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load intruder logs', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteLog(int logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this intruder log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        HapticFeedback.mediumImpact();
        final intruderService = ref.read(intruderDetectionServiceProvider);
        await intruderService.deleteIntruderLog(logId);
        await _loadLogs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log deleted')),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to delete intruder log', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete log: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all intruder logs? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        HapticFeedback.heavyImpact();
        final intruderService = ref.read(intruderDetectionServiceProvider);
        await intruderService.clearIntruderLogs();
        await _loadLogs();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All logs cleared')),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to clear intruder logs', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear logs: $e')),
          );
        }
      }
    }
  }

  List<IntruderLog> _getFilteredLogs() {
    var filtered = _logs;

    if (_selectedTypeFilter != null) {
      filtered = filtered.where((log) => log.eventType == _selectedTypeFilter).toList();
    }

    if (_selectedDateFilter != null) {
      final now = DateTime.now();
      DateTime? startDate;
      
      switch (_selectedDateFilter) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = null;
      }

      if (startDate != null) {
        filtered = filtered.where((log) => log.timestamp.isAfter(startDate)).toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Intruder Logs'),
        actions: [
          if (_logs.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllLogs();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All Logs'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            )
          : _logs.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFilterBar(),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredLogs().length,
                        itemBuilder: (context, index) {
                          final log = _getFilteredLogs()[index];
                          return _buildLogCard(log, index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.shield,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No Intruder Logs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone enters a wrong PIN multiple times,\ntheir photo and location will be captured here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'All Time',
              value: null,
              selected: _selectedDateFilter == null,
              onTap: () => setState(() => _selectedDateFilter = null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'Today',
              value: 'Today',
              selected: _selectedDateFilter == 'Today',
              onTap: () => setState(() => _selectedDateFilter = 'Today'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'This Week',
              value: 'This Week',
              selected: _selectedDateFilter == 'This Week',
              onTap: () => setState(() => _selectedDateFilter = 'This Week'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'This Month',
              value: 'This Month',
              selected: _selectedDateFilter == 'This Month',
              onTap: () => setState(() => _selectedDateFilter = 'This Month'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(IntruderLog log, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          NaCupattonoof(context).push(
            MaterialPageRoute(
              builder: (context) => IntruderLogDetailScreen(log: log),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(log.eventType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventTypeIcon(log.eventType),
                  color: _getEventTypeColor(log.eventType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEventTypeLabel(log.eventType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(log.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (log.encryptedPhotoPath != null)
                Icon(
                  CupertinoIcons.camera,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              const SizedBox(width: 8),
              if (log.encryptedLocation != null)
                Icon(
                  CupertinoIcons.location,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_forward,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return AppTheme.systemOrange;
      case 'screenshot':
        return Colors.purple;
      case 'compromise_report':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return CupertinoIcons.lock;
      case 'screenshot':
        return CupertinoIcons.photo;
      case 'compromise_report':
        return CupertinoIcons.exclamationmark_triangle;
      default:
        return CupertinoIcons.xmark_circle;
    }
  }

  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return 'Wrong PIN Attempt';
      case 'screenshot':
        return 'Screenshot Detected';
      case 'compromise_report':
        return 'Security Compromise';
      default:
        return 'Unknown Event';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Screen to view details of a single intruder log
class IntruderLogDetailScreen extends ConsumerStatefulWidget {
  final IntruderLog log;

  const IntruderLogDetailScreen({super.key, required this.log});

  @override
  ConsumerState<IntruderLogDetailScreen> createState() =>
      _IntruderLogDetailScreenState();
}

class _IntruderLogDetailScreenState
    extends ConsumerState<IntruderLogDetailScreen> {
  Uint8List? _photoData;
  bool _isLoadingPhoto = false;

  @override
  void initState() {
    super.initState();
    if (widget.log.encryptedPhotoPath != null) {
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    setState(() {
      _isLoadingPhoto = true;
    });

    try {
      final secureStorage = ref.read(secureFileStorageProvider);
      final data = await secureStorage.retrieveFile(widget.log.encryptedPhotoPath!);
      
      if (mounted) {
        setState(() {
          _photoData = data;
          _isLoadingPhoto = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load intruder photo', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Log Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventInfo(),
            const SizedBox(height: 24),
            if (widget.log.encryptedPhotoPath != null) _buildPhotoSection(),
            const SizedBox(height: 24),
            if (widget.log.encryptedLocation != null) _buildLocationSection(),
            const SizedBox(height: 24),
            if (widget.log.metadata != null) _buildMetadataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(widget.log.eventType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getEventTypeIcon(widget.log.eventType),
                  color: _getEventTypeColor(widget.log.eventType),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEventTypeLabel(widget.log.eventType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFullDate(widget.log.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.camera, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Captured Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPhoto)
            const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            )
          else if (_photoData != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _photoData!,
                fit: BoxFit.contain,
              ),
            )
          else
            const Text(
              'Failed to load photo',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.location, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Location Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Location was captured at the time of the event.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.info_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Additional Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.log.metadata ?? 'No additional information',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return AppTheme.systemOrange;
      case 'screenshot':
        return Colors.purple;
      case 'compromise_report':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return CupertinoIcons.lock;
      case 'screenshot':
        return CupertinoIcons.photo;
      case 'compromise_report':
        return CupertinoIcons.exclamationmark_triangle;
      default:
        return CupertinoIcons.xmark_circle;
    }
  }

  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'wrong_pin':
        return 'Wrong PIN Attempt';
      case 'screenshot':
        return 'Screenshot Detected';
      case 'compromise_report':
        return 'Security Compromise';
      default:
        return 'Unknown Event';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
