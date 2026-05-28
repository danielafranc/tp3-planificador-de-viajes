import 'dart:convert';
import 'package:http/http.dart' as http;

class DollarService {
  Future<double> getMepRate() async {
    try {
      final response = await http.get(
        Uri.parse('https://dolarapi.com/v1/dolares/bolsa'),
      );
      if (response.statusCode == 200) {

        print('Response body: ${response.body}');
        final data = jsonDecode(response.body);
        final rate = (data['venta'] as num).toDouble();
        print('MEP obtenido: $rate'); 
        return rate;
      }
    } catch (e) {
      print('Error al obtener MEP: $e');
      return 1444.0;
    }
    return 1444.0;
  }
}
