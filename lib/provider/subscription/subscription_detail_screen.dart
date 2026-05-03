import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/pdf_viewer_component.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final ProviderSubscriptionModel data;

  const SubscriptionDetailScreen({super.key, required this.data});

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  bool _isDownloadingInvoice = false;

  Future<void> _downloadAndOpenInvoice(BuildContext context) async {
    if (_isDownloadingInvoice) return;

    final int subscriptionId = widget.data.id.validate();
    if (subscriptionId <= 0) {
      toast(errorSomethingWentWrong);
      return;
    }

    setState(() => _isDownloadingInvoice = true);
    try {
      final String pdfPath =
          await downloadSubscriptionInvoice(subscriptionId: subscriptionId);
      final String? savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: pdfPath,
          fileName: 'subscription_invoice_$subscriptionId.pdf',
        ),
      );

      if (savedPath == null || savedPath.isEmpty) return;

      await PdfViewerComponent(pdfFile: pdfPath, isFile: true).launch(context);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _isDownloadingInvoice = false);
    }
  }

  DateTime? _tryParseDate(String? dateTime) {
    final parsed = DateTime.tryParse(dateTime?.validate() ?? '');
    return parsed;
  }

  String _durationTypeText(String duration, int durationValue) {
    final String durationKey = duration.toLowerCase();

    switch (durationKey) {
      // Backend sometimes contains the misspelling "mothly"
      case 'monthly':
        return durationValue > 1 ? languages.lblMonths : languages.lblMonth;
      case 'yearly':
        return durationValue > 1 ? languages.lblYears : languages.lblYear;
      case 'weekly':
        return durationValue > 1 ? languages.lblWeeks : languages.lblWeek;
      case 'daily':
        return durationValue > 1 ? languages.lblDays : languages.lblDay;
      default:
        return duration;
    }
  }

  Widget _metricColumn({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: secondaryTextStyle(size: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          6.height,
          Text(
            value,
            style: boldTextStyle(size: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(label, style: secondaryTextStyle(size: 13))),
          16.width,
          Flexible(
            child: Text(
              value,
              style: boldTextStyle(size: 13),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required BuildContext buildContext,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationWithRoundedCorners(
          backgroundColor: buildContext.cardColor,
          borderRadius: radius(10),
          border: Border.all(color: buildContext.dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: secondaryTextStyle(size: 13)),
            8.height,
            Text(value, style: boldTextStyle(size: 13)),
          ],
        ),
      ),
    );
  }

  Widget _limitCard({
    required BuildContext buildContext,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: buildContext.cardColor,
        borderRadius: radius(12),
        border: Border.all(
            color: buildContext.dividerColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: boldTextStyle(size: 16),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          10.height,
          Text(
            title,
            style: secondaryTextStyle(size: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? startDate = _tryParseDate(widget.data.startAt);
    final DateTime? endDate = _tryParseDate(widget.data.endAt);
    final DateTime now = DateTime.now();
    final String subscriptionStatus = widget.data.status.validate();
    final bool isActive = subscriptionStatus == SUBSCRIPTION_STATUS_ACTIVE;
    final bool isCancelled =
        subscriptionStatus == SUBSCRIPTION_STATUS_CANCELLED;

    final int remainingDays =
        endDate != null ? (endDate.difference(now).inDays + 1) : 0;
    final bool showRemainingDays =
        endDate != null && remainingDays >= 0 && (isActive || isCancelled);

    final String amountText = (widget.data.amount ?? 0).toPriceFormat();
    final String planTypeText = widget.data.planType.validate();
    final String durationTypeText =
        widget.data.type.validate().capitalizeFirstLetter();
    final String durationValueText = widget.data.duration.validate();

    // Avoid empty metric values (otherwise only labels appear).
    final String planTypeValue =
        planTypeText.isEmpty ? '-' : planTypeText.capitalizeFirstLetter();

    final Color paymentStatusBg = Colors.green.withValues(alpha: 0.12);
    final Color paymentStatusText = Colors.green;
    final String statusTextLabel = isCancelled
        ? languages.cancelled
        : isActive
            ? languages.active
            : languages.inactive;
    final Color statusBg = isCancelled
        ? Colors.red.withValues(alpha: 0.12)
        : isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12);
    final Color statusText = isCancelled
        ? Colors.red
        : isActive
            ? Colors.green
            : Colors.grey;

    final String subtitle =
        '${appStore.userEmail.validate()} · ${widget.data.title.validate().capitalizeFirstLetter()}';

    final dateFormatter = DateFormat('MMMM d, yyyy · hh:mm a');

    final String startDateText =
        startDate != null ? dateFormatter.format(startDate) : '-';

    final String endDateText =
        endDate != null ? dateFormatter.format(endDate) : '-';

    final previousPlan =
        widget.data.otherDetail?.previousPlan?.validate() ?? '';
    final previousPrice =
        (widget.data.otherDetail?.previousPlanPrice?.toDouble() ?? 0);
    final String previousPlanPriceText = previousPrice.toPriceFormat();

    final String previousPlanDisplayName = previousPlan.isNotEmpty
        ? previousPlan.capitalizeEachWord()
        : '${languages.lblFree} ${languages.lblPlan}';

    final String upgradedPlanDisplayName =
        widget.data.title.validate().capitalizeEachWord();
    final String upgradedPriceFormatted =
        (widget.data.amount ?? 0).toPriceFormat();

    final String prorationTitle = languages.lblProrationDetails;
    final String planLimitsTitle = languages.lblPlanLimits;

    final planLimitation = widget.data.planLimitation;
    final bool showLimitedLimits =
        widget.data.planType.validate().toLowerCase() == 'limited' &&
            planLimitation != null;

    final String planDescription = widget.data.description.validate().trim();

    return Scaffold(
      appBar: appBarWidget(
        languages.lblSubscriptionDetails,
        backWidget: BackWidget(),
        elevation: 0,
        color: primaryColor,
        textColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.title.validate().capitalizeEachWord(),
                      style: boldTextStyle(size: 22)),
                  6.height,
                  Text(subtitle, style: secondaryTextStyle(size: 13)),
                  12.height,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(statusTextLabel,
                              style:
                                  boldTextStyle(size: 12, color: statusText)),
                        ),
                        if (widget.data.paymentMethod.validate().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: paymentStatusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              languages.lblPaymentVia(widget.data.paymentMethod
                                  .validate()
                                  .capitalizeFirstLetter()),
                              style: boldTextStyle(
                                  size: 12, color: paymentStatusText),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (planDescription.isNotEmpty) ...[
                    16.height,
                    Container(
                      width: context.width(),
                      padding: const EdgeInsets.all(14),
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: context.cardColor,
                        borderRadius: radius(12),
                        border:
                            Border.all(color: context.dividerColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(languages.hintDescription,
                              style: boldTextStyle(size: 14)),
                          14.height,
                          ReadMoreText(
                            planDescription,
                            style: secondaryTextStyle(size: 13),
                            trimMode: TrimMode.Line,
                            trimLines: 3,
                            trimCollapsedText: ' ${languages.lblReadMore}',
                            trimExpandedText: ' ${languages.lblReadLess}',
                            colorClickableText: context.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                  16.height,

                  // Top metrics card (Amount / Plan type / Duration / Remaining)
                  Container(
                    width: context.width(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(12),
                      border: Border.all(color: context.dividerColor, width: 1),
                      backgroundColor: context.cardColor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _metricColumn(
                            label: languages.lblAmount, value: amountText),
                        const VerticalDivider(width: 1),
                        _metricColumn(
                            label: languages.lblType, value: planTypeValue),
                        const VerticalDivider(width: 1),
                        _metricColumn(
                            label: languages.hintDuration,
                            value:
                                "${durationValueText} ${_durationTypeText(durationTypeText, int.parse(durationValueText))}"),
                        if (showRemainingDays) ...[
                          const VerticalDivider(width: 1),
                          _metricColumn(
                              label: languages.lblRemaining,
                              value:
                                  '$remainingDays ${remainingDays == 1 ? languages.lblDay : languages.lblDays}'),
                        ],
                      ],
                    ),
                  ),
                  16.height,

                  // Date range
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dateBox(
                            buildContext: context,
                            title: languages.lblStartDate,
                            value: startDateText),
                        10.width,
                        _dateBox(
                            buildContext: context,
                            title: languages.lblEndDate,
                            value: endDateText),
                      ],
                    ),
                  ),
                  16.height,

                  // Bottom cards (vertical)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.data.otherDetail != null) ...[
                        // Proration details
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: context.cardColor,
                            borderRadius: radius(12),
                            border: Border.all(
                                color: context.dividerColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prorationTitle,
                                  style: boldTextStyle(size: 14)),
                              14.height,
                              _infoRow(
                                label: languages.lblPurchaseType,
                                value: widget.data.otherDetail?.purchaseType
                                            ?.validate()
                                            .capitalizeFirstLetter()
                                            .isNotEmpty ==
                                        true
                                    ? widget.data.otherDetail!.purchaseType!
                                        .validate()
                                        .capitalizeFirstLetter()
                                    : '-',
                              ),
                              _infoRow(
                                label: languages.lblPreviousPlan,
                                value: widget.data.otherDetail?.previousPlan
                                            ?.validate()
                                            .capitalizeFirstLetter()
                                            .isNotEmpty ==
                                        true
                                    ? widget.data.otherDetail!.previousPlan!
                                        .validate()
                                        .capitalizeFirstLetter()
                                    : '-',
                              ),
                              _infoRow(
                                label: languages.lblPreviousPrice,
                                value: (widget.data.otherDetail
                                            ?.previousPlanPrice ??
                                        0)
                                    .toPriceFormat(),
                              ),
                              _infoRow(
                                label: languages.lblOriginalPrice,
                                value:
                                    (widget.data.otherDetail?.originalPrice ??
                                            0)
                                        .toPriceFormat(),
                              ),
                              _infoRow(
                                label: languages.lblCreditApplied,
                                value:
                                    (widget.data.otherDetail?.creditApplied ??
                                            0)
                                        .toPriceFormat(),
                              ),
                              _infoRow(
                                label: languages.lblPaidAmount,
                                value:
                                    (widget.data.otherDetail?.paidAmount ?? 0)
                                        .toPriceFormat(),
                              ),
                            ],
                          ),
                        ),
                        12.height,
                      ],
                      // Plan limits
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: boxDecorationWithRoundedCorners(
                          backgroundColor: context.cardColor,
                          borderRadius: radius(12),
                          border:
                              Border.all(color: context.dividerColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(planLimitsTitle,
                                style: boldTextStyle(size: 14)),
                            14.height,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _limitCard(
                                    buildContext: context,
                                    title: languages.lblFeaturedServices,
                                    value: showLimitedLimits
                                        ? (planLimitation
                                                    .featuredService?.limit ??
                                                '0')
                                            .validate()
                                        : languages.unlimited,
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: _limitCard(
                                    buildContext: context,
                                    title: languages.handyman,
                                    value: showLimitedLimits
                                        ? (planLimitation.handyman?.limit ??
                                                '0')
                                            .validate()
                                        : languages.unlimited,
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: _limitCard(
                                    buildContext: context,
                                    title: languages.lblServices,
                                    value: showLimitedLimits
                                        ? (planLimitation.service?.limit ?? '0')
                                            .validate()
                                        : languages.unlimited,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      12.height,
                      if (widget.data.otherDetail != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: boxDecorationWithRoundedCorners(
                            backgroundColor: context.cardColor,
                            borderRadius: radius(12),
                            border: Border.all(
                                color: context.dividerColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(languages.lblReason,
                                  style: boldTextStyle(size: 14)),
                              14.height,
                              Text(languages.lblPlanUpgradeProratedAdjustment,
                                  style: boldTextStyle(size: 14)),
                              14.height,
                              Text(
                                languages.lblSubscriptionPreviousPlanLine(
                                  previousPlanDisplayName,
                                  previousPlanPriceText,
                                ),
                                style: secondaryTextStyle(size: 13),
                              ),
                              10.height,
                              Text(
                                languages.lblSubscriptionUpgradedPlanLine(
                                  upgradedPlanDisplayName,
                                  upgradedPriceFormatted,
                                ),
                                style: secondaryTextStyle(size: 13),
                              ),
                            ],
                          ),
                        ),
                        12.height,
                      ],
                      AppButton(
                        onTap: _isDownloadingInvoice
                            ? null
                            : () => _downloadAndOpenInvoice(context),
                        text: languages.lblDownloadInvoice,
                        color: context.primaryColor,
                        width: context.width(),
                      ),
                      12.height,
                    ],
                  ),
                  20.height,
                ],
              ),
            ),
          ),
          LoaderWidget().center().visible(_isDownloadingInvoice),
        ],
      ),
    );
  }
}
