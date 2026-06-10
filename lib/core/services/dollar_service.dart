import 'dart:convert';
import 'package:http/http.dart' as http;

class DollarService {
  Future<double> getMepRate() async {
    try {
      final response = await http.get(
        Uri.parse('https://dolarapi.com/v1/dolares/bolsa'),
      );
      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        final rate = (data['venta'] as num).toDouble();
        return rate;
      }
    } catch (e) {
      return 1444.0;
    }
    return 1444.0;
  }
}
