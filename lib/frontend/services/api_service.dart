import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/client_detail.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  dynamic _json(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

  Future<Map<String, dynamic>> fetchResumen() async {
    final res = await http.get(Uri.parse('$baseUrl/resumen'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} en resumen');
    }
    return _json(res) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchRiesgoPorTerritorio({int top = 8}) async {
    final res =
        await http.get(Uri.parse('$baseUrl/riesgo_por_territorio?top=$top'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} en territorio');
    }
    final List data = _json(res);
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Client>> fetchClientes({String orden = 'riesgo', int limit = 200}) async {
    final res =
        await http.get(Uri.parse('$baseUrl/clientes?orden=$orden&limit=$limit'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al cargar clientes');
    }
    final List data = _json(res);
    return data.map((j) => Client.fromJson(j)).toList();
  }

  Future<List<Client>> buscarPorNivel(String nivel, {int limit = 200}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/buscar?nivel=${nivel.toLowerCase()}&limit=$limit'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} en la búsqueda');
    }
    final List data = _json(res);
    return data.map((j) => Client.fromJson(j)).toList();
  }

  Future<ClientDetail> fetchDetalle(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/$id'));
    if (res.statusCode == 404) throw Exception('Cliente no encontrado');
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al cargar el detalle');
    }
    return ClientDetail.fromJson(_json(res));
  }

  Future<List<Map<String, dynamic>>> fetchRiesgoPorCoolers() async {
    final res = await http.get(Uri.parse('$baseUrl/riesgo_por_coolers'));
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} en coolers');
    }
    final List data = _json(res);
    return data.cast<Map<String, dynamic>>();
  }

  Future<String> preguntar(
    String pregunta, {
    String? clienteId,
    List<Map<String, String>>? historial,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/preguntar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pregunta': pregunta,
        if (clienteId != null) 'cliente': clienteId,
        if (historial != null) 'historial': historial,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} consultando la IA');
    }
    return (_json(res)['respuesta'] ?? '').toString();
  }
}