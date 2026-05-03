import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/plan_list_response.dart';
import 'package:handyman_provider_flutter/models/plan_request_model.dart';
import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/payment/payment_screen.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/provider/subscription/subscription_detail_screen.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:purchases_flutter/object_wrappers.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';
import 'components/subscription_widget.dart';

class PricingPlanScreen extends StatefulWidget {
  const PricingPlanScreen({Key? key}) : super(key: key);

  @override
  _PricingPlanScreenState createState() => _PricingPlanScreenState();
}

class _PricingPlanScreenState extends State<PricingPlanScreen> {
  Future<PlanListResponse>? future;

  List<ProviderSubscriptionModel> subscriptionPlanList = [];

  ProviderSubscriptionModel? selectedPricingPlan;

  ProviderSubscriptionModel? currentPlan;

  int currentSelectedPlan = -1;
  int page = 1;

  Offerings? revenueCatSubscriptionOfferings;

  List<StoreProduct> storeProductList = [];

  @override
  void initState() {
    super.initState();
    if (appConfigurationStore.isInAppPurchaseEnable) {
      inAppPurchaseService.init();
    }
    init();
  }

  Future<void> init() async {
    future = getPricingPlanList().then(
      (value) {
        subscriptionPlanList = value.data ?? [];
        currentPlan = value.currentPlan;
        if (appConfigurationStore.isInAppPurchaseEnable) {
          getRevenueCatOfferings();
        }
        setState(() {});

        return value;
      },
    );
  }

  Future<void> getRevenueCatOfferings() async {
    await inAppPurchaseService.getStoreSubscriptionPlanList().then((value) {
      revenueCatSubscriptionOfferings = value;

      if (revenueCatSubscriptionOfferings != null &&
          revenueCatSubscriptionOfferings!.current != null &&
          revenueCatSubscriptionOfferings!
              .current!.availablePackages.isNotEmpty) {
        storeProductList = revenueCatSubscriptionOfferings!
            .current!.availablePackages
            .map((e) => e.storeProduct)
            .toList();
        Set<String> revenueCatIdentifiers = revenueCatSubscriptionOfferings!
            .current!.availablePackages
            .map((package) => package.storeProduct.identifier)
            .toSet();

        // Filter backend plans to match RevenueCat identifiers

        subscriptionPlanList = subscriptionPlanList.where((plan) {
          return (revenueCatIdentifiers.contains(
            isIOS ? plan.appStoreIdentifier : plan.playStoreIdentifier,
          ));
        }).toList();

        setState(() {});
      }
    }).catchError((e) {
      log("Can't find revenueCat offerings");
    });
  }

  Package? getSelectedPlanFromRevenueCat(
    ProviderSubscriptionModel selectedPlan,
  ) {
    if (revenueCatSubscriptionOfferings != null &&
        revenueCatSubscriptionOfferings!.current != null &&
        revenueCatSubscriptionOfferings!
            .current!.availablePackages.isNotEmpty) {
      int index = revenueCatSubscriptionOfferings!.current!.availablePackages
          .indexWhere(
        (element) =>
            element.storeProduct.identifier ==
            (isIOS
                ? selectedPlan.appStoreIdentifier
                : selectedPlan.playStoreIdentifier),
      );
      if (index > -1) {
        return revenueCatSubscriptionOfferings!
            .current!.availablePackages[index];
      }
    } else {
      return null;
    }
    return null;
  }

  Future<void> saveSubscriptionPurchase({
    required String paymentType,
    String transactionId = '',
  }) async {
    appStore.setLoading(true);

    PlanRequestModel planRequestModel = PlanRequestModel()
      ..amount = selectedPricingPlan!.amount
      ..description = selectedPricingPlan!.description
      ..duration = selectedPricingPlan!.duration
      ..identifier = selectedPricingPlan!.identifier
      ..otherTransactionDetail = ''
      ..paymentStatus = PAID
      ..paymentType = paymentType
      ..planId = selectedPricingPlan!.id
      ..planLimitation = selectedPricingPlan!.planLimitation
      ..planType = selectedPricingPlan!.planType
      ..title = selectedPricingPlan!.title
      ..txnId = transactionId
      ..type = selectedPricingPlan!.type
      ..userId = appStore.userId;

    if (appConfigurationStore.isInAppPurchaseEnable) {
      planRequestModel.activeRevenueCatIdentifier = isIOS
          ? selectedPricingPlan!.appStoreIdentifier
          : selectedPricingPlan!.playStoreIdentifier;
    }

    log('Request : ${planRequestModel.toJson()}');

    await saveSubscription(planRequestModel.toJson()).then((value) {
      appStore.setLoading(false);
      toast(
        "${selectedPricingPlan!.title.validate()} ${languages.lblSuccessFullyActivated}",
      );

      push(
        ProviderDashboardScreen(index: 0),
        isNewTask: true,
        pageRouteAnimation: PageRouteAnimation.Fade,
      );
    }).catchError((e) {
      toast(e.toString());
      appStore.setLoading(false);
      if (appConfigurationStore.isInAppPurchaseEnable) {
        setValue(IS_RESTORE_PURCHASE_REQUIRED, true);
        setValue(PURCHASE_REQUEST, planRequestModel.toJson());
      }
      log(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  /// Shows adjusted billing when user has a current plan and the selected plan
  /// includes proration (`original_amount` vs `amount`) or `credit_applied` in `other_detail`.
  bool _shouldShowProrationBilling() {
    final p = selectedPricingPlan;
    if (p == null || currentPlan == null) return false;
    if (p.identifier == FREE || p.amount.validate() == 0) return false;
    final credit = p.otherDetail?.creditApplied;
    final hasCredit = credit != null && credit.toDouble() > 0;
    final orig = p.originalAmount;
    final amt = p.amount;
    final hasProratedPrice = orig != null && amt != null && orig != amt;
    return hasCredit || hasProratedPrice;
  }

  Future<void> _handleCheckoutTap(BuildContext context) async {
    if (selectedPricingPlan!.identifier == FREE ||
        selectedPricingPlan!.amount.validate() == 0) {
      await saveSubscriptionPurchase(
        paymentType: PAYMENT_METHOD_COD,
        transactionId: '',
      );
    } else {
      if (appConfigurationStore.isInAppPurchaseEnable) {
        if (selectedPricingPlan != null) {
          Package? selectedRevenueCatPackage =
              await getSelectedPlanFromRevenueCat(
            selectedPricingPlan!,
          );
          if (selectedRevenueCatPackage != null) {
            inAppPurchaseService.startPurchase(
              selectedRevenueCatPackage: selectedRevenueCatPackage,
              onComplete: (String transactionId) async {
                await saveSubscriptionPurchase(
                  paymentType: PAYMENT_METHOD_IN_APP_PURCHASE,
                  transactionId: transactionId,
                );
              },
            );
          } else {
            toast(languages.canTFindRevenuecatProduct);
          }
        }
      } else {
        PaymentScreen(selectedPricingPlan!).launch(context);
      }
    }
  }

  /// Credit from API, or implied proration credit when `original_amount` > `amount`.
  num _adjustmentBalanceAmount(ProviderSubscriptionModel p) {
    final num fromApi = p.otherDetail?.creditApplied ?? 0;
    if (fromApi.toDouble() > 0) return fromApi;
    final int? orig = p.originalAmount;
    final int? amt = p.amount;
    if (orig != null && amt != null && orig > amt) {
      return orig - amt;
    }
    return 0;
  }

  Widget _buildAdjustmentBanner(BuildContext context) {
    final p = selectedPricingPlan!;
    final num balance = _adjustmentBalanceAmount(p);
    final String text;
    if (balance.toDouble() > 0) {
      text = languages.lblPreviousBalanceWillBeAdjusted(
        balance.toPriceFormat(),
      );
    } else {
      text = languages.lblSubscriptionPriceAdjustedNotice;
    }

    // No fill: gold on dark scaffold, deep orange on light for contrast on default background.
    final Color accentText =
        appStore.isDarkMode ? const Color(0xFFFFCA28) : const Color(0xFFE65100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: primaryTextStyle(
          size: 12,
          color: accentText,
          weight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckoutWithBilling(BuildContext context) {
    final p = selectedPricingPlan!;
    final int? orig = p.originalAmount;
    final int amt = p.amount.validate();
    final bool showStrikethrough = orig != null && orig != amt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAdjustmentBanner(context),
        12.height,
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (showStrikethrough)
                        Text(
                          orig.validate().toPriceFormat(),
                          style: secondaryTextStyle(
                            size: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        amt.toPriceFormat(),
                        style: boldTextStyle(size: 20),
                      ),
                    ],
                  ),
                  4.height,
                  Text(
                    languages.lblAmountToPay,
                    style: secondaryTextStyle(size: 12),
                  ),
                ],
              ),
            ),
            12.width,
            AppButton(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                currentPlan != null
                    ? languages.lblUpgradePlan
                    : (selectedPricingPlan!.identifier == FREE
                        ? languages.lblProceed
                        : languages.lblMakePayment),
                style: boldTextStyle(color: white, size: 14),
              ),
              color: primaryColor,
              onTap: () => _handleCheckoutTap(context),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblPricingPlan,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SnapHelperWidget<PlanListResponse>(
            future: future,
            loadingWidget: LoaderWidget(),
            onSuccess: (res) {
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (res.currentPlan != null) ...[
                    12.height,
                    // if(res.currentPlan!.status.validate() == SUBSCRIPTION_STATUS_CANCELLED) ...[
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16),
                    //     child: Text(
                    //       languages.subscriptionCancelledUntil(
                    //         formatDate(
                    //           res.currentPlan!.endAt.validate().toString(),
                    //           format: DATE_FORMAT_2,
                    //         ),
                    //       ),
                    //       style: secondaryTextStyle(),
                    //     ),
                    //   ),
                    //   4.height,
                    // ],
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: SubscriptionWidget(
                        res.currentPlan!,
                        onTap: () {
                          push(
                            SubscriptionDetailScreen(data: res.currentPlan!),
                            pageRouteAnimation: PageRouteAnimation.Fade,
                          );
                        },
                      ),
                    ),
                    if (subscriptionPlanList.isNotEmpty) ...[ 
                      16.height,
                      Text(
                        languages.lblChoosePlanToUpgrade,
                        style: secondaryTextStyle(size: 14),
                      ).paddingSymmetric(horizontal: 16),
                      8.height,
                    ],
                  ] else ...[
                    42.height,
                    Text(languages.lblSelectPlan,
                            style: boldTextStyle(size: 16))
                        .center(),
                    8.height,
                    Text(
                      languages.selectPlanSubTitle,
                      style: secondaryTextStyle(),
                    ).center(),
                    24.height,
                  ],
                  AnimatedListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        bottom: 140, top: 8, right: 8, left: 8),
                    itemCount: subscriptionPlanList.length,
                    itemBuilder: (_, index) {
                      ProviderSubscriptionModel data =
                          subscriptionPlanList[index];
                      StoreProduct? revenueCatProduct;
                      if (appConfigurationStore.isInAppPurchaseEnable) {
                        revenueCatProduct =
                            getSelectedPlanFromRevenueCat(data)?.storeProduct;
                      }
                      final isSelected = currentSelectedPlan == index;
                      final showCompare = isSelected && currentPlan != null;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedContainer(
                            duration: 500.milliseconds,
                            decoration: boxDecorationWithRoundedCorners(
                              borderRadius: radius(),
                              backgroundColor: context.scaffoldBackgroundColor,
                              border: Border.all(
                                color: currentSelectedPlan == index
                                    ? primaryColor
                                    : context.dividerColor,
                                width: 1.5,
                              ),
                            ),
                            margin: const EdgeInsets.all(8),
                            width: context.width(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (currentSelectedPlan == index)
                                      AnimatedContainer(
                                        duration: 500.milliseconds,
                                        decoration: BoxDecoration(
                                          color: context.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      )
                                    else
                                      AnimatedContainer(
                                        duration: 500.milliseconds,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.transparent,
                                          size: 16,
                                        ),
                                      ),
                                    16.width,
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (revenueCatProduct != null)
                                              Text(
                                                '${revenueCatProduct.title.capitalizeEachWord()}',
                                                style: boldTextStyle(),
                                              ).flexible()
                                            else
                                              Text(
                                                '${data.title.capitalizeEachWord()}',
                                                style: boldTextStyle(),
                                              ).flexible(),
                                            if (revenueCatProduct == null) ...[
                                              if (data.trialPeriod.validate() !=
                                                      0 &&
                                                  data.identifier == FREE)
                                                RichText(
                                                  text: TextSpan(
                                                    text:
                                                        ' (${languages.lblTrialFor} ',
                                                    style: secondaryTextStyle(),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text:
                                                            ' ${data.trialPeriod.validate()} ',
                                                        style: boldTextStyle(),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '${languages.lblDays})',
                                                        style:
                                                            secondaryTextStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Text(
                                                  ' (${data.type.validate().capitalizeFirstLetter()})',
                                                  style: secondaryTextStyle(),
                                                ),
                                            ],
                                          ],
                                        ),
                                        if (data.description
                                            .validate()
                                            .isNotEmpty) ...[
                                          2.height,
                                          Text(
                                            data.description.validate(),
                                            style: secondaryTextStyle(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ).expand(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: context.primaryColor,
                                        borderRadius: radius(),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      child: revenueCatProduct != null
                                          ? Text(
                                              '${revenueCatProduct.priceString}',
                                              style: boldTextStyle(
                                                color: white,
                                                size: 12,
                                              ),
                                            )
                                          : data.identifier == FREE
                                              ? Text(
                                                  '${languages.lblFreeTrial}',
                                                  style: boldTextStyle(
                                                    color: white,
                                                    size: 12,
                                                  ),
                                                )
                                              : (data.originalAmount == null ||
                                                      data.originalAmount ==
                                                          data.amount)
                                                  ? Text(
                                                      data.amount
                                                          .validate()
                                                          .toPriceFormat(),
                                                      style: boldTextStyle(
                                                        color: white,
                                                        size: 12,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          data.originalAmount
                                                              .validate()
                                                              .toPriceFormat(),
                                                          style: boldTextStyle(
                                                            color: white
                                                                .withValues(
                                                                    alpha: 0.8),
                                                            size: 11,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            decorationColor:
                                                                white,
                                                          ),
                                                        ),
                                                        4.width,
                                                        Text(
                                                          data.amount
                                                              .validate()
                                                              .toPriceFormat(),
                                                          style: boldTextStyle(
                                                            color: white,
                                                            size: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                    ),
                                  ],
                                ),
                                if (data.planType == 'limited')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      16.height,
                                      Container(
                                        decoration:
                                            boxDecorationWithRoundedCorners(
                                          backgroundColor: context.cardColor,
                                          borderRadius: radius(),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        width: context.width(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                  getPlanStatusImage(
                                                    limitData: data
                                                        .planLimitation!
                                                        .service!,
                                                  ),
                                                  width: 14,
                                                  height: 14,
                                                ),
                                                8.width,
                                                getPlanStatus(
                                                  limitData: data
                                                      .planLimitation!.service!,
                                                  name: languages.lblServices,
                                                ),
                                              ],
                                            ),
                                            8.height,
                                            Row(
                                              children: [
                                                Image.asset(
                                                  getPlanStatusImage(
                                                    limitData: data
                                                        .planLimitation!
                                                        .handyman!,
                                                  ),
                                                  width: 14,
                                                  height: 14,
                                                ),
                                                8.width,
                                                getPlanStatus(
                                                  limitData: data
                                                      .planLimitation!
                                                      .handyman!,
                                                  name: languages.handyman,
                                                ),
                                              ],
                                            ),
                                            8.height,
                                            Row(
                                              children: [
                                                Image.asset(
                                                  getPlanStatusImage(
                                                    limitData: data
                                                        .planLimitation!
                                                        .featuredService!,
                                                  ),
                                                  width: 14,
                                                  height: 14,
                                                ),
                                                8.width,
                                                getPlanStatus(
                                                  limitData: data
                                                      .planLimitation!
                                                      .featuredService!,
                                                  name: languages
                                                      .lblFeaturedServices,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      16.height,
                                      Container(
                                        decoration:
                                            boxDecorationWithRoundedCorners(
                                          backgroundColor: context.cardColor,
                                          borderRadius: radius(),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        width: context.width(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            getUnlimitedServiceWidget(
                                                languages.lblServices),
                                            8.height,
                                            getUnlimitedServiceWidget(
                                                languages.handyman),
                                            8.height,
                                            getUnlimitedServiceWidget(
                                                languages.lblFeaturedServices),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ).onTap(() {
                            selectedPricingPlan = data;
                            currentSelectedPlan = index;

                            setState(() {});
                          }),
                          if (showCompare) ...[
                            8.height,
                            _buildPlanComparisonSection(
                                context, currentPlan!, data),
                            8.height,
                          ],
                        ],
                      );
                    },
                    emptyWidget: NoDataWidget(
                      title: languages.noSubscriptionPlan,
                      imageWidget: const EmptyStateWidget(),
                    ),
                  ),
                ],
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: const ErrorStateWidget(),
                retryText: languages.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);

                  init();
                  setState(() {});
                },
              );
            },
          ),
          if (selectedPricingPlan != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _shouldShowProrationBilling()
                    ? _buildCheckoutWithBilling(context)
                    : AppButton(
                        child: Text(
                          currentPlan != null
                              ? languages.lblUpgradePlan
                              : (selectedPricingPlan!.identifier == FREE
                                  ? languages.lblProceed
                                  : languages.lblMakePayment),
                          style: boldTextStyle(color: white),
                        ),
                        color: primaryColor,
                        onTap: () => _handleCheckoutTap(context),
                      ),
              ),
            ),
          Observer(
            builder: (_) => LoaderWidget().center().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanComparisonSection(
    BuildContext context,
    ProviderSubscriptionModel current,
    ProviderSubscriptionModel selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languages.lblPlanComparison,
            style: boldTextStyle(size: 16),
          ),
          12.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _comparisonPlanCard(
                  title: languages.lblCurrentPlan,
                  plan: current,
                  borderColor: Colors.grey,
                ),
              ),
              12.width,
              Expanded(
                child: _comparisonPlanCard(
                  title: languages.lblSelectedPlan,
                  plan: selected,
                  borderColor: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _comparisonPlanCard({
    required String title,
    required ProviderSubscriptionModel plan,
    required Color borderColor,
  }) {
    final isFree = plan.identifier == FREE;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: boldTextStyle(size: 14, color: borderColor),
          ),
          14.height,
          _comparisonRow(
              languages.lblPlan, plan.title.validate().capitalizeFirstLetter()),
          10.height,
          _comparisonRow(
              languages.lblType, plan.type.validate().capitalizeFirstLetter()),
          10.height,
          _comparisonRow(
            languages.lblAmount,
            isFree
                ? languages.lblFreeTrial
                : plan.amount.validate().toPriceFormat(),
          ),
          14.height,
          Divider(height: 1, color: context.dividerColor),
          10.height,
          if (plan.planType == 'limited' && plan.planLimitation != null) ...[
            if (plan.planLimitation!.service != null &&
                plan.planLimitation!.service!.isChecked == 'on')
              _comparisonLimitRow(languages.lblServices,
                  plan.planLimitation!.service!.limit.validate()),
            if (plan.planLimitation!.handyman != null &&
                plan.planLimitation!.handyman!.isChecked == 'on')
              _comparisonLimitRow(languages.handyman,
                  plan.planLimitation!.handyman!.limit.validate()),
            if (plan.planLimitation!.featuredService != null &&
                plan.planLimitation!.featuredService!.isChecked == 'on')
              _comparisonLimitRow(languages.lblFeaturedServices,
                  plan.planLimitation!.featuredService!.limit.validate()),
          ] else ...[
            _comparisonUnlimitedRow(languages.lblServices),
            _comparisonUnlimitedRow(languages.handyman),
            _comparisonUnlimitedRow(languages.lblFeaturedServices),
          ],
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: secondaryTextStyle(size: 13)),
        12.width,
        Flexible(
          child: Text(
            value,
            style: boldTextStyle(size: 13),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _comparisonLimitRow(String name, String limit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          8.width,
          Expanded(
              child: Text(
            '$limit $name',
            style: secondaryTextStyle(size: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  Widget _comparisonUnlimitedRow(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          8.width,
          Expanded(
              child: Text(
            '${languages.unlimited} $name',
            style: secondaryTextStyle(size: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  Widget getPlanStatus({required LimitData limitData, required String name}) {
    if (limitData.isChecked.validate() == 'on') {
      return RichTextWidget(
        list: [
          TextSpan(
            text: '${languages.hintAdd} ${languages.upTo} ',
            style: primaryTextStyle(),
          ),
          TextSpan(
            text: '${limitData.limit.validate()} ',
            style: boldTextStyle(color: primaryColor, size: 15),
          ),
          TextSpan(
            text: name,
            style: primaryTextStyle(),
          ),
        ],
      );
    } else {
      return RichTextWidget(
        list: [
          TextSpan(
            text: '${languages.hintAdd} $name',
            style: primaryTextStyle(),
          ),
        ],
      );
    }
  }

  Widget getUnlimitedServiceWidget(String name) {
    return Row(
      children: [
        Image.asset(
          pricing_plan_accept,
          width: 14,
          height: 14,
        ),
        8.width,
        RichTextWidget(
          list: [
            TextSpan(
              text: '${languages.unlimited} $name',
              style: primaryTextStyle(),
            ),
          ],
        ),
      ],
    );
  }

  String getPlanStatusImage({required LimitData limitData}) {
    if (limitData.isChecked == 'on') {
      return pricing_plan_accept;
    } else {
      return pricing_plan_reject;
    }
  }
}
