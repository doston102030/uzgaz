import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_segmented_control.dart';

/// Tone/icon mapping for the seller & admin status enums, so every
/// "pending / approved / rejected" badge in the app reads identically.
extension SellerStatusUi on SellerStatus {
  PillTone get tone => switch (this) {
        SellerStatus.pending => PillTone.warning,
        SellerStatus.approved => PillTone.success,
        SellerStatus.rejected => PillTone.danger,
        SellerStatus.suspended => PillTone.neutral,
      };

  IconData get icon => switch (this) {
        SellerStatus.pending => Icons.hourglass_top_rounded,
        SellerStatus.approved => Icons.verified_rounded,
        SellerStatus.rejected => Icons.cancel_rounded,
        SellerStatus.suspended => Icons.pause_circle_rounded,
      };
}

extension ProductModerationStatusUi on ProductModerationStatus {
  PillTone get tone => switch (this) {
        ProductModerationStatus.pending => PillTone.warning,
        ProductModerationStatus.approved => PillTone.success,
        ProductModerationStatus.rejected => PillTone.danger,
      };

  IconData get icon => switch (this) {
        ProductModerationStatus.pending => Icons.hourglass_top_rounded,
        ProductModerationStatus.approved => Icons.check_circle_rounded,
        ProductModerationStatus.rejected => Icons.cancel_rounded,
      };
}

extension SellerOrderStatusUi on SellerOrderStatus {
  PillTone get tone => switch (this) {
        SellerOrderStatus.yangi => PillTone.info,
        SellerOrderStatus.tayyorlanmoqda => PillTone.warning,
        SellerOrderStatus.yetkazishga => PillTone.primary,
        SellerOrderStatus.yopildi => PillTone.success,
        SellerOrderStatus.bekorQilindi => PillTone.neutral,
      };

  IconData get icon => switch (this) {
        SellerOrderStatus.yangi => Icons.notifications_active_rounded,
        SellerOrderStatus.tayyorlanmoqda => Icons.inventory_2_rounded,
        SellerOrderStatus.yetkazishga => Icons.local_shipping_rounded,
        SellerOrderStatus.yopildi => Icons.check_circle_rounded,
        SellerOrderStatus.bekorQilindi => Icons.block_rounded,
      };

  /// The label + icon on the seller's "move forward" button, or null once
  /// the order is closed / cancelled.
  String? get nextActionLabel => switch (this) {
        SellerOrderStatus.yangi => 'Qabul qilish',
        SellerOrderStatus.tayyorlanmoqda => 'Yetkazishga tayyor',
        SellerOrderStatus.yetkazishga => 'Yopish',
        SellerOrderStatus.yopildi => null,
        SellerOrderStatus.bekorQilindi => null,
      };
}
