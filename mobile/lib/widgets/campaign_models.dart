import 'package:flutter/material.dart';

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
  final Color corPrincipal;

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
    required this.corPrincipal,
  });
}

