import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/auth_provider.dart';
import '../services/duty_service.dart';
import '../models/duty_rota.dart';
import '../utils/app_theme.dart';

class DutyRotaScreen extends StatefulWidget {
  const DutyRotaScreen({super.key});

  @override
  _DutyRotaScreenState createState() => _DutyRotaScreenState();
}

class _DutyRotaScreenState extends State<DutyRotaScreen> {
  late DutyService _dutyService;
  late String _userId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DutyRota> _duties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _userId = authProvider.user?.id ?? '';
    _dutyService = DutyService(
      baseUrl: 'https://oouthsalary.com.ng/auth_api',
      token: authProvider.token ?? '',
    );
    _selectedDay = _focusedDay;
    _loadDuties();
  }

  Future<void> _loadDuties() async {
    setState(() => _isLoading = true);
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final duties = await _dutyService.getDutyRota(
        staffId: _userId,
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      setState(() => _duties = duties);
    } catch (e) {
      _showError('Error loading duties: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<DutyRota> _getDutiesForDay(DateTime day) {
    return _duties.where((duty) {
      final dutyDate = DateTime.parse(duty.dutyDate);
      return dutyDate.year == day.year &&
          dutyDate.month == day.month &&
          dutyDate.day == day.day;
    }).toList();
  }

  Future<void> _updateDutyStatus(int dutyId, String status) async {
    try {
      await _dutyService.updateDutyStatus(dutyId, status);
      await _loadDuties();
    } catch (e) {
      _showError('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Duty Roaster', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadDuties();
                  },
                  eventLoader: _getDutiesForDay,
                ),
                const Divider(),
                Expanded(
                  child: _buildDutyList(),
                ),
              ],
            ),
    );
  }

  Widget _buildDutyList() {
    final duties = _selectedDay != null ? _getDutiesForDay(_selectedDay!) : [];

    if (duties.isEmpty) {
      return const Center(
        child: Text('You are not on Duty Today.'),
      );
    }

    return ListView.builder(
      itemCount: duties.length,
      itemBuilder: (context, index) {
        final duty = duties[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(duty.shiftTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${duty.startTime} - ${duty.endTime}'),
                Text('Location: ${duty.locationName}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _updateDutyStatus(duty.id, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'completed',
                  child: Text('Mark Completed'),
                ),
                const PopupMenuItem(
                  value: 'absent',
                  child: Text('Mark Absent'),
                ),
              ],
              child: _buildStatusChip(duty.status),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'absent':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}
