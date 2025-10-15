import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  final pb = PocketBase(dotenv.env['POCKETBASE_URL']!);
  final email = dotenv.env['POCKETBASE_ADMIN_EMAIL']!;
  final password = dotenv.env['POCKETBASE_ADMIN_PASSWORD']!;
  final apiUrl = dotenv.env['FAKESTORE_API']!;

  try {
    await pb.admins.authWithPassword(email, password);
    print('Connected to PocketBase as admin');
  } catch (e) {
    print('Failed to authenticate admin: $e');
    return;
  }

  final res = await http.get(Uri.parse(apiUrl));
  if (res.statusCode != 200) {
    print('Failed to fetch products');
    return;
  }

  final List<dynamic> products = jsonDecode(res.body);
  print('Fetched ${products.length} products from FakeStoreAPI');

  for (final p in products) {
    try {
      final record = await pb.collection('products').create(body: {
        'title': p['title'],
        'price': p['price'],
        'description': p['description'],
        'category': p['category'],
        'image': p['image'],
      });
      print('Created: ${record.id} - ${p['title']}');
    } catch (e) {
      print('Error creating product ${p['title']}: $e');
    }
  }

  print('Finished seeding products into PocketBase');
}
