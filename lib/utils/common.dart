import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:handyman_provider_flutter/components/html_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/image_crop_screen.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/cached_image_widget.dart';
import '../models/provider_subscription_model.dart';
import '../screens/cash_management/cash_constant.dart';
import 'app_configuration.dart';
import 'colors.dart';

//region App Default Settings
void defaultSettings() {
  passwordLengthGlobal = 6;
  appButtonBackgroundColorGlobal = primaryColor;
  defaultRadius = 8;
  defaultAppButtonTextColorGlobal = Colors.white;
  defaultElevation = 0;
  defaultBlurRadius = 0;
  defaultSpreadRadius = 0;
  defaultAppButtonRadius = defaultRadius;
  defaultAppButtonElevation = 0;
  textBoldSizeGlobal = 14;
  textPrimarySizeGlobal = 14;
  textSecondarySizeGlobal = 12;
  defaultToastBackgroundColor = appStore.isDarkMode ? Colors.white : Colors.black;
  defaultToastTextColor = appStore.isDarkMode ? Colors.black : Colors.white;
}
//endregion

ThemeMode get appThemeMode => appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light;

Future<bool> get isIqonicProduct async => await getPackageName() == APP_PACKAGE_NAME;

bool get isRTL => RTL_LANGUAGES.contains(appStore.selectedLanguageCode);

bool isCommissionTypePercent(String? type) => type.validate() == COMMISSION_TYPE_PERCENT;

bool get isUserTypeHandyman => appStore.userType == USER_TYPE_HANDYMAN;

bool get isUserTypeProvider => appStore.userType == USER_TYPE_PROVIDER;

Future<void> setSaveSubscription({
  int? isSubscribe,
  required ProviderSubscriptionModel subscription,
}) async {
  await appStore.setPlanTitle(subscription.title ?? getStringAsync(PLAN_TITLE));
  await appStore.setIdentifier(subscription.identifier ?? getStringAsync(PLAN_IDENTIFIER));
  await appStore.setPlanEndDate(subscription.endAt ?? getStringAsync(PLAN_END_DATE));
  await appStore.setPlanSubscribeStatus(isSubscribe.validate() == 1);

  // Persist the full subscription locally (includes `status`) so the UI can
  // reliably show the correct state even when IAP is disabled.
  await appStore.setProviderCurrentSubscriptionPlan(subscription);

  if (appConfigurationStore.isInAppPurchaseEnable) {
    await appStore.setActiveRevenueCatIdentifier(
      subscription.activePlanRevenueCatIdentifier.isNotEmpty
          ? subscription.activePlanRevenueCatIdentifier
          : getStringAsync(ACTIVE_IN_APP_PURCHASE_IDENTIFIER),
    );
  }
}

int getRemainingPlanDays() {
  if (appStore.planEndDate.isNotEmpty) {
    final now = DateTime.now();
    final DateTime date = DateTime(now.year, now.month, now.day);
    final DateTime endAt = DateFormat(DATE_FORMAT_7).parse(appStore.planEndDate);

    return date.difference(endAt).inDays.abs();
  } else {
    return 0;
  }
}

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(
      id: 1,
      name: 'English',
      languageCode: 'en',
      fullLanguageCode: 'en-US',
      flag: 'assets/flag/ic_us.png',
    ),
    LanguageDataModel(
      id: 2,
      name: 'Hindi',
      languageCode: 'hi',
      fullLanguageCode: 'hi-IN',
      flag: 'assets/flag/ic_india.png',
    ),
    LanguageDataModel(
      id: 3,
      name: 'Arabic',
      languageCode: 'ar',
      fullLanguageCode: 'ar-AR',
      flag: 'assets/flag/ic_ar.png',
    ),
    LanguageDataModel(
      id: 4,
      name: 'French',
      languageCode: 'fr',
      fullLanguageCode: 'fr-FR',
      flag: 'assets/flag/ic_fr.png',
    ),
    LanguageDataModel(
      id: 5,
      name: 'German',
      languageCode: 'de',
      fullLanguageCode: 'de-DE',
      flag: 'assets/flag/ic_de.png',
    ),
    LanguageDataModel(
      id: 6,
      name: 'Dutch',
      languageCode: 'nl',
      fullLanguageCode: 'nl-NL',
      flag: 'assets/flag/ic_nl.png',
    ),
    LanguageDataModel(
      id: 7,
      name: 'Italian',
      languageCode: 'it',
      fullLanguageCode: 'it-IT',
      flag: 'assets/flag/ic_it.png',
    ),
  ];

  /*if (getStringAsync(SERVER_LANGUAGES).isNotEmpty) {
    Iterable it = jsonDecode(getStringAsync(SERVER_LANGUAGES));
    var res = it.map((e) => LanguageOption.fromJson(e)).toList();

    localeLanguageList.clear();

    res.forEach((element) {
      localeLanguageList.add(LanguageDataModel(languageCode: element.id.validate().toString(), flag: element.flagImage, name: element.title));
    });

    return localeLanguageList;
  } else {
    return [
      LanguageDataModel(id: 1, name: 'English', languageCode: 'en', fullLanguageCode: 'en-US', flag: 'assets/flag/ic_us.png'),
      LanguageDataModel(id: 2, name: 'Hindi', languageCode: 'hi', fullLanguageCode: 'hi-IN', flag: 'assets/flag/ic_india.png'),
      LanguageDataModel(id: 3, name: 'Arabic', languageCode: 'ar', fullLanguageCode: 'ar-AR', flag: 'assets/flag/ic_ar.png'),
      LanguageDataModel(id: 4, name: 'French', languageCode: 'fr', fullLanguageCode: 'fr-FR', flag: 'assets/flag/ic_fr.png'),
      LanguageDataModel(id: 5, name: 'German', languageCode: 'de', fullLanguageCode: 'de-DE', flag: 'assets/flag/ic_de.png'),
    ];
  }*/
}

InputDecoration inputDecoration(
  BuildContext context, {
  Widget? prefixIcon,
  Widget? prefix,
  String? hint,
  String? hintText,
  Color? fillColor,
  String? counterText,
  double? borderRadius,
  bool? counter,
  bool showLabel = true,
}) {
  return InputDecoration(
    contentPadding: const EdgeInsets.only(left: 12, bottom: 10, top: 10, right: 10),
    labelText: showLabel ? hint : "",
    labelStyle: secondaryTextStyle(),
    hintText: hintText,
    hintStyle: secondaryTextStyle(),
    alignLabelWithHint: true,
    counterText: counter == false ? "" : counterText,
    prefixIcon: prefixIcon,
    prefix: prefix,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: Colors.red, width: 0.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: Colors.red),
    ),
    errorMaxLines: 2,
    border: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
    ),
    errorStyle: primaryTextStyle(color: Colors.red, size: 10),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius(borderRadius ?? defaultRadius),
      borderSide: const BorderSide(color: primaryColor, width: 0.0),
    ),
    filled: true,
    fillColor: fillColor ?? context.cardColor,
  );
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

String formatDate(
  String? dateTime, {
  String format = DATE_FORMAT_1,
  bool isFromMicrosecondsSinceEpoch = false,
  bool isLanguageNeeded = true,
  bool isTime = false,
  bool showDateWithTime = false,
}) {
  final parsedDateTime = isFromMicrosecondsSinceEpoch ? DateTime.fromMicrosecondsSinceEpoch(dateTime.validate().toInt() * 1000) : DateTime.parse(dateTime.validate());
  if (isTime) {
    return DateFormat(
      getStringAsync(TIME_FORMAT),
      isLanguageNeeded ? appStore.selectedLanguageCode : null,
    ).format(parsedDateTime);
  } else {
    if (getStringAsync(DATE_FORMAT).validate().contains('dS')) {
      final int day = parsedDateTime.day;
      if (DateFormat(
        getStringAsync(DATE_FORMAT),
        isLanguageNeeded ? appStore.selectedLanguageCode : null,
      ).format(parsedDateTime).contains('$day')) {
        return DateFormat(
          '${getStringAsync(DATE_FORMAT).validate().replaceAll('S', '')}${showDateWithTime ? ' ${getStringAsync(TIME_FORMAT)}' : ''}',
          isLanguageNeeded ? appStore.selectedLanguageCode : null,
        ).format(parsedDateTime).replaceFirst('$day', addOrdinalSuffix(day));
      }
    }
    return DateFormat(
      '${getStringAsync(DATE_FORMAT).validate()}${showDateWithTime ? ' ${getStringAsync(TIME_FORMAT)}' : ''}',
      isLanguageNeeded ? appStore.selectedLanguageCode : null,
    ).format(parsedDateTime);
  }
}

String getTime(
  String? time, {
  String format = DISPLAY_TIME_FORMAT,
  bool isFromMicrosecondsSinceEpoch = false,
  bool isLanguageNeeded = true,
}) {
  final parsedTime = isFromMicrosecondsSinceEpoch ? DateTime.fromMicrosecondsSinceEpoch(time!.validate().toInt() * 1000) : DateTime.parse(time.validate());
  return DateFormat(
    getStringAsync(TIME_FORMAT),
    isLanguageNeeded ? appStore.selectedLanguageCode : null,
  ).format(parsedTime);
}

String getSlotWithDate({required String date, required String slotTime}) {
  final DateTime originalDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
  final DateTime newTime = DateFormat('HH:mm:ss').parse(slotTime);
  final DateTime newDateTime = DateTime(
    originalDateTime.year,
    originalDateTime.month,
    originalDateTime.day,
    newTime.hour,
    newTime.minute,
    newTime.second,
  );
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime);
}

String getDateFormat(String phpFormat) {
  final formatMapping = {
    'Y': 'yyyy',
    'm': 'MM',
    'd': 'dd',
    'j': 'd',
    'S': 'S',
    'M': 'MMM',
    'F': 'MMMM',
    'l': 'EEEE',
    'D': 'EEE',
    'H': 'HH',
    'i': 'mm',
    's': 'ss',
    'A': 'a',
    'T': 'z',
    'v': 'S',
    'U': 'y-MM-ddTHH:mm:ssZ',
    'u': 'y-MM-ddTHH:mm:ss.SSSZ',
    'G': 'H',
    'B': 'EEE, d MMM y HH:mm:ss Z',
  };

  String dartFormat = phpFormat.replaceAllMapped(
    RegExp('[YmjdSFMlDHisaTvGuB]'),
    (match) => formatMapping[match.group(0)] ?? match.group(0).validate(),
  );

  dartFormat = dartFormat.replaceAllMapped(
    RegExp(r"\\(.)"),
    (match) => match.group(1) ?? '',
  );

  return dartFormat;
}

String addOrdinalSuffix(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String getDisplayTimeFormat(String phpFormat) {
  switch (phpFormat) {
    case 'H:i':
      return 'HH:mm';
    case 'H:i:s':
      return 'HH:mm:ss';
    case 'g:i A':
      return 'h:mm a';
    case 'H:i:s T':
      return 'HH:mm:ss z';
    case 'H:i:s.v':
      return 'HH:mm:ss.S';
    case 'U':
      return 'HH:mm:ssZ';                 
    case 'u':
      return 'HH:mm:ss.SSSZ';
    case 'G.i':
      return 'H.mm';
    case '@BMT':
      return 'HH:mm:ss Z';
    default:
      return DISPLAY_TIME_FORMAT; // Return the same format if not found in the mapping
  }
}

Future<void> commonLaunchUrl(
  String url, {
  LaunchMode launchMode = LaunchMode.inAppWebView,
}) async {
  await launchUrl(Uri.parse(url), mode: launchMode).catchError((e) {
    toast('Invalid URL: $url');
    throw e;
  });
}

void viewFiles(String url) {
  if (url.isNotEmpty) {
    commonLaunchUrl(url, launchMode: LaunchMode.externalApplication);
  }
}

void launchCall(String? url) {
  if (url.validate().isNotEmpty) {
    if (isIOS) {
      commonLaunchUrl(
        'tel://${url!}',
        launchMode: LaunchMode.externalApplication,
      );
    } else {
      commonLaunchUrl(
        'tel:${url!}',
        launchMode: LaunchMode.externalApplication,
      );
    }
  }
}

void launchMail(String? url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl(
      'mailto:${url!}',
      launchMode: LaunchMode.externalApplication,
    );
  }
}

void launchMap(String? url) {
  if (url.validate().isNotEmpty) {
    commonLaunchUrl(
      GOOGLE_MAP_PREFIX + Uri.encodeFull(url!),
      launchMode: LaunchMode.externalApplication,
    );
  }
}

void launchMapFromLatLng({required double latitude, required double longitude}) {
  final String query = "${latitude.toString()},${longitude.toString()}";
  commonLaunchUrl(GOOGLE_MAP_PREFIX + Uri.encodeFull(query), launchMode: LaunchMode.externalApplication);
}

void launchUrlCustomTab(String? url) {
  if (url.validate().isNotEmpty) {
    custom_tabs.launchUrl(
      Uri.parse(url!),
      customTabsOptions: custom_tabs.CustomTabsOptions(
        showTitle: true,
        colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
          toolbarColor: primaryColor,
        ),
      ),
      safariVCOptions: const custom_tabs.SafariViewControllerOptions(
        preferredBarTintColor: primaryColor,
        preferredControlTintColor: Colors.white,
        barCollapsingEnabled: true,
        entersReaderIfAvailable: true,
        dismissButtonStyle: custom_tabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }
}

// Logic For Calculate Time
String calculateTimer(int secTime) {
  //int hour = 0, minute = 0, seconds = 0;
  int hour = 0, minute = 0;

  hour = secTime ~/ 3600;

  minute = (secTime - hour * 3600) ~/ 60;

  //seconds = secTime - (hour * 3600) - (minute * 60);

  final String hourLeft = hour.toString().length < 2 ? "0$hour" : hour.toString();

  final String minuteLeft = minute.toString().length < 2 ? "0$minute" : minute.toString();

  final String minutes = minuteLeft == '00' ? '01' : minuteLeft;

  final String result = "$hourLeft:$minutes";

  return result;
}

Widget subSubscriptionPlanWidget({
  Color? planBgColor,
  String? planTitle,
  String? planSubtitle,
  String? planButtonTxt,
  Function? onTap,
  Color? btnColor,
  IconData? icon,
}) {
  return Container(
    color: planBgColor,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(icon != null)...[
          Icon(icon, size: 24, color: Colors.grey),
          12.width,
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(planTitle.validate().isNotEmpty)...[
              Text(planTitle.validate(), style: boldTextStyle()),
              8.height,
            ],
            if(planSubtitle.validate().isNotEmpty)...[
              Text(planSubtitle.validate(), style: secondaryTextStyle()),
            ],
          ],
        ).flexible(),
        if(planButtonTxt.validate().isNotEmpty)...[
          8.width,
          AppButton(
            child: Text(
              planButtonTxt.validate(),
              style: boldTextStyle(color: white),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: btnColor,
            elevation: 0,
            onTap: () {
              onTap?.call();
            },
          ),
        ]
      ],
    ),
  );
}

Brightness getStatusBrightness({required bool val}) {
  return val ? Brightness.light : Brightness.dark;
}

String getPaymentStatusFilterText(String? status) {
  if (status!.isEmpty) {
    return languages.pending;
  } else if (status == PAID || status == PENDING_BY_ADMIN) {
    return languages.paid;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
    return languages.advancePaid;
  } else if (status == PENDING) {
    return languages.pending;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_REFUND) {
    return languages.advancedRefund;
  } else {
    return "";
  }
}

String getPaymentStatusText(String? status, String? method) {
  if (status!.isEmpty) {
    return languages.pending;
  } else if (status == PAID || status == PENDING_BY_ADMINS) {
    return languages.paid;
  } else if (status == PAYMENT_STATUS_ADVANCE) {
    return languages.advancePaid;
  } else if (status == PENDING && method == PAYMENT_METHOD_COD) {
    return languages.pendingApproval;
  } else if (status == BOOKING_STATUS_PENDING_APPROVAL && method.validate().toLowerCase() == PAYMENT_METHOD_COD) {
    return languages.pendingApproval;
  } else if (status == PENDING) {
    return languages.pending;
  } else if (status == SERVICE_PAYMENT_STATUS_ADVANCE_REFUND) {
    return languages.cancelled;
  } else {
    return "";
  }
}

String getReasonText(BuildContext context, String val) {
  if (val == BookingStatusKeys.cancelled) {
    return languages.lblReasonCancelling;
  } else if (val == BookingStatusKeys.rejected) {
    return languages.lblReasonRejecting;
  } else if (val == BookingStatusKeys.failed) {
    return languages.lblFailed;
  }
  return '';
}

void checkIfLink(BuildContext context, String value, {String? title}) {
  final String temp = parseHtmlString(value.validate());
  if (value.validate().isEmpty) return;

  if (temp.startsWith("https") || temp.startsWith("http")) {
    launchUrlCustomTab(temp.validate());
  } else if (temp.validateEmail()) {
    launchMail(temp);
  } else if (temp.validatePhone() || temp.startsWith('+')) {
    launchCall(temp);
  } else {
    HtmlWidget(postContent: value, title: title).launch(context);
  }
}

String buildPaymentStatusWithMethod(String status, String method) {
  return '${getPaymentStatusText(status, method)}${(status == BOOKING_STATUS_PAID || status == PENDING_BY_ADMINS) ? ' ${languages.by} $method' : ''}';
}

Color getRatingBarColor(int rating, {bool showRedForZeroRating = false}) {
  if (rating == 1 || rating == 2) {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  } else if (rating == 3) {
    return const Color(0xFFff6200);
  } else if (rating == 4 || rating == 5) {
    return const Color(0xFF73CB92);
  } else {
    return showRedForZeroRating ? showRedForZeroRatingColor : ratingBarColor;
  }
}

String formatBookingDate(
  String? dateTime, {
  String format = DATE_FORMAT_1,
  bool isFromMicrosecondsSinceEpoch = false,
  bool isLanguageNeeded = true,
  bool isTime = false,
  bool showDateWithTime = false,
}) {
  if (isFromMicrosecondsSinceEpoch) {
    return DateFormat(format).format(
      DateTime.fromMicrosecondsSinceEpoch(
        dateTime.validate().toInt() * 1000,
      ),
    );
  } else {
    return DateFormat(format).format(DateTime.parse(dateTime.validate()));
  }
}

void ifNotTester(BuildContext context, VoidCallback callback) {
  if (!appStore.isTester) {
    callback.call();
  } else {
    toast(languages.lblUnAuthorized);
  }
}

Future<void> checkAndPerformInAppUpdate() async {
  // Respect user preference for optional updates.
  if (!getBoolAsync(UPDATE_NOTIFY, defaultValue: true)) return;

  if (Platform.isIOS) {
    await _checkAndOpenIosStoreIfUpdateAvailable();
    return;
  }

  if (!Platform.isAndroid) return;

  try {
    final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) return;

    if (updateInfo.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
      return;
    }

    if (updateInfo.flexibleUpdateAllowed) {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    }
  } on PlatformException catch (e) {
    log('In-app update failed: ${e.message}');
  } catch (e) {
    log('In-app update failed: $e');
  }
}

Future<void> _checkAndOpenIosStoreIfUpdateAvailable() async {
  try {
    final packageInfo = await getPackageInfo();
    final String currentVersion = packageInfo.versionName.validate();
    final String bundleId = packageInfo.packageName.validate();
    if (bundleId.isEmpty || currentVersion.isEmpty) return;

    final Uri uri = Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId');
    final response = await http.get(uri);
    if (response.statusCode != 200) return;

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> results = (data['results'] as List<dynamic>?) ?? const [];
    if (results.isEmpty) return;

    final Map<String, dynamic> appData = results.first as Map<String, dynamic>;
    final String storeVersion = (appData['version'] as String?)?.trim() ?? '';
    if (!_isVersionNewer(storeVersion, currentVersion)) return;

    String appStoreUrl = getStringAsync(PROVIDER_APPSTORE_URL).trim();
    appStoreUrl = appStoreUrl.isNotEmpty ? appStoreUrl : ((appData['trackViewUrl'] as String?) ?? '').trim();
    if (appStoreUrl.isEmpty) return;

    await commonLaunchUrl(appStoreUrl, launchMode: LaunchMode.externalApplication);
  } catch (e) {
    log('iOS update check failed: $e');
  }
}

bool _isVersionNewer(String storeVersion, String currentVersion) {
  List<int> parseVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  final List<int> store = parseVersion(storeVersion);
  final List<int> current = parseVersion(currentVersion);
  final int maxLength = store.length > current.length ? store.length : current.length;

  for (int i = 0; i < maxLength; i++) {
    final int storePart = i < store.length ? store[i] : 0;
    final int currentPart = i < current.length ? current[i] : 0;
    if (storePart > currentPart) return true;
    if (storePart < currentPart) return false;
  }
  return false;
}

Widget mobileNumberInfoWidget(BuildContext context) {
  return RichTextWidget(
    list: [
      TextSpan(
        text: languages.lblAddYourCountryCode,
        style: secondaryTextStyle(),
      ),
      TextSpan(text: ' "91-", "236-" ', style: boldTextStyle(size: 12)),
      TextSpan(
        text: ' (${languages.lblHelp})',
        style: boldTextStyle(size: 12, color: primaryColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrlCustomTab("https://countrycode.org/");
          },
      ),
    ],
  );
}

Future<List<File>> getMultipleImageSource({bool isCamera = true}) async {
  final pickedImage = await ImagePicker().pickMultiImage();
  return pickedImage.map((e) => File(e.path)).toList();
}

Future<File?> getCameraImage({
  bool isCamera = true,
  bool isCrop = false,
  required BuildContext context,
}) async {
  final pickedImage = await ImagePicker().pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
  );

  if (pickedImage == null) {
    return null; // Return null if no image is selected
  }

  final File imageFile = File(pickedImage.path);

  // Crop the image only if isCrop is true
  if (isCrop) {
    final File? croppedImage = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => CropImageScreen(
          key: ValueKey(imageFile.path),
          imageFile: imageFile,
        ),
      ),
    );

    return croppedImage; // Return cropped image
  }

  return imageFile; // Return original image if cropping is not required
}

String getDateInString({required DateTimeRange dateTime, String? format}) {
  if (dateTime.start.isToday) {
    return languages.today;
  } else if (dateTime.start.isTomorrow)
    return languages.tomorrow;
  else if (dateTime.start.isYesterday)
    return languages.yesterday;
  else {
    return "${formatDate(dateTime.start.toString(), format: format.validate())} - ${formatDate(dateTime.end.toString(), format: format.validate())}'s";
  }
}

String convertToHourMinute(String timeStr) {
  if (timeStr.isEmpty) {
    return ''; // Handle empty time string
  }

  // Normalize time string to always have two digits for hours
  final List<String> parts = timeStr.split(':');
  final int hours = int.parse(parts[0]) % 24; // Ensure hours are within 24 hours
  final int minutes = int.parse(parts[1]);

  // Construct the resulting string
  String result = '';
  if (hours > 0) {
    result += '${hours}${languages.lblHr}';
  }
  if (minutes > 0) {
    result = (result.validate().isNotEmpty) ? '$result $minutes ${languages.min}' : '$minutes ${languages.min}';
  }
  return result;
}

Future<List<File>> pickFiles({
  FileType type = FileType.any,
  List<String> allowedExtensions = const [],
  int maxFileSizeMB = 5,
  bool allowMultiple = false,
}) async {
  final List<File> _filePath = [];
  try {
    final FilePickerResult? filePickerResult = await FilePicker.pickFiles(
      type: type,
      allowMultiple: allowMultiple,
      withData: Platform.isAndroid ? false : true,
      allowedExtensions: allowedExtensions,
      onFileLoading: (FilePickerStatus status) => print(status),
    );
    if (filePickerResult != null) {
      if (Platform.isAndroid) {
        // For Android, check file size and use the PlatformFile directly
        for (final PlatformFile file in filePickerResult.files) {
          if (file.size <= maxFileSizeMB * 1024 * 1024) {
            _filePath.add(File(file.path!));
          } else {
            // File size exceeds the limit
            toast('File size should be less than $maxFileSizeMB MB');
          }
        }
      } else {
        final Directory cacheDir = await getTemporaryDirectory();
        for (final PlatformFile file in filePickerResult.files) {
          if (file.bytes != null && file.size <= maxFileSizeMB * 1024 * 1024) {
            final String filePath = '${cacheDir.path}/${file.name}';
            final File cacheFile = File(filePath);
            await cacheFile.writeAsBytes(file.bytes!.toList());
            _filePath.add(cacheFile);
          } else {
            // File size exceeds the limit
            toast('File size should be less than $maxFileSizeMB MB');
          }
        }
      }
    }
  } on PlatformException catch (e) {
    print('Unsupported operation$e');
  } catch (e) {
    print(e);
  }
  return _filePath;
}

String bankAccountWidget(String accountNo) {
  if (accountNo.length <= 4) {
    return accountNo;
  }
  final obscuredPart = '*' * (accountNo.length - 4);
  final visiblePart = accountNo.substring(accountNo.length - 4);
  return obscuredPart + visiblePart;
}

class OptionListWidget extends StatelessWidget {
  final List<OptionModel> optionList;

  const OptionListWidget({super.key, required this.optionList});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        optionList.length,
        (index) => Row(
          children: [
            InkWell(
              onTap: optionList[index].onTap,
              child: Text(
                optionList[index].title,
                style: secondaryTextStyle(
                  color: primaryColor,
                  size: 12,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            8.width,
            Text("|", style: secondaryTextStyle()).visible(optionList.length != index + 1),
            8.width,
          ],
        ),
      ),
    );
  }
}

class OptionModel {
  final String title;
  final Function()? onTap;

  OptionModel({required this.title, required this.onTap});
}

void share({required String url, required BuildContext context}) {
  if (Platform.isIOS) {
    try {
      final box = context.findRenderObject() as RenderBox?;

      SharePlus.instance.share(
        ShareParams(
          text: url,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      log('Failed to share: $e');
    }
  } else {
    SharePlus.instance.share(ShareParams(text: url));
  }
}

//Multi Language Component
class MultiLanguageWidget extends StatelessWidget {
  final Function(LanguageDataModel languageDetails) onTap;
  final String selectedLanguageCode;

  const MultiLanguageWidget({
    super.key,
    required this.onTap,
    required this.selectedLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    final List<LanguageDataModel> availableLanguages = languageList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: context.scaffoldBackgroundColor),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            availableLanguages.length,
            (index) {
              final LanguageDataModel languageData = availableLanguages[index];
              final bool isFirstLanguage =
                  availableLanguages.first.languageCode ==
                      languageData.languageCode;

              return Padding(
                padding: EdgeInsetsDirectional.only(
                  start: isFirstLanguage ? 16 : 0,
                  end: 8,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    onTap(languageData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedLanguageCode == languageData.languageCode ? primaryColor : context.scaffoldBackgroundColor,
                    elevation: 0,
                    shadowColor: transparentColor,
                    overlayColor: transparentColor,
                    side: BorderSide(color: context.iconColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CachedImageWidget(
                        url: languageData.flag.validate(),
                        height: 16,
                      ),
                      4.width,
                      Text(
                        languageData.name.validate().toUpperCase(),
                        style: secondaryTextStyle(
                          color: selectedLanguageCode == languageData.languageCode ? white : textSecondaryColorGlobal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

SystemUiOverlayStyle defaultSystemUiOverlayStyle(
  BuildContext context, {
  Color? color,
  Brightness? statusBarIconBrightness,
}) {
  return SystemUiOverlayStyle(
    statusBarColor: color ?? context.scaffoldBackgroundColor,
    statusBarIconBrightness: statusBarIconBrightness ?? (appStore.isDarkMode ? Brightness.light : Brightness.dark),
    statusBarBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark,
  );
}

List<LanguageDataModel> filterDefaultLanguages(List<String> defaultLanguages) {
  final filteredList = languageList().where((lang) => defaultLanguages.contains(lang.languageCode)).toList();
  if (filteredList.isNotEmpty) {
    filteredList.sort((a, b) {
      if (a.languageCode == 'pt') return -1; // pt should be first
      if (b.languageCode == 'pt') return 1;
      return 0; // keep other items in their original order
    });
  }
  return filteredList.isNotEmpty ? filteredList : languageList();
}

String formatShopTimeRange(String? startTime, String? endTime) {
  return '${formatDate(startTime, isTime: true)} - ${formatDate(endTime, isTime: true)}';
}