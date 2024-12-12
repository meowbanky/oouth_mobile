import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/duty_location.dart';
import '../models/duty_shift.dart';
import '../models/duty_rota.dart';

class DutyService {
  final String baseUrl;
  final String token;

  DutyService({required this.baseUrl, required this.token});

  Future<List<DutyLocation>> getLocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/duty/duty_rota.php?action=list_locations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((json) => DutyLocation.fromJson(json))
            .toList();
      }
      throw Exception(data['message']);
    }
    throw Exception('Failed to load locations');
  }

  Future<List<DutyShift>> getShifts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/duty/duty_rota.php?action=list_shifts'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((json) => DutyShift.fromJson(json))
            .toList();
      }
      throw Exception(data['message']);
    }
    throw Exception('Failed to load shifts');
  }

  Future<List<DutyRota>> getDutyRota({
    String? staffId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'action': 'get_duties',
      if (staffId != null) 'staff_id': staffId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/duty/duty_rota.php')
          .replace(queryParameters: queryParams),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((json) => DutyRota.fromJson(json))
            .toList();
      }
      throw Exception(data['message']);
    }
    throw Exception('Failed to load duty rota');
  }

  Future<bool> assignDuty(
      int staffId, int shiftId, int locationId, String dutyDate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/duty/duty_rota.php?action=assign_duty'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'staff_id': staffId,
        'shift_id': shiftId,
        'location_id': locationId,
        'duty_date': dutyDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'];
    }
    throw Exception('Failed to assign duty');
  }

  Future<bool> updateDutyStatus(int dutyId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/duty/duty_rota.php?action=update_status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'duty_id': dutyId,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'];
    }
    throw Exception('Failed to update duty status');
  }

  Future<bool> deleteDuty(int dutyId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/duty/duty_rota.php?action=delete_duty'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'duty_id': dutyId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'];
    }
    throw Exception('Failed to delete duty');
  }
}
