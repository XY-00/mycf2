import 'package:flutter/material.dart';

class AddPlantDialog extends StatelessWidget {
  final Function(String) onAdd;
  
  const AddPlantDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add New Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter Plant Name', 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 👑 控制文字内部高度
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () {
            if (nameController.text.trim().isNotEmpty) {
              onAdd(nameController.text.trim());
            }
            Navigator.pop(context);
          },
          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}