import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import 'campaign_models.dart';

class CampaignProgressBar extends StatelessWidget {
  final ThemeProvider theme;
  final double progress;
  final Color? color;
  final Color? background;

  const CampaignProgressBar({
    super.key,
    required this.theme,
    required this.progress,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        minHeight: 8,
        backgroundColor: background ?? (theme.isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
        valueColor: AlwaysStoppedAnimation<Color>(color ?? theme.accent),
      ),
    );
  }
}

class CampaignListTile extends StatelessWidget {
  final ThemeProvider theme;
  final Campaign campaign;

  const CampaignListTile({super.key, required this.theme, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: campaign.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                campaign.icon,
                color: theme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    campaign.stamps,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CampaignProgressBar(theme: theme, progress: campaign.progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
