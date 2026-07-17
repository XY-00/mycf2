import 'package:flutter/material.dart';
import 'add_plant_screen.dart'; 
import 'plant_details_screen.dart'; 

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  // 动态增长的数组，用于存储已添加的活体植物，最大上限3个
  final List<Map<String, dynamic>> _activePlants = [];

  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

  void _showAddPlantDialog() {
    // 达到3个植物时，拦截操作不弹出对话框
    if (_activePlants.length >= 3) return;

    // 动态计算下一个植物的编号
    int nextPlantNumber = _activePlants.length + 1;

    showDialog(
      context: context,
      builder: (context) => AddPlantDialog(
        slotNumber: nextPlantNumber, 
        onAdd: (name, date, avatar) {
          setState(() {
            _activePlants.add({
              'name': name,
              'date': date,
              'avatar': avatar,
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      
      // 当活体植物达到3个的上限时，右下角的 FloatingActionButton 会自动隐藏
      floatingActionButton: _activePlants.length < 3
          ? FloatingActionButton(
              backgroundColor: primaryDarkGreen,
              onPressed: _showAddPlantDialog,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Panel
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
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 14.0, bottom: 16.0), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: const [
                    Text('Plant Profile', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ),
          ),
          
          // Content Base
          Expanded(
            child: _activePlants.isEmpty
                ? _buildEmptyPlaceholder() // 如果没有添加植物，渲染卡片包裹的空状态
                : _buildDynamicPlantList(softIvoryWhite, primaryDarkGreen), // 有植物时动态显示列表
          ),
        ],
      ),
    );
  }

  // 修正后的空状态组件：将 Maximum 提示完美融入到白色卡片内部
  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // 精致大圆角
            border: Border.all(color: Colors.black12), // 统一的黑12全App细边框
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 第一行：引导添加文本与图标并排居中
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tap the ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35)),
                  ),
                  Icon(
                    Icons.add_circle, // 实心圆形加号图标
                    color: Color(0xFF2C4A3E),
                    size: 26,
                  ),
                  Text(
                    ' to add a plant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第二行：直接内嵌在卡片底部的最大数量温馨提示
              const Text(
                '(Maximum 3 plants can be added)',
                style: TextStyle(
                  fontSize: 12, 
                  color: Colors.grey, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 动态植物列表页面渲染
  Widget _buildDynamicPlantList(Color softIvoryWhite, Color primaryDarkGreen) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
      itemCount: _activePlants.length,
      itemBuilder: (context, index) {
        final plant = _activePlants[index];
        final int daysOld = DateTime.now().difference(plant['date']).inDays;
        
        // 自动转换成符合 Analytic 页面格式的 "Plant 1: 名字" 格式
        String formattedTitle = 'Plant ${index + 1}: ${plant['name']}';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: softIvoryWhite, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.black12), // 保持全App统一的黑12浅色细腻边框
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantDetailsScreen(
                    slotIndex: index,
                    initialName: plant['name'],
                    initialDate: plant['date'],
                    initialAvatar: plant['avatar'],
                  ),
                ),
              );
              
              if (result != null) {
                setState(() {
                  if (result['action'] == 'delete' || result['action'] == 'harvest') {
                    _activePlants.removeAt(index);
                  } else if (result['action'] == 'update') {
                    _activePlants[index] = {
                      'name': result['name'],
                      'date': result['date'],
                      'avatar': result['avatar'],
                    };
                  }
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2E8), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Icon(_avatarMap[plant['avatar']] ?? Icons.eco, size: 32, color: primaryDarkGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        const SizedBox(height: 4),
                        Text('$daysOld Days Old', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}