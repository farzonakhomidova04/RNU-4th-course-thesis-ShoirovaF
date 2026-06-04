import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../core/theme/app_theme.dart';

class BorderGuideScreen extends StatelessWidget {
  const BorderGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.textPrimary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'border_guide'.tr(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.travel_explore, color: AppTheme.primaryColor, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Border Rules Card
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 700),
                        child: _buildInfoCard(
                          context,
                          icon: Icons.security,
                          iconColor: Colors.orange,
                          title: 'border_rules_title'.tr(),
                          description: 'border_rules_desc'.tr(),
                          details: _buildBorderDetails(context),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Transport Card
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 700),
                        child: _buildInfoCard(
                          context,
                          icon: Icons.directions_bus,
                          iconColor: AppTheme.primaryColor,
                          title: 'transport_title'.tr(),
                          description: 'transport_desc'.tr(),
                          details: _buildTransportDetails(context),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Emergency Card
                      FadeInUp(
                        delay: const Duration(milliseconds: 600),
                        duration: const Duration(milliseconds: 700),
                        child: _buildEmergencyCard(context),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Widget details,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.textPrimary.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Details
              details,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorderDetails(BuildContext context) {
    final lang = context.locale.languageCode;

    final documents = lang == 'ru'
        ? ['Загранпаспорт', 'ID-карта нового образца']
        : lang == 'en'
            ? ['International Passport', 'New type ID Card']
            : ['Xorijga chiqish pasporti (Zagran)', 'Yangi namunadagi ID karta'];

    final workingHours = lang == 'ru'
        ? '24 часа / 7 дней'
        : lang == 'en'
            ? '24 hours / 7 days'
            : '24 soat / 7 kun';

    final docLabel = lang == 'ru'
        ? 'Необходимые документы:'
        : lang == 'en'
            ? 'Required documents:'
            : 'Kerakli hujjatlar:';

    final hoursLabel = lang == 'ru'
        ? 'Режим работы:'
        : lang == 'en'
            ? 'Working hours:'
            : 'Ish vaqti:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          docLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...documents.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(doc, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hoursLabel,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workingHours,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransportDetails(BuildContext context) {
    final lang = context.locale.languageCode;

    final routes = lang == 'ru'
        ? [
            {'from': 'Фергана', 'time': '1-1.5 ч', 'type': 'Такси / Маршрутка'},
            {'from': 'Водиль', 'time': '30-40 мин', 'type': 'Такси / Дамас'},
          ]
        : lang == 'en'
            ? [
                {'from': 'Fergana', 'time': '1-1.5 h', 'type': 'Taxi / Minibus'},
                {'from': 'Vodil', 'time': '30-40 min', 'type': 'Taxi / Damas'},
              ]
            : [
                {'from': 'Farg\'ona', 'time': '1-1.5 soat', 'type': 'Taksi / Marshrutka'},
                {'from': 'Vodil', 'time': '30-40 daq', 'type': 'Taksi / Damas'},
              ];

    final fromLabel = lang == 'ru' ? 'Откуда' : lang == 'en' ? 'From' : 'Qayerdan';
    final typeLabel = lang == 'ru' ? 'Транспорт' : lang == 'en' ? 'Transport' : 'Transport';

    return Column(
      children: routes.map((route) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.textPrimary.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fromLabel: ${route['from']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$typeLabel: ${route['type']}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          route['time']!,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    final lang = context.locale.languageCode;

    final title = lang == 'ru'
        ? 'Экстренные службы'
        : lang == 'en'
            ? 'Emergency Services'
            : 'Favqulodda xizmatlar';

    final contacts = [
      {
        'icon': Icons.local_hospital,
        'color': Colors.red,
        'label': lang == 'ru' ? 'Скорая помощь' : lang == 'en' ? 'Ambulance' : 'Tez yordam',
        'number': '103',
      },
      {
        'icon': Icons.local_police,
        'color': Colors.blue,
        'label': lang == 'ru' ? 'Полиция' : lang == 'en' ? 'Police' : 'Politsiya',
        'number': '102',
      },
      {
        'icon': Icons.fire_extinguisher,
        'color': Colors.orange,
        'label': lang == 'ru' ? 'Пожарная' : lang == 'en' ? 'Fire Dept' : 'O\'t o\'chirish',
        'number': '101',
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sos, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...contacts.map((contact) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(contact['icon'] as IconData, color: contact['color'] as Color, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          contact['label'] as String,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: (contact['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          contact['number'] as String,
                          style: TextStyle(
                            color: contact['color'] as Color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
