import 'package:flutter/material.dart';

class PlantDetailsScreen extends StatefulWidget {
  final int slotIndex;
  final String initialName;
  final DateTime initialDate;
  final String initialAvatar;

  const PlantDetailsScreen({
    Key? key, 
    required this.slotIndex, 
    required this.initialName, 
    required this.initialDate, 
    required this.initialAvatar
  }) : super(key: key);

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late String _currentName;
  late DateTime _currentDate;
  late String _currentAvatar;

  @override
  void initState() {
    super.initState();
    _currentName = widget.initialName;
    _currentDate = widget.initialDate;
    _currentAvatar = widget.initialAvatar;
  }

  int get _calcDays => DateTime.now().difference(_currentDate).inDays;

  void _openEditBottomSheet() {
    final nameCtrl = TextEditingController(text: _currentName);
    String tempAvatar = _currentAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Plant Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Plant Name', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: tempAvatar,
                decoration: const InputDecoration(labelText: 'Change Avatar', border: OutlineInputBorder()),
                items: ['Sunflower 🌻', 'Cactus 🌵', 'Rose 🌹', 'Fern 🌿'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setPopupState(() => tempAvatar = val!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E)),
                onPressed: () {
                  setState(() {
                    _currentName = nameCtrl.text.trim();
                    _currentAvatar = tempAvatar;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text('$_currentName (Slot ${widget.slotIndex + 1})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context, {'action': 'update', 'name': _currentName, 'date': _currentDate, 'avatar': _currentAvatar}),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _openEditBottomSheet)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FBFA), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Hardware Binding:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('• Soil Moisture Sensor: Channel ${widget.slotIndex} (A${widget.slotIndex})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('• Water Relay Actuator: Pump ${widget.slotIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('Age: $_calcDays Days Old', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF9FBFA), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Physiological Moisture Benchmarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _box('Field Capacity', '75 %', Colors.green),
                      const SizedBox(width: 6),
                      _box('Carbon Safe Line', '59 %', Colors.orange),
                      const SizedBox(width: 6),
                      _box('Wilting Point', '45 %', Colors.red),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5CB85C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.flag_rounded, color: Colors.white),
                label: const Text('Finish & Harvest Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(context, {'action': 'harvest'});
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 16),
              label: const Text('Delete / Clear Wrong Input', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context, {'action': 'delete'});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(String t, String v, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
        child: Column(children: [Text(t, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c))]),
      ),
    );
  }
}