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

  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Plant Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E)),
                  onPressed: () {
                    setState(() {
                      _currentName = nameCtrl.text.trim();
                      _currentAvatar = tempAvatar;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openGrowthHistoryGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7F5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_currentName - Growth History', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 8, 
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        image: const DecorationImage(
                          image: AssetImage('assets/analytic_plant.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black54,
                        child: Text(
                          'Day ${index * 5 + 1} Snapshot',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
        content: Text('Are you sure you want to complete and archive "$_currentName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5CB85C)),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, {'action': 'harvest'}); 
            },
            child: const Text('Yes, Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('Are you sure you want to delete "$_currentName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, {'action': 'delete'}); 
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    const Color unifiedCardBg = Color(0xFFEAF2E8); 

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
                // 顶部标题栏
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
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10.0, bottom: 16.0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context, {'action': 'update', 'name': _currentName, 'date': _currentDate, 'avatar': _currentAvatar}),
                          ),
                          Text('$_currentName (Slot ${widget.slotIndex + 1})', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: _openEditBottomSheet,
                          ),
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
                        // 1. Plant Details 区域标题
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                            'Plant Details', 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)
                          ),
                        ),

                        // 2. 基础信息卡片（已移除 Plant Name 前面的图标）
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
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Icon(_avatarMap[_currentAvatar] ?? Icons.eco, size: 54, color: primaryDarkGreen),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Moisture: 62%',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Plant Name', style: TextStyle(fontSize: 11, fontStyle: FontStyle.normal, color: Colors.black54, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentName, 
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: primaryDarkGreen),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Age: $_calcDays Days Old', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
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

                        // 3. Soil Moisture Levels & Targets
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                            'Soil Moisture Levels & Targets', 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)
                          ),
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
                              const SizedBox(height: 12),
                              Column(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double totalWidth = constraints.maxWidth;
                                      double pos45 = totalWidth * 0.20;
                                      double pos59 = totalWidth * 0.50;
                                      double pos75 = totalWidth * 0.80;

                                      return Column(
                                        children: [
                                          Stack(
                                            alignment: Alignment.centerLeft,
                                            children: [
                                              Container(
                                                height: 12,
                                                width: totalWidth,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFF8D7DA), Color(0xFFFFD54F), Color(0xFFA3E4D7)],
                                                  ),
                                                  border: Border.all(color: Colors.black26, width: 0.8),
                                                ),
                                              ),
                                              Positioned(
                                                left: pos45 - 1.25,
                                                child: Container(width: 2.5, height: 16, color: const Color(0xFF856404)),
                                              ),
                                              Positioned(
                                                left: pos59 - 1.25,
                                                child: Container(width: 2.5, height: 16, color: Colors.red),
                                              ),
                                              Positioned(
                                                left: pos75 - 1.25,
                                                child: Container(width: 2.5, height: 16, color: Colors.green),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Stack(
                                            children: [
                                              const SizedBox(height: 16, width: double.infinity),
                                              Positioned(
                                                left: pos45 - 14,
                                                child: const Text('45%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                              ),
                                              Positioned(
                                                left: pos59 - 14,
                                                child: const Text('59%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                              ),
                                              Positioned(
                                                left: pos75 - 14,
                                                child: const Text('75%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Growth History
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Growth History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                            GestureDetector(
                              onTap: () => _openGrowthHistoryGallery(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _growthThumbnail('assets/analytic_plant.jpg')),
                              const SizedBox(width: 8),
                              Expanded(child: _growthThumbnail('assets/analytic_plant.jpg')),
                              const SizedBox(width: 8),
                              Expanded(child: _growthThumbnail('assets/analytic_plant.jpg')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 5. Complete 按钮
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5CB85C), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              onPressed: _confirmComplete,
                              child: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 6. Delete 按钮
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _confirmDelete,
                          ),
                        ),
                        const SizedBox(height: 20),
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
      decoration: BoxDecoration(
        color: boxBgColor, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: dotColor.withOpacity(0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title, 
                  maxLines: 1, 
                  overflow: TextOverflow.visible,
                  style: TextStyle(fontSize: 8, color: textColor, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 2),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            ],
          ), 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(
              child: Text(
                percent, 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, height: 1.0)
              ),
            ),
          ),
          Text(
            desc, 
            style: TextStyle(fontSize: 7.5, color: textColor.withOpacity(0.85), height: 1.15),
            maxLines: 3,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _growthThumbnail(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}