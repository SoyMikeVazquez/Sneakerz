import 'dart:async';

Future<List<Map<String, dynamic>>> fetch() async {
  throw Exception("Fail");
}

void main() async {
  try {
    final result = await fetch().catchError((_) => []);
    print("SUCCESS: \$result");
  } catch (e) {
    print("ERROR CAUGHT: \$e");
  }
}
