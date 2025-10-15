import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class ProductEditPageWrapper extends StatelessWidget {
  const ProductEditPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final product = Get.arguments as Map<String, dynamic>;
    return ProductEditPage(product: product);
  }
}

class ProductEditPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductEditPage({super.key, required this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.product['title']);
    priceController =
        TextEditingController(text: widget.product['price'].toString());
  }

  Future<void> saveChanges() async {
    setState(() => isSaving = true);
    final id = widget.product['id'];
    final url = 'http://127.0.0.1:8090/api/collections/products/records/$id';
    final body = jsonEncode({
      'title': titleController.text,
      'price': double.tryParse(priceController.text) ?? 0,
    });
    final res = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    setState(() => isSaving = false);
    if (res.statusCode == 200) {
      Get.back(result: true);
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
        title: Text('แก้ไขสินค้า', style: GoogleFonts.prompt()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ราคา'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
