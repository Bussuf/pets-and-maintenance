import 'package:flutter/material.dart';

/// קטלוג מרכזי ומאוחד של כל סמלי האפליקציה (Filled + Outlined)
class AppIcons {
  static final Map<String, IconData> catalog = {
    // --- חיות מחמד (Filled + Outlined) ---
    'pets': Icons.pets,
    'pets_outlined': Icons.pets_outlined,
    'cruelty_free': Icons.cruelty_free,
    'cruelty_free_outlined': Icons.cruelty_free_outlined,
    'flutter_dash': Icons.flutter_dash,
    'flutter_dash_outlined': Icons.flutter_dash_outlined,

    // --- מוזיקה וכלי נגינה (Filled + Outlined) ---
    'music': Icons.music_note,
    'music_outlined': Icons.music_note_outlined,
    'queue_music': Icons.queue_music,
    'queue_music_outlined': Icons.queue_music_outlined,
    'headphones': Icons.headphones,
    'headphones_outlined': Icons.headphones_outlined,
    'piano': Icons.piano,
    'piano_outlined': Icons.piano_outlined,
    'graphic_eq': Icons.graphic_eq,
    'graphic_eq_outlined': Icons.graphic_eq_outlined,
    'mic': Icons.mic,
    'mic_outlined': Icons.mic_outlined,
    'radio': Icons.radio,
    'radio_outlined': Icons.radio_outlined,

    // --- בית, ניקיון ותחזוקה (Filled + Outlined) ---
    'home': Icons.home,
    'home_outlined': Icons.home_outlined,
    'cleaning': Icons.cleaning_services,
    'cleaning_outlined': Icons.cleaning_services_outlined,
    'build': Icons.build,
    'build_outlined': Icons.build_outlined,
    'plumbing': Icons.plumbing,
    'plumbing_outlined': Icons.plumbing_outlined,
    'roofing': Icons.roofing,
    'roofing_outlined': Icons.roofing_outlined,
    'handyman': Icons.handyman,
    'handyman_outlined': Icons.handyman_outlined,
    'yard': Icons.yard,
    'yard_outlined': Icons.yard_outlined,
    'light': Icons.lightbulb,
    'light_outlined': Icons.lightbulb_outline,

    // --- רכב ותחבורה (Filled + Outlined) ---
    'car': Icons.directions_car,
    'car_outlined': Icons.directions_car_outlined,
    'motorcycle': Icons.two_wheeler,
    'motorcycle_outlined': Icons.two_wheeler_outlined,
    'gas': Icons.local_gas_station,
    'gas_outlined': Icons.local_gas_station_outlined,
    'ev': Icons.electric_car,
    'ev_outlined': Icons.electric_car_outlined,

    // --- כושר ובריאות (Filled + Outlined) ---
    'fitness': Icons.fitness_center,
    'fitness_outlined': Icons.fitness_center_outlined,
    'run': Icons.directions_run,
    'run_outlined': Icons.directions_run_outlined,
    'health': Icons.favorite,
    'health_outlined': Icons.favorite_border_outlined,
    'meditation': Icons.self_improvement,
    'meditation_outlined': Icons.self_improvement_outlined,
    'spa': Icons.spa,
    'spa_outlined': Icons.spa_outlined,
    'medication': Icons.medication,
    'medication_outlined': Icons.medication_outlined,

    // --- עבודה, טכנולוגיה ומחשבים (Filled + Outlined) ---
    'work': Icons.work,
    'work_outlined': Icons.work_outline,
    'laptop': Icons.laptop,
    'laptop_outlined': Icons.laptop_outlined,
    'devices': Icons.devices,
    'devices_outlined': Icons.devices_outlined,
    'folder': Icons.folder,
    'folder_outlined': Icons.folder_outlined,
    'code': Icons.code,
    'code_outlined': Icons.code_outlined,
    'terminal': Icons.terminal,
    'terminal_outlined': Icons.terminal_outlined,

    // --- גינון, טבע ואישי (Filled + Outlined) ---
    'flower': Icons.local_florist,
    'flower_outlined': Icons.local_florist_outlined,
    'park': Icons.park,
    'park_outlined': Icons.park_outlined,
    'water': Icons.water_drop,
    'water_outlined': Icons.water_drop_outlined,
    'shopping': Icons.shopping_cart,
    'shopping_outlined': Icons.shopping_cart_outlined,
    'inventory': Icons.inventory_2,
    'inventory_outlined': Icons.inventory_2_outlined,
    'star': Icons.star,
    'star_outlined': Icons.star_border_outlined,
  };

  /// פונקציית עזר מרכזית לקבלת IconData מתוך שם מפתח שמור ב-DB
  static IconData getIcon(String? iconKey) {
    if (iconKey == null) return Icons.folder_outlined;
    return catalog[iconKey] ?? Icons.folder_outlined;
  }
}