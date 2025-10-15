import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'product_edit_page.dart';
import 'product_new_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const url = 'http://127.0.0.1:8090/api/collections/products/records';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        products = data['items'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = 'http://127.0.0.1:8090/api/collections/products/records/$id';

    // ใส่ token ที่ได้จากตอน login หรือ admin login
    const token = 'YOUR_ADMIN_OR_USER_TOKEN';

    final res = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 204) {
      setState(() {
        products.removeWhere((p) => p['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสินค้าสำเร็จ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ (${res.statusCode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'สินค้าทั้งหมด',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Get.to(() => const ProductNewPage());
              if (created == true) {
                fetchProducts();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Image.network(
                p['image'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text(p['title'], style: GoogleFonts.prompt()),
              subtitle: Text('฿${p['price']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updated = await Get.to(
                            () => ProductEditPage(product: p),
                      );
                      if (updated == true) {
                        fetchProducts();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteProduct(p['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
