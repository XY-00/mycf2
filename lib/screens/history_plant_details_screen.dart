import 'dart:io';
import 'package:flutter/material.dart';

class HistoryPlantDetailsScreen extends StatefulWidget {
  final int slotIndex;
  final String initialName;
  final DateTime initialDate;
  final String initialAvatar;
  final DateTime? archivedDate;

  const HistoryPlantDetailsScreen({
    Key? key, 
    required this.slotIndex, 
    required this.initialName, 
    required this.initialDate, 
    required this.initialAvatar,
    this.archivedDate,
  }) : super(key: key);

  @override
  State<HistoryPlantDetailsScreen> createState() => _HistoryPlantDetailsScreenState();
}

class _HistoryPlantDetailsScreenState extends State<HistoryPlantDetailsScreen> {
  late String _currentName;
  late DateTime _currentDate;
  late String _currentAvatar;
  late DateTime _archivedDate;

  // 模拟该历史植物的真实快照记录（如果为空，则代表没有生长历史记录）
  // 后续你可以根据数据库字段进行动态传入，这里预留空的或真实的判定
  final List<Map<String, dynamic>> _growthSnapshots = []; 

  @override
  void initState() {
    super.initState();
    _currentName = widget.initialName;
    _currentDate = widget.initialDate;
    _currentAvatar = widget.initialAvatar;
    _archivedDate = widget.archivedDate ?? DateTime.now();
  }

  int get _calcDays => _archivedDate.difference(_currentDate).inDays;

  void _openGrowthHistoryGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7F5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Growth History',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: _growthSnapshots.isEmpty
                    ? const Center(
                        child: Text(
                          'No growth history yet',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        children: const [],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    const Color unifiedCardBg = Color(0xFFF0F5F1); 
    
    bool isLocalFile = _currentAvatar.startsWith('/') || _currentAvatar.startsWith('file://');
    bool fileExists = isLocalFile && File(_currentAvatar).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/app_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.white.withOpacity(0.78)), 
            Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: primaryDarkGreen, 
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              _currentName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Plant Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black12),
                                      image: fileExists
                                          ? DecorationImage(image: FileImage(File(_currentAvatar)), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: !fileExists
                                        ? Center(
                                            child: Text(
                                              isLocalFile ? '🌱' : _currentAvatar,
                                              style: const TextStyle(fontSize: 26),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Moisture: --%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Plant Name', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_currentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: primaryDarkGreen),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Age: $_calcDays Days', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                                            Text('Planted: ${_currentDate.day}/${_currentDate.month}/${_currentDate.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Soil Moisture Levels & Targets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _screenshotBox('Field Capacity', '75 %', 'moisture level maximum plant health and growth', Colors.green, const Color(0xFFD4EDDA), const Color(0xFF28A745))),
                                    const SizedBox(width: 5),
                                    Expanded(child: _screenshotBox('Carbon Safe Line', '59 %', 'irrigation on before reaching this point\n ', Colors.amber.shade800, const Color(0xFFFFF3CD), const Color(0xFF856404))),
                                    const SizedBox(width: 5),
                                    Expanded(child: _screenshotBox('Wilting Point', '45 %', 'plant cannot recover moisture\n ', Colors.red, const Color(0xFFF8D7DA), const Color(0xFF721C24))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Growth History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: _growthSnapshots.isEmpty
                              ? Column(
                                  children: const [
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(
                                          'No growth history yet',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () => _openGrowthHistoryGallery(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                                          child: const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenshotBox(String title, String percent, String desc, Color dotColor, Color boxBgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: boxBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: dotColor.withOpacity(0.5), width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 8, color: textColor, fontWeight: FontWeight.bold))),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            ],
          ), 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(child: Text(percent, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, height: 1.0))),
          ),
          Text(desc, style: TextStyle(fontSize: 7.5, color: textColor.withOpacity(0.85), height: 1.15), maxLines: 3, overflow: TextOverflow.visible),
        ],
      ),
    );
  }
}