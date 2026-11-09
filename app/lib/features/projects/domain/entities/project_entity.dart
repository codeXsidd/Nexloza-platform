import 'package:flutter/material.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? icon;
  final String? organizationId;
  final String ownerId;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int deviceCount;
  final int onlineDeviceCount;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.icon,
    this.organizationId,
    required this.ownerId,
    this.settings = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deviceCount = 0,
    this.onlineDeviceCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      organizationId: json['organization_id'] as String?,
      ownerId: json['owner_id'] as String,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'icon': icon,
    'organization_id': organizationId,
    'settings': settings,
    'is_active': isActive,
  };

  static const List<String> categories = [
    'Smart Home',
    'Smart Agriculture',
    'Smart Irrigation',
    'Weather Monitoring',
    'Water Management',
    'Energy Monitoring',
    'Industrial IoT',
    'Security Monitoring',
    'Custom',
  ];

  static IconData categoryIcon(String? category) {
    return switch (category?.toLowerCase().replaceAll(' ', '_')) {
      'smart_home' => Icons.home_outlined,
      'smart_agriculture' => Icons.grass_outlined,
      'smart_irrigation' => Icons.water_drop_outlined,
      'weather_monitoring' => Icons.cloud_outlined,
      'water_management' => Icons.waves_outlined,
      'energy_monitoring' => Icons.bolt_outlined,
      'industrial_iot' => Icons.factory_outlined,
      'security_monitoring' => Icons.shield_outlined,
      _ => Icons.folder_outlined,
    };
  }
}

class ProjectTemplate {
  final String name;
  final String description;
  final String category;
  final IconData icon;

  const ProjectTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
  });

  static const List<ProjectTemplate> templates = [
    ProjectTemplate(
      name: 'Smart Home',
      description: 'Monitor and control home devices — lights, fans, temperature, motion sensors.',
      category: 'Smart Home',
      icon: Icons.home_outlined,
    ),
    ProjectTemplate(
      name: 'Smart Agriculture',
      description: 'Track soil moisture, temperature, humidity and automate irrigation for crops.',
      category: 'Smart Agriculture',
      icon: Icons.grass_outlined,
    ),
    ProjectTemplate(
      name: 'Smart Irrigation',
      description: 'Automated watering system with soil moisture sensors and valve control.',
      category: 'Smart Irrigation',
      icon: Icons.water_drop_outlined,
    ),
    ProjectTemplate(
      name: 'Weather Monitoring',
      description: 'Collect temperature, humidity, pressure and rainfall data from outdoor sensors.',
      category: 'Weather Monitoring',
      icon: Icons.cloud_outlined,
    ),
    ProjectTemplate(
      name: 'Water Management',
      description:
          'Monitor water levels in tanks, detect leaks and track consumption.',
      category: 'Water Management',
      icon: Icons.waves_outlined,
    ),
    ProjectTemplate(
      name: 'Energy Monitoring',
      description: 'Track energy consumption, voltage, current and power across circuits.',
      category: 'Energy Monitoring',
      icon: Icons.bolt_outlined,
    ),
    ProjectTemplate(
      name: 'Industrial IoT',
      description: 'Monitor industrial equipment, vibration, temperature and operational status.',
      category: 'Industrial IoT',
      icon: Icons.factory_outlined,
    ),
    ProjectTemplate(
      name: 'Security Monitoring',
      description: 'PIR motion detection, door/window sensors, camera triggers and alerts.',
      category: 'Security Monitoring',
      icon: Icons.shield_outlined,
    ),
    ProjectTemplate(
      name: 'Custom Project',
      description:
          'Start with a blank project and configure everything yourself.',
      category: 'Custom',
      icon: Icons.tune_outlined,
    ),
  ];
}
