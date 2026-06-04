import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../models/tourist_object.dart';
import '../services/sync_service.dart';
import '../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SyncService _syncService = SyncService();

  void _showAddDialog() {
    final uzNameCtrl = TextEditingController();
    final ruNameCtrl = TextEditingController();
    final enNameCtrl = TextEditingController();
    final uzDescCtrl = TextEditingController();
    final ruDescCtrl = TextEditingController();
    final enDescCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Tabiat');
    bool isRecommended = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FadeInUp(
              child: AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                title: const Text('Add Tourist Object', style: TextStyle(color: AppTheme.textPrimary)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(uzNameCtrl, 'Name (UZ)'),
                      const SizedBox(height: 10),
                      _buildTextField(ruNameCtrl, 'Name (RU)'),
                      const SizedBox(height: 10),
                      _buildTextField(enNameCtrl, 'Name (EN)'),
                      const SizedBox(height: 10),
                      _buildTextField(uzDescCtrl, 'Description (UZ)'),
                      const SizedBox(height: 10),
                      _buildTextField(ruDescCtrl, 'Description (RU)'),
                      const SizedBox(height: 10),
                      _buildTextField(enDescCtrl, 'Description (EN)'),
                      const SizedBox(height: 10),
                      _buildTextField(categoryCtrl, 'Category (e.g. Tabiat, Tarix)'),
                      const SizedBox(height: 10),
                      _buildTextField(latCtrl, 'Latitude', isNumber: true),
                      const SizedBox(height: 10),
                      _buildTextField(lngCtrl, 'Longitude', isNumber: true),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text('Recommend this place?', style: TextStyle(color: AppTheme.textPrimary)),
                        value: isRecommended,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => isRecommended = val),
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newObj = TouristObject(
                        id: const Uuid().v4(),
                        nameUz: uzNameCtrl.text,
                        nameRu: ruNameCtrl.text,
                        nameEn: enNameCtrl.text,
                        descriptionUz: uzDescCtrl.text,
                        descriptionRu: ruDescCtrl.text,
                        descriptionEn: enDescCtrl.text,
                        lat: double.tryParse(latCtrl.text) ?? 0.0,
                        lng: double.tryParse(lngCtrl.text) ?? 0.0,
                        category: categoryCtrl.text,
                        isRecommended: isRecommended,
                      );
                      await _syncService.addTouristObject(newObj);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        fillColor: AppTheme.textPrimary.withOpacity(0.05),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
    );
  }

  void _sendPushNotification() {
    // In a real app, this would hit a Cloud Function.
    // For prototype, we show a success message simulating the broadcast.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Push Notification sent to all users!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('admin_panel').tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Broadcast Notification',
            onPressed: _sendPushNotification,
          )
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: StreamBuilder<List<TouristObject>>(
            stream: _syncService.streamTouristObjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final objects = snapshot.data ?? [];
              if (objects.isEmpty) {
                return const Center(child: Text('No objects found. Add some!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: objects.length,
                itemBuilder: (context, index) {
                  final obj = objects[index];
                  return FadeInLeft(
                    delay: Duration(milliseconds: index * 100),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.textPrimary.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: obj.isRecommended ? Colors.amber.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(obj.isRecommended ? Icons.star : Icons.place, color: obj.isRecommended ? Colors.amber : AppTheme.primaryColor),
                        ),
                        title: Text(
                          '\${obj.nameUz} / \${obj.nameEn}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Lat: \${obj.lat}, Lng: \${obj.lng}\\nCat: \${obj.category}',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: AppTheme.backgroundColor),
      ),
    );
  }
}
