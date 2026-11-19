import '../core/api_client.dart';
import '../models/json_model.dart';

class AdminDashboardService {
  const AdminDashboardService(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> resumen() async {
    return jsonObject(await api.json('GET', '/panel/resumen'));
  }
}
