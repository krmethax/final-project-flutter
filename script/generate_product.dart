import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

Future<void> main() async {
  final pb = PocketBase('http://127.0.0.1:8090');

  // ✅ login ด้วย admin ก่อน
  try {
    await pb.admins.authWithPassword(
      'methasit.ka.65@ubu.ac.th', // ← เปลี่ยนเป็นของคุณ
      'Methasit66-99',           // ← เปลี่ยนเป็นของคุณ
    );
    print('✅ Connected to PocketBase as admin');
  } catch (e) {
    print('❌ Failed to authenticate admin: $e');
    return;
  }

  final res = await http.get(Uri.parse('https://fakestoreapi.com/products'));
  if (res.statusCode != 200) {
    print('❌ Failed to fetch products');
    return;
  }

  final List<dynamic> products = jsonDecode(res.body);
  print('Fetched ${products.length} products from FakeStoreAPI');

  // ✅ บันทึกลง PocketBase ทีละตัว
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

  print('🎉 Finished seeding products into PocketBase');
}
