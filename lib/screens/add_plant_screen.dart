import 'package:flutter/material.dart';

class AddPlantDialog extends StatefulWidget {
  final int slotNumber;
  final Function(String, DateTime, String) onAdd;
  
  const AddPlantDialog({Key? key, required this.slotNumber, required this.onAdd}) : super(key: key);

  @override
  State<AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends State<AddPlantDialog> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now(); 
  String _selectedAvatar = 'Sunflower 🌻';

  final List<String> _avatarsList = ['Sunflower 🌻', 'Cactus 🌵', 'Rose 🌹', 'Fern 🌿'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Plant in Slot ${widget.slotNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: 'Enter Plant Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 14),
            
            // 👑 修正处：把 ListTheme 改为正确的 ListTileTheme 
            ListTileTheme(
              data: const ListTileThemeData(contentPadding: EdgeInsets.zero),
              child: ListTile(
                title: const Text('Planted Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year} (Tap to change)'),
                trailing: const Icon(Icons.calendar_month, color: Color(0xFF2C4A3E)),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context, 
                    initialDate: _selectedDate, 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime.now()
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedAvatar,
              decoration: const InputDecoration(labelText: 'Choose 2D Theme Avatar', border: OutlineInputBorder()),
              items: _avatarsList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedAvatar = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E)),
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onAdd(_nameController.text.trim(), _selectedDate, _selectedAvatar);
            }
            Navigator.pop(context);
          },
          child: const Text('Plant Now', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}