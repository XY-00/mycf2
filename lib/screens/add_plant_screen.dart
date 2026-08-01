import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8);
    
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += text[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddPlantScreen extends StatefulWidget {
  final int slotNumber;
  final Function(String, DateTime, String) onAdd;

  const AddPlantScreen({Key? key, required this.slotNumber, required this.onAdd}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  
  String? _dateErrorText;

  @override
  void initState() {
    super.initState();
    _dateController.text = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime fiftyYearsAgo = DateTime(now.year - 50, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: fiftyYearsAgo, 
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        _dateErrorText = null;
      });
    }
  }

  DateTime? _parseAndValidateDate(String text) {
    try {
      List<String> parts = text.split('/');
      if (parts.length != 3) return null;
      
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
        return null;
      }

      DateTime parsedDate = DateTime(year, month, day);
      
      if (parsedDate.year != year || parsedDate.month != month || parsedDate.day != day) {
        return null;
      }

      if (parsedDate.isAfter(DateTime.now())) {
        return null;
      }

      return parsedDate;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2C4A3E)),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            const Divider(color: Colors.black12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF2C4A3E)),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/app_background.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.78))),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: primaryDarkGreen,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Add Plant ${widget.slotNumber}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _showImageSourceBottomSheet,
                                  child: Container(
                                    width: 95,
                                    height: 95,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: primaryDarkGreen, width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                                      image: _selectedImageFile != null
                                          ? DecorationImage(image: FileImage(_selectedImageFile!), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: _selectedImageFile == null
                                        ? const Center(child: Text('🌱', style: TextStyle(fontSize: 42)))
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImageSourceBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: primaryDarkGreen),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                            child: Text('Plant Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                          ),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter plant name',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                            child: Text('Date (DD/MM/YYYY)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                          ),
                          TextField(
                            controller: _dateController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, DateInputFormatter()],
                            onChanged: (val) {
                              if (_dateErrorText != null) {
                                setState(() => _dateErrorText = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _dateErrorText, // 👈 仅显示 Invalid date
                              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_outlined, color: primaryDarkGreen), onPressed: _pickDate),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12), 
                                borderSide: BorderSide(color: _dateErrorText != null ? Colors.redAccent : primaryDarkGreen, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD96B27), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
                              onPressed: () async {
                                if (_nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter plant name')));
                                  return;
                                }

                                DateTime? validatedDate = _parseAndValidateDate(_dateController.text.trim());
                                if (validatedDate == null) {
                                  setState(() {
                                    _dateErrorText = 'Invalid date'; // 👈 修改为精简提示
                                  });
                                  return;
                                }

                                String avatarResult = '🌱';
                                if (_selectedImageFile != null) {
                                  final appDir = await getApplicationDocumentsDirectory();
                                  String fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}.png';
                                  final permanentImage = await _selectedImageFile!.copy('${appDir.path}/$fileName');
                                  avatarResult = permanentImage.path;
                                }

                                final user = Supabase.instance.client.auth.currentUser;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
                                  return;
                                }

                                widget.onAdd(
                                  _nameController.text.trim(), 
                                  validatedDate, 
                                  avatarResult
                                );
                                Navigator.pop(context);
                              },
                              child: const Text('ADD PLANT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}