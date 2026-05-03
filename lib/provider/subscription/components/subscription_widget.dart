import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionWidget extends StatefulWidget {
  final ProviderSubscriptionModel data;
  final VoidCallback? onTap;

  SubscriptionWidget(this.data, {this.onTap});

  @override
  SubscriptionWidgetState createState() => SubscriptionWidgetState();
}

class SubscriptionWidgetState extends State<SubscriptionWidget> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  Future<void> cancelPlan() async {
    showConfirmDialogCustom(
      context,
      title: languages.lblSubscriptionTitle,
      primaryColor: context.primaryColor,
      positiveText: languages.lblYes,
      negativeText: languages.lblCancel,
      onAccept: (_) {
        if (appConfigurationStore.isInAppPurchaseEnable) {
          cancelRevenueCatSubscription();
        } else {
          cancelCurrentSubscription();
        }
      },
    );
  }

  Future<void> cancelCurrentSubscription() async {
    Map req = {
      CommonKeys.id: widget.data.id,
    };

    appStore.setLoading(true);

    cancelSubscription(req).then((value) {
      appStore.setLoading(false);
      widget.data.status = SUBSCRIPTION_STATUS_INACTIVE;
      appStore.setPlanSubscribeStatus(false);
      if (appConfigurationStore.isInAppPurchaseEnable) {
        appStore.setProviderCurrentSubscriptionPlan(ProviderSubscriptionModel());
        appStore.setActiveRevenueCatIdentifier('');
      }

      push(ProviderDashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      setState(() {});
    }).catchError(
      (e) {
        appStore.setLoading(false);
        toast(e.toString());
      },
    );
  }

  Future<void> cancelRevenueCatSubscription() async {
    await inAppPurchaseService.init();
    inAppPurchaseService.loginToRevenueCate().then(
      (value) async {
        await inAppPurchaseService.getCustomerInfo().then(
          (value) {
            if (value.managementURL.validate().isNotEmpty) {
              commonLaunchUrl(value.managementURL.validate(), launchMode: LaunchMode.externalApplication).then((value) async {
                await inAppPurchaseService.init();
                await inAppPurchaseService.loginToRevenueCate();
                await inAppPurchaseService.getCustomerInfo().then((data) {
                  if (data.activeSubscriptions.isEmpty) {
                    cancelCurrentSubscription();
                  }
                });
              });
            } else {
            }
          },
        );
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ACTIVE — pale mint + dark teal/emerald
  static const Color _badgeActiveBg = Color(0xFFE8F5F4);
  static const Color _badgeActiveText = Color(0xFF00796B);
  // CANCELLED — pale peach + salmon
  static const Color _badgeCancelledBg = Color(0xFFFFE4E1);
  static const Color _badgeCancelledText = Color(0xFFE57373);
  // EXPIRED badge (inactive uses same) — light translucent grey (more transparent)
  static const Color _badgeExpiredBg = Color(0x3D9E9E9E);
  static const Color _badgeExpiredLabel = Color(0xFF4A4A4A);

  Widget _buildStatusBadge() {
    final String status = widget.data.status.validate().toLowerCase();
    late final Color bg;
    late final Color fg;
    late final String label;

    if (status == SUBSCRIPTION_STATUS_ACTIVE) {
      bg = _badgeActiveBg;
      fg = _badgeActiveText;
      label = languages.active.toUpperCase();
    } else if (status == SUBSCRIPTION_STATUS_CANCELLED) {
      bg = _badgeCancelledBg;
      fg = _badgeCancelledText;
      label = languages.cancelled.toUpperCase();
    } else {
      // expired, inactive (same as expired per API), or unknown
      bg = _badgeExpiredBg;
      fg = appStore.isDarkMode ? Colors.white : _badgeExpiredLabel;
      label = languages.lblExpired.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: boldTextStyle(size: 11, color: fg, letterSpacing: 0.6),
      ),
    );
  }

  Widget _buildCardBody() {
    final String dateRange =
        '${formatDate(widget.data.startAt.validate().toString(), format: DATE_FORMAT_2)} - ${formatDate(widget.data.endAt.validate().toString(), format: DATE_FORMAT_2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                dateRange,
                style: boldTextStyle(letterSpacing: 1.3),
              ),
            ),
            10.width,
            _buildStatusBadge(),
          ],
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(languages.lblPlan, style: secondaryTextStyle()),
            Text(widget.data.title.validate().capitalizeFirstLetter(), style: boldTextStyle()),
          ],
        ),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(languages.lblType, style: secondaryTextStyle()),
            Text(widget.data.type.validate().capitalizeFirstLetter(), style: boldTextStyle()),
          ],
        ),
        if (widget.data.identifier != FREE)
          Column(
            children: [
              16.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(languages.lblAmount, style: secondaryTextStyle()),
                  16.width,
                  PriceWidget(
                    price: widget.data.amount.validate(),
                    color: primaryColor,
                    isBoldText: true,
                  ).flexible(),
                ],
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showCancelButton =
        widget.data.status.validate() == SUBSCRIPTION_STATUS_ACTIVE && !appConfigurationStore.isInAppPurchaseEnable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(),
        border: Border.all(
          width: 1,
          color: context.dividerColor,
        ),
      ),
      width: context.width(),
      child: Column(
        children: [
          widget.onTap != null
              ? InkWell(
                  borderRadius: radius(),
                  onTap: widget.onTap,
                  child: _buildCardBody(),
                )
              : _buildCardBody(),
          if (showCancelButton)
            AppButton(
              text: languages.lblCancelPlan.toUpperCase(),
              margin: const EdgeInsets.only(top: 16),
              width: context.width(),
              elevation: 0,
              color: primaryColor,
              onTap: () {
                ifNotTester(context, () {
                  cancelPlan();
                });
              },
            )
        ],
      ),
    );
  }
}