import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/shop_hours_model.dart';
import 'package:handyman_provider_flutter/models/shop_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/components/service_widget.dart';
import 'package:handyman_provider_flutter/provider/shop/components/shop_image_slider.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

import 'shimmer/shop_detail_shimmer.dart';

const List<String> _shopDetailDaysOrder = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({
    Key? key,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Future<ShopDetailResponse>? future;
  int _selectedDetailTab = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getShopDetail(widget.shopId);
  }

  // Future<void> _toggleFavorite(ShopModel shop) async {
  //   if (shop.isFavourite == 1) {
  //     // Remove from favorites
  //     shop.isFavourite = 0;
  //     setState(() {});

  //     await removeShopFromWishList(shopId: shop.id.validate()).then((value) {
  //       if (!value) {
  //         shop.isFavourite = 1;
  //         setState(() {});
  //       }
  //     });
  //   } else {
  //     // Add to favorites
  //     shop.isFavourite = 1;
  //     setState(() {});

  //     await addShopToWishList(shopId: shop.id.validate()).then((value) {
  //       if (!value) {
  //         shop.isFavourite = 0;
  //         setState(() {});
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblShopDetails,
      body: SnapHelperWidget<ShopDetailResponse>(
        future: future,
        loadingWidget: ShopDetailShimmer(),
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: languages.reload,
            onRetry: () {
              init();
              setState(() {});
            },
          ).center();
        },
        onSuccess: (shopResponse) {
          final ShopModel? shop = shopResponse.shopDetail;
          if (shop == null) {
            return NoDataWidget(
              title: languages.noDataFound,
              imageWidget: EmptyStateWidget(),
              retryText: languages.reload,
              onRetry: () {
                init();
                setState(() {});
              },
            ).center();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 60, left: 16, top: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Shop Image Slider
                Container(
                  height: 180,
                  width: context.width(),
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: radius(16),
                    backgroundColor: context.cardColor,
                  ),
                  child: ShopImageSlider(imageList: shop.shopImage),
                ),
                SizedBox(
                  height: (shop.shopImage.validate().isNotEmpty &&
                          shop.shopImage.validate().length > 1)
                      ? 25
                      : 12,
                ),

                /// Shop Contact Details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: boldTextStyle(size: 18)),
                    8.height,
                    if ((shop.email.validate().isNotEmpty) ||
                        (shop.contactNumber.validate().isNotEmpty)) ...[
                      if (shop.email.validate().isNotEmpty) ...[
                        TextIcon(
                          spacing: 10,
                          onTap: () {
                            launchMail("${shop.email.validate()}");
                          },
                          prefix: Image.asset(ic_message,
                              width: 16,
                              height: 16,
                              color: appStore.isDarkMode
                                  ? Colors.white
                                  : context.primaryColor),
                          text: shop.email.validate(),
                          textStyle: secondaryTextStyle(size: 14),
                          expandedText: true,
                        ),
                        6.height,
                      ],
                      if (shop.contactNumber.validate().isNotEmpty) ...[
                        TextIcon(
                          spacing: 10,
                          onTap: () {
                            launchCall("${shop.contactNumber.validate()}");
                          },
                          prefix: Image.asset(calling,
                              width: 16,
                              height: 16,
                              color: appStore.isDarkMode
                                  ? Colors.white
                                  : context.primaryColor),
                          text: shop.contactNumber.validate(),
                          textStyle: secondaryTextStyle(size: 14),
                          expandedText: true,
                        ),
                        6.height,
                      ]
                    ],
                    if (shop.latitude != 0 && shop.longitude != 0) ...[
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              ic_location,
                              width: 18,
                              height: 18,
                              color: appStore.isDarkMode
                                  ? Colors.white
                                  : context.primaryColor,
                            ),
                            10.width,
                            Text("${shop.address}, ${shop.cityName}, ${shop.stateName}, ${shop.countryName}",
                                    style: secondaryTextStyle(size: 14))
                                .flexible(),
                          ],
                        ),
                      ).onTap(() {
                        if (shop.latitude != 0 && shop.longitude != 0) {
                          launchMapFromLatLng(
                              latitude: shop.latitude,
                              longitude: shop.longitude);
                        } else {
                          launchMap(shop.address);
                        }
                      }),
                      6.height,
                    ],
                    if (shop.shopStartTime.isNotEmpty &&
                        shop.shopEndTime.isNotEmpty) ...[
                      TextIcon(
                        spacing: 10,
                        prefix: Image.asset(ic_time_slots,
                            width: 16,
                            height: 16,
                            color: appStore.isDarkMode
                                ? Colors.white
                                : context.primaryColor),
                        text: "${shop.shopStartTime} - ${shop.shopEndTime}",
                        textStyle: secondaryTextStyle(size: 14),
                        expandedText: true,
                      ),
                      6.height,
                    ]
                  ],
                ),
                16.height,

                /// Services & Business Hours Tabs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailTabBar(
                      tabs: [languages.lblServices, languages.lblBusinessHours],
                      selectedIndex: _selectedDetailTab,
                      onTap: (index) =>
                          setState(() => _selectedDetailTab = index),
                    ),
                    16.height,
                    if (_selectedDetailTab == 0) ...[
                      if (shop.services.validate().isNotEmpty)
                        AnimatedWrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: shop.services.validate().map((e) {
                            return ServiceComponent(
                              width: context.width() / 2 - 24,
                              data: ServiceData(
                                id: e.id,
                                name: e.name,
                                price: e.price,
                                discount: 0,
                                providerName: shop.providerName,
                                providerImage: shop.providerImage,
                                imageAttachments: e.imageAttachments,
                                categoryName: e.categoryName,
                                totalRating: e.totalRating,
                                visitType: VISIT_OPTION_SHOP,
                                status: e.status,
                              ),
                            );
                          }).toList(),
                        )
                      else
                        NoDataWidget(
                          title: languages.noServiceFound,
                          imageWidget: EmptyStateWidget(),
                        ),
                    ] else
                      _ShopBusinessHoursTable(
                          shopHour: shop.shopHour.validate()),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Segmented tab bar: single pill with two equal segments; selected is filled, unselected is muted.
class _DetailTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DetailTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(22),
        backgroundColor: context.cardColor,
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: EdgeInsets.all(4),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(18),
                  backgroundColor:
                      isSelected ? context.primaryColor : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: boldTextStyle(
                    size: 13,
                    color: isSelected ? Colors.white : context.iconColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Read-only weekly business hours table for Shop Detail.
class _ShopBusinessHoursTable extends StatelessWidget {
  final List<ShopDayModel> shopHour;

  const _ShopBusinessHoursTable({required this.shopHour});

  static String _dayDisplayName(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <String, ShopDayModel>{};
    for (final d in shopHour) {
      if (d.day.isNotEmpty) byDay[d.day.toLowerCase()] = d;
    }
    final currentWeekday = DateTime.now().weekday;
    final mondayBasedIndex = currentWeekday - 1;

    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: context.cardColor,
      ),
      child: Column(
        children: [
          /// Table header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 110,
                    child:
                        Text(languages.lblDay, style: boldTextStyle(size: 12))),
                Expanded(
                    child: Text(languages.lblBusinessHours,
                        style: boldTextStyle(size: 12))),
              ],
            ),
          ),

          /// Rows: Monday → Sunday
          ...List.generate(_shopDetailDaysOrder.length, (index) {
            final dayKey = _shopDetailDaysOrder[index];
            final dayData = byDay[dayKey];
            final isToday = (index == mondayBasedIndex);
            final isClosed = dayData?.isHoliday ?? false;
            final hoursText = isClosed
                ? languages.closed
                : (dayData != null
                    ? '${dayData.startTime} – ${dayData.endTime}'
                    : '9:00 AM – 6:00 PM');

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isToday
                    ? context.primaryColor.withValues(alpha: 0.06)
                    : null,
                border: Border(
                    bottom: BorderSide(
                        color: context.dividerColor.withValues(alpha: 0.5))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayDisplayName(dayKey),
                          style: isToday
                              ? boldTextStyle(
                                  size: 13, color: context.primaryColor)
                              : (isClosed
                                  ? secondaryTextStyle(
                                      size: 13, color: context.iconColor)
                                  : primaryTextStyle(size: 13)),
                        ),
                        if (dayData != null && dayData.breaks.isNotEmpty)
                          Text(
                            languages.lblBreak,
                            style: secondaryTextStyle(
                                size: 10, color: context.primaryColor),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hoursText,
                          style: isClosed
                              ? secondaryTextStyle(
                                  size: 12, color: context.iconColor)
                              : secondaryTextStyle(size: 12),
                        ),
                        if (dayData != null)
                          ...dayData.breaks.map(
                            (b) => Text(
                              '${b.startBreak} – ${b.endBreak}',
                              style: secondaryTextStyle(
                                  size: 10, color: context.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
