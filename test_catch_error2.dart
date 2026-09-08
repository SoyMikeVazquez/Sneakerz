import 'dart:async';

Future<List<Map<String, dynamic>>> fetch() async {
  return [{"hello": "world"}];
}

void main() async {
  try {
    final result = await fetch().catchError((_) => []);
    print("SUCCESS: " + result.toString());
  } catch (e) {
    print("ERROR CAUGHT: " + e.toString());
  }
}
