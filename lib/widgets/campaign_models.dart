import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Campaign {
  final String name;
  final String stamps;
  final IconData icon;
  final Color iconBg;
  final double progress; // 0..1
  final String? tag; // ex: "Quase lá!"

  const Campaign({
    required this.name,
    required this.stamps,
    required this.icon,
    required this.iconBg,
    required this.progress,
    this.tag,
  });
}

class FeaturedCampaign extends Campaign {
  final String rewardTitle;
  final String rewardSubtitle;
  final int currentStamps;
  final int totalStamps;
  final String progressLabel;
  final String imageUrl;
  final String imageFallbackEmoji;

  const FeaturedCampaign({
    required super.name,
    required super.stamps,
    required super.icon,
    required super.iconBg,
    required super.progress,
    super.tag,
    required this.rewardTitle,
    required this.rewardSubtitle,
    required this.currentStamps,
    required this.totalStamps,
    required this.progressLabel,
    required this.imageUrl,
    required this.imageFallbackEmoji,
  });
}

class HomeCampaigns {
  static final FeaturedCampaign featured = FeaturedCampaign(
    name: 'Café Grátis na Artisan',
    stamps: '8/10 selos',
    icon: Icons.local_cafe_outlined,
    iconBg: AppColors.accent,
    progress: 0.8,
    tag: 'Quase lá!',
    rewardTitle: 'Café Grátis na Artisan',
    rewardSubtitle:
        'Faltam apenas 2 selos para resgatar sua recompensa favorita.',
    currentStamps: 8,
    totalStamps: 10,
    progressLabel: '80%',
    imageUrl: '',
    imageFallbackEmoji: '☕',
  );

  static final List<Campaign> others = [
    const Campaign(
      name: 'Grão & Arte Cafeteria',
      stamps: '5/10 acumulados',
      icon: Icons.coffee_outlined,
      iconBg: Color(0xFFE9D5F5),
      progress: 0.5,
    ),
    const Campaign(
      name: 'Studio Estrela',
      stamps: '3/5 acumulados',
      icon: Icons.content_cut,
      iconBg: Color(0xFFE9D5F5),
      progress: 0.6,
    ),
  ];
}
