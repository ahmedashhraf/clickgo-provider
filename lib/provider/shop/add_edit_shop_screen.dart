// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/components/custom_image_picker.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/city_list_response.dart';
import 'package:handyman_provider_flutter/models/country_list_response.dart';
import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/shop_model.dart';
import 'package:handyman_provider_flutter/models/static_data_model.dart';
import 'package:handyman_provider_flutter/models/state_list_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/services/phone_number_service.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/extensions/string_extension.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

class AddEditShopScreen extends StatefulWidget {
  final ShopModel? shop;

  const AddEditShopScreen({Key? key, this.shop}) : super(key: key);

  @override
  State<AddEditShopScreen> createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends State<AddEditShopScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isUpdate = false;

  bool isLastPage = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController regNoController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController shopStartTimeController = TextEditingController();
  TextEditingController shopEndTimeController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  List<CountryListResponse> countryList = [];
  List<StateListResponse> stateList = [];
  List<CityListResponse> cityList = [];
  List<ServiceData> serviceList = [];
  CountryListResponse? selectedCountry;
  StateListResponse? selectedState;
  CityListResponse? selectedCity;
  List<String> selectedImages = [];
  String shopStatus = ACTIVE;
  List<StaticDataModel> statusListStaticData = [
    StaticDataModel(key: ACTIVE, value: languages.active),
    StaticDataModel(key: INACTIVE, value: languages.inactive),
  ];
  StaticDataModel? shopStatusModel;

  int servicePage = 1;

  ShopModel? shopDetails;
  Country selectedCountryPicker = defaultCountry();
  final FocusNode shopNameFocus = FocusNode();
  final FocusNode countryFocus = FocusNode();
  final FocusNode stateFocus = FocusNode();
  final FocusNode cityFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode registrationNumberFocus = FocusNode();
  final FocusNode latitudeFocus = FocusNode();
  final FocusNode longitudeFocus = FocusNode();
  final FocusNode shopStartTimeFocus = FocusNode();
  final FocusNode shopEndTimeFocus = FocusNode();
  final FocusNode contactNumberFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  ValueNotifier _valueNotifier = ValueNotifier(true);
  final PhoneNumberService _phoneNumberService = const PhoneNumberService();

  // Multi-language support
  Map<String, Map<String, String>> shopTranslations = {};
  String shopEnName = '';
  String selectedFormLanguageCode = DEFAULT_LANGUAGE;
  UniqueKey shopFormKey = UniqueKey();

  String formatTime24(TimeOfDay t) =>
      t.hour.toString().padLeft(2, '0') +
      ':' +
      t.minute.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    selectedFormLanguageCode =
        appStore.selectedLanguage.languageCode.validate().isNotEmpty
            ? appStore.selectedLanguage.languageCode.validate()
            : DEFAULT_LANGUAGE;

    isUpdate = widget.shop != null;
    shopStatusModel = statusListStaticData.first;
    if (isUpdate) {
      await getShopDetails();
    }
    await Future.wait(
      [
        getCountries(),
        getServices(shopId: isUpdate ? widget.shop!.id : 0),
      ],
    );
  }

  Future<void> getCountries() async {
    appStore.setLoading(true);
    await getCountryList().then((value) async {
      countryList.clear();
      countryList.addAll(value);
      if (isUpdate && shopDetails!.countryId.validate() > 0) {
        if (countryList.isNotEmpty && selectedCountry == null && isUpdate) {
          if (countryList
              .any((element) => element.id == shopDetails!.countryId)) {
            selectedCountry = countryList
                .firstWhere((element) => element.id == shopDetails!.countryId);
            getStates(selectedCountry!.id.validate()).then(
              (value) {
                if (stateList.isNotEmpty && selectedState == null && isUpdate) {
                  if (stateList
                      .any((element) => element.id == shopDetails!.stateId)) {
                    selectedState = stateList.firstWhere(
                        (element) => element.id == shopDetails!.stateId);
                    getCities(selectedState!.id.validate()).then(
                      (value) {
                        if (cityList.isNotEmpty &&
                            selectedCity == null &&
                            isUpdate) {
                          if (cityList.any(
                              (element) => element.id == shopDetails!.cityId)) {
                            selectedCity = cityList.firstWhere(
                                (element) => element.id == shopDetails!.cityId);
                          }
                        }
                      },
                    );
                  }
                }
              },
            );
          }
        }
      }
      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getStates(int countryId) async {
    if (countryId == 0) return;
    appStore.setLoading(true);
    await getStateList({'country_id': countryId})
        .then((value) async {
          stateList.clear();
          stateList.addAll(value);
          setState(() {});
        })
        .whenComplete(() => appStore.setLoading(false))
        .catchError((e) {
          toast('$e', print: true);
        });
  }

  Future<void> getCities(int stateId) async {
    if (stateId == 0) return;
    appStore.setLoading(true);

    await getCityList({'state_id': stateId}).then((value) async {
      cityList.clear();
      cityList.addAll(value);

      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    }).whenComplete(() => appStore.setLoading(false));
  }

  Future<void> getServices({int shopId = 0}) async {
    appStore.setLoading(true);
    await getSearchList(
      servicePage,
      providerId: appStore.userId.validate(),
      perPage: shopId > 0 ? PER_PAGE_ITEM_ALL : 10,
      status: VISIT_OPTION_SHOP,
      services: serviceList,
      shopId: shopId > 0 ? shopId.toString() : '',
      lastPageCallback: (isLast) {
        isLastPage = isLast;
      },
    ).then(
      (value) {
        if (isUpdate && shopId > 0) {
          final Set<String> selectedIds =
              shopDetails?.services.map((e) => e.id.toString()).toSet() ?? {};
          for (var s in serviceList) {
            if (selectedIds.contains(s.id.toString())) {
              s.isSelected = true;
            }
          }
        }

        setState(() {});
      },
    ).catchError((e) {
      toast('$e', print: true);
    }).whenComplete(() => appStore.setLoading(false));

    // Ensure at least 5 services available initially in edit mode by fetching
    // additional unselected services from the general list (without shopId)
    // if the first fetch returned only a few selected items.
    if (isUpdate && shopId > 0 && servicePage == 1 && serviceList.length < 5) {
      appStore.setLoading(true);
      await getSearchList(
        servicePage,
        providerId: appStore.userId.validate(),
        perPage: 10,
        status: VISIT_OPTION_SHOP,
        services: serviceList,
        shopId: '',
        lastPageCallback: (isLast) {
          isLastPage = isLast;
        },
      ).then((value) {
        // Re-apply selection flags based on shop details (robust string compare)
        final Set<String> selectedIds =
            shopDetails?.services.map((e) => e.id.toString()).toSet() ?? {};
        for (var s in serviceList) {
          s.isSelected = selectedIds.contains(s.id.toString());
        }

        // Deduplicate by id while preserving order
        final Map<int?, ServiceData> byId = {};
        final List<ServiceData> deduped = [];
        for (final s in serviceList) {
          if (!byId.containsKey(s.id)) {
            byId[s.id] = s;
            deduped.add(s);
          }
        }
        serviceList
          ..clear()
          ..addAll(deduped);

        setState(() {});
      }).catchError((e) {
        toast('$e', print: true);
      }).whenComplete(() => appStore.setLoading(false));
    }
  }

  Future<void> getShopDetails() async {
    appStore.setLoading(true);

    await getShopDetail(widget.shop!.id)
        .then(
          (value) async {
            shopDetails = value.shopDetail;
            nameController.text = shopDetails!.name;
            shopEnName = shopDetails!.name;

            // Load existing translations from API response
            if (shopDetails!.translations != null &&
                shopDetails!.translations!.isNotEmpty) {
              shopTranslations = Map.from(shopDetails!.translations!);
              // English is stored separately — extract and remove from map
              if (shopTranslations.containsKey(DEFAULT_LANGUAGE)) {
                shopEnName = shopTranslations[DEFAULT_LANGUAGE]?['shop_name'] ??
                    shopDetails!.name;
                shopTranslations.remove(DEFAULT_LANGUAGE);
              }
              // Show the name for the currently selected language
              final currentLang = selectedFormLanguageCode;
              if (currentLang != DEFAULT_LANGUAGE &&
                  shopTranslations.containsKey(currentLang)) {
                nameController.text =
                    shopTranslations[currentLang]?['shop_name'] ?? shopEnName;
              } else {
                nameController.text = shopEnName;
              }
            }

            addressController.text = shopDetails!.address;
            regNoController.text = shopDetails!.registrationNumber.validate();
            latitudeController.text =
                shopDetails!.latitude.validate().toString();
            longitudeController.text =
                shopDetails!.longitude.validate().toString();
            emailController.text = shopDetails!.email.validate();
            final parsedPhone = _phoneNumberService
                .parseStoredContact(shopDetails!.contactNumber.validate());
            selectedCountryPicker = parsedPhone.country ??
                Country.from(json: defaultCountry().toJson());
            mobileController.text = parsedPhone.localNumber;

            selectedImages = List<String>.from(shopDetails!.shopImage);
            shopStatus = shopDetails!.isActive ? ACTIVE : INACTIVE;
            shopStatusModel = shopStatus == ACTIVE ? statusListStaticData.first : statusListStaticData[1];

            setState(() {});
          },
        )
        .whenComplete(() => appStore.setLoading(false))
        .catchError((e) {
          toast('$e', print: true);
        });
  }

  Future<void> onNextPage() async {
    if (appStore.isLoading) return;
    if (!isLastPage) {
      servicePage++;
      await getServices();
    }
  }

  Future<void> onBackToFirstPage() async {
    if (appStore.isLoading) return;
    setState(() {
      servicePage = 1;
      isLastPage = false;
    });
    await getServices(shopId: isUpdate ? widget.shop!.id : 0);
  }

  //region Multi-Language Methods

  void updateShopTranslation() {
    final langCode = selectedFormLanguageCode;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      shopTranslations.remove(langCode);
    } else if (langCode != DEFAULT_LANGUAGE) {
      shopTranslations[langCode] = {'shop_name': name};
    } else {
      shopEnName = name;
    }
  }

  void getShopTranslation() {
    final langCode = selectedFormLanguageCode;
    if (langCode == DEFAULT_LANGUAGE) {
      nameController.text = shopEnName;
    } else {
      nameController.text = shopTranslations[langCode]?['shop_name'] ?? '';
    }
    setState(() {});
  }

  String _resolvedEnglishShopName() {
    final String englishName = shopEnName.trim();
    if (englishName.isNotEmpty) return englishName;

    final String currentName = nameController.text.trim();
    if (currentName.isNotEmpty) return currentName;

    final String selectedLangName =
        shopTranslations[selectedFormLanguageCode]?['shop_name']?.trim() ?? '';
    if (selectedLangName.isNotEmpty) return selectedLangName;

    for (final Map<String, String> translation in shopTranslations.values) {
      final String fallbackName = (translation['shop_name'] ?? '').trim();
      if (fallbackName.isNotEmpty) return fallbackName;
    }

    return '';
  }

  //endregion

  Future<void> saveShop() async {
    if (appStore.isLoading) return;

    if (!_formKey.currentState!.validate()) {
      if (_autoValidateMode != AutovalidateMode.onUserInteraction) {
        setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      }
      return;
    }

    hideKeyboard(context);
    _formKey.currentState!.save();
    appStore.setLoading(true);

    updateShopTranslation();
    shopTranslations.remove(DEFAULT_LANGUAGE);

    final Map<String, dynamic> fields = {
      ShopKeys.providerId: appStore.userId.toString(),
      ShopKeys.shopName: _resolvedEnglishShopName(),
      ShopKeys.countryId: selectedCountry?.id.toString() ?? '',
      ShopKeys.stateId: selectedState?.id.toString() ?? '',
      ShopKeys.cityId: selectedCity?.id.toString() ?? '',
      ShopKeys.address: addressController.text.trim(),
      ShopKeys.latitude: latitudeController.text.trim(),
      ShopKeys.longitude: longitudeController.text.trim(),
      ShopKeys.registrationNumber: regNoController.text.trim(),
      ShopKeys.contactNumber: buildMobileNumber(),
      ShopKeys.email: emailController.text.trim(),
      ShopKeys.isActive: shopStatus == ACTIVE,
    };

    if (shopTranslations.isNotEmpty) {
      fields[ShopKeys.translations] = jsonEncode(shopTranslations);
    }

    if (serviceList.any((element) => element.isSelected.validate())) {
      serviceList
          .where((element) => element.isSelected.validate())
          .forEachIndexed((element, index) {
        fields['${ShopKeys.serviceIds}[$index]'] = element.id;
      });
    }

    if (isUpdate) {
      List<String> existingImages = widget.shop!.shopImage
          .validate()
          .where((path) => path.startsWith('http'))
          .toList();
      if (existingImages.isNotEmpty) {
        fields[ShopKeys.existingImages] = existingImages.join(',');
      }
    }

    final images = selectedImages
        .where((path) => !path.startsWith('http'))
        .map((e) => File(e))
        .toList();

    await addEditShopMultiPart(
      data: fields,
      images: images,
      shopId: isUpdate ? widget.shop!.id : 0,
    ).then(
      (value) {
        finish(context, true);
      },
    ).catchError((e) {
      toast(e.toString());
    }).whenComplete(() => appStore.setLoading(false));
  }

  //region Validation Methods

  String? validateRegNo() {
    final value = regNoController.text;
    if (value.trim().isEmpty) {
      return languages.hintRequired;
    } else if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(value.trim())) {
      return languages.invalidInput;
    } else {
      return null;
    }
  }

  String? validateLatitude() {
    final value = latitudeController.text;
    if (value.trim().isEmpty) {
      return languages.latitudeIsRequired;
    } else {
      final lat = double.tryParse(value.trim());
      if (lat == null || lat < -90 || lat > 90) {
        return languages.latitudeRange;
      } else {
        return null;
      }
    }
  }

  String? validateLongitude() {
    final value = longitudeController.text;
    if (value.isEmpty) {
      return languages.longitudeIsRequired;
    }

    final double? longitude = double.tryParse(value);

    if (longitude.validate() < -180 || longitude.validate() > 180) {
      return languages.longitudeRange;
    }

    return null;
  }

  //endregion

  TimeOfDay parseTimeOfDay(String time) {
    if (time.isEmpty) return TimeOfDay.now();

    if (time.contains('T')) {
      final dt = DateTime.tryParse(time);
      if (dt != null) {
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }

    try {
      final parts = time.split(":");
      if (parts.length < 2) return TimeOfDay.now();

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1].split(" ")[0]) ?? 0;
      final isPM = time.toLowerCase().contains("pm");
      return TimeOfDay(
          hour: isPM ? (hour % 12) + 12 : hour % 12, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      nameController.dispose();
      addressController.dispose();
      regNoController.dispose();
      latitudeController.dispose();
      longitudeController.dispose();
      contactController.dispose();
      emailController.dispose();
      mobileController.dispose();
    }
    appStore.setLoading(false);
    super.dispose();
  }

  Future<void> fetchCurrentLocation() async {
    appStore.setLoading(true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          latitudeController.text = position.latitude.toString();
          longitudeController.text = position.longitude.toString();
        });
      }
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty && mounted) {
          Placemark place = placemarks.first;
          String address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          setState(() {
            addressController.text = address;
          });
        }
      } catch (e) {
        toast(e.toString());
      }
    } catch (e) {
      if (mounted) {
        toast(e.toString());
      }
    } finally {
      appStore.setLoading(false);
    }
  }

  //----------------------------- Helper Functions----------------------------//
  // Change country code function...
  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: languages.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      showPhoneCode: true,
      // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountryPicker = country;
        _valueNotifier.value = !_valueNotifier.value;
      },
    );
  }

  // Build mobile number with phone code and number
  String buildMobileNumber() {
    if (mobileController.text.isEmpty) {
      return '';
    } else {
      return _phoneNumberService.buildE164(
        mobileNumber: mobileController.text,
        countryCode: selectedCountryPicker.phoneCode,
      );
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Order services with selected first
    final List<ServiceData> _selectedServices =
        serviceList.where((s) => s.isSelected.validate()).toList();
    final List<ServiceData> _unselectedServices =
        serviceList.where((s) => !s.isSelected.validate()).toList();
    final List<ServiceData> _fullSortedServices = [
      ..._selectedServices,
      ..._unselectedServices
    ];

    // First page should show up to 5: selected first, then unselected
    final List<ServiceData> _initialDisplayServices = () {
      const int minCount = 5;
      if (_selectedServices.length >= minCount) return _selectedServices;
      final int need = minCount - _selectedServices.length;
      return [..._selectedServices, ..._unselectedServices.take(need)];
    }();

    return AppScaffold(
      appBarTitle: isUpdate ? languages.editShop : languages.addNewShop,
      body: Stack(
        children: [
          Column(
            children: [
              8.height,
              MultiLanguageWidget(
                selectedLanguageCode: selectedFormLanguageCode,
                onTap: (LanguageDataModel code) {
                  updateShopTranslation();
                  selectedFormLanguageCode = code.languageCode.validate();
                  nameController.clear();
                  getShopTranslation();
                  setState(() {
                    shopFormKey = UniqueKey();
                    _formKey = GlobalKey<FormState>();
                    _autoValidateMode = AutovalidateMode.disabled;
                  });
                },
              ),
              8.height,
              Expanded(
                child: SingleChildScrollView(
                  key: shopFormKey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: Column(
                      spacing: 14,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormField<List<String>>(
                          initialValue: selectedImages,
                          validator: (_) {
                            if (selectedImages.isEmpty) {
                              return languages.pleaseSelectImages;
                            }
                            return null;
                          },
                          builder: (field) {
                            final bool hasImageError = field.hasError;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomImagePicker(
                                  isMultipleImages: true,
                                  key: ValueKey(selectedImages.length),
                                  selectedImages: selectedImages,
                                  dottedBorderColor: hasImageError
                                      ? Colors.red
                                      : context.primaryColor,
                                  errorText: hasImageError
                                      ? field.errorText.validate()
                                      : null,
                                  showErrorUnderBorder: true,
                                  compactWhenNoImages: true,
                                  height: 140,
                                  width: double.infinity,
                                  onFileSelected: (files) {
                                    if (!mounted) return;
                                    setState(() {
                                      selectedImages =
                                          files.map((f) => f.path).toList();
                                    });
                                    field.didChange(selectedImages);
                                    if (field.hasError) field.validate();
                                  },
                                  onRemoveClick: (path) {
                                    if (!mounted) return;

                                    showConfirmDialogCustom(
                                      context,
                                      dialogType: DialogType.DELETE,
                                      positiveText: languages.lblDelete,
                                      negativeText: languages.lblCancel,
                                      onAccept: (p0) {
                                        if (!mounted) return;
                                        setState(() {
                                          selectedImages.remove(path);
                                        });
                                        field.didChange(selectedImages);
                                        if (field.hasError) field.validate();
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.NAME,
                          controller: nameController,
                          focus: shopNameFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.shop,
                          ),
                          suffix: Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          nextFocus: registrationNumberFocus,
                          isValidationRequired: true,
                          errorThisFieldRequired: languages.hintRequired,
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.NAME,
                          controller: regNoController,
                          focus: registrationNumberFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.registrationNumber,
                          ),
                          suffix: Icon(
                            Icons.badge_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          textStyle: primaryTextStyle(),
                          isValidationRequired: true,
                          errorThisFieldRequired: languages.hintRequired,
                          nextFocus: latitudeFocus,
                        ),
                        Row(
                          spacing: 16,
                          children: [
                            DropdownButtonFormField<CountryListResponse>(
                              decoration: inputDecoration(context,
                                  hint: languages.selectCountry),
                              isExpanded: true,
                              menuMaxHeight: 300,
                              value: countryList.any(
                                      (item) => item.id == selectedCountry?.id)
                                  ? selectedCountry
                                  : null,
                              dropdownColor: context.cardColor,
                              validator: (value) {
                                if (value == null)
                                  return languages.hintRequired;
                                return null;
                              },
                              items: countryList.map((CountryListResponse e) {
                                return DropdownMenuItem<CountryListResponse>(
                                  value: e,
                                  child: Text(e.name.validate(),
                                      style: primaryTextStyle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (CountryListResponse? value) async {
                                selectedCountry = value;
                                selectedState = null;
                                selectedCity = null;
                                await getStates(selectedCountry!.id!);
                                setState(() {});
                              },
                            ).expand(),
                            DropdownButtonFormField<StateListResponse>(
                              decoration: inputDecoration(context,
                                  hint: languages.selectState),
                              isExpanded: true,
                              dropdownColor: context.cardColor,
                              menuMaxHeight: 300,
                              value: (stateList.isNotEmpty &&
                                      selectedState != null &&
                                      stateList.any((item) =>
                                          item.id == selectedState?.id))
                                  ? selectedState
                                  : null,
                              validator: (value) {
                                if (value == null)
                                  return languages.hintRequired;
                                return null;
                              },
                              items: stateList.map((StateListResponse e) {
                                return DropdownMenuItem<StateListResponse>(
                                  value: e,
                                  child: Text(e.name!,
                                      style: primaryTextStyle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (StateListResponse? value) async {
                                selectedState = value;
                                selectedCity = null;
                                await getCities(selectedState!.id!);
                                setState(() {});
                              },
                            ).expand(),
                          ],
                        ),
                        DropdownButtonFormField<CityListResponse>(
                          decoration: inputDecoration(context),
                          hint: Text(languages.selectCity,
                              style: secondaryTextStyle()),
                          isExpanded: true,
                          value: cityList
                                  .any((item) => item.id == selectedCity?.id)
                              ? selectedCity
                              : null,
                          dropdownColor: context.cardColor,
                          validator: (value) {
                            if (value == null) return languages.hintRequired;
                            return null;
                          },
                          items: cityList.map(
                            (CityListResponse e) {
                              return DropdownMenuItem<CityListResponse>(
                                value: e,
                                child: Text(e.name!,
                                    style: primaryTextStyle(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              );
                            },
                          ).toList(),
                          onChanged: (CityListResponse? value) async {
                            selectedCity = value;
                            setState(() {});
                          },
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.MULTILINE,
                          controller: addressController,
                          focus: addressFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.hintAddress,
                          ),
                          suffix: Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          nextFocus: registrationNumberFocus,
                          isValidationRequired: true,
                          errorThisFieldRequired: languages.hintRequired,
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.NUMBER,
                          controller: latitudeController,
                          focus: latitudeFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.latitude,
                          ),
                          suffix: Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          validator: (value) => validateLatitude(),
                          nextFocus: longitudeFocus,
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.NUMBER,
                          controller: longitudeController,
                          focus: longitudeFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.longitude,
                          ),
                          suffix: Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          isValidationRequired: true,
                          errorThisFieldRequired: languages.hintRequired,
                          validator: (value) => validateLongitude(),
                          nextFocus: shopStartTimeFocus,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextIcon(
                            onTap: fetchCurrentLocation,
                            prefix: Icon(
                              Icons.my_location,
                              color: primaryColor,
                              size: 16,
                            ),
                            text: languages.useCurrentLocation,
                            textStyle: boldTextStyle(size: 12),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Container(
                              height: 48.0,
                              decoration: boxDecorationDefault(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: ValueListenableBuilder(
                                  valueListenable: _valueNotifier,
                                  builder: (context, value, child) {
                                    final String code =
                                        selectedCountryPicker.phoneCode;
                                    final String formattedCode =
                                        code.startsWith('+') ? code : '+$code';

                                    return Row(
                                      children: [
                                        Text(
                                          '${selectedCountryPicker.flagEmoji} $formattedCode',
                                          style: primaryTextStyle(size: 12),
                                        ).paddingOnly(left: 8),
                                        Icon(Icons.arrow_drop_down)
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ).onTap(() => changeCountry()),
                            AppTextField(
                              textFieldType: TextFieldType.NUMBER,
                              controller: mobileController,
                              focus: contactNumberFocus,
                              decoration: inputDecoration(context,
                                      hint: languages.hintContactNumberTxt)
                                  .copyWith(
                                hintStyle: secondaryTextStyle(),
                              ),
                              suffix:
                                  calling.iconImage(size: 10).paddingAll(14),
                              maxLength: 15,
                            ).expand(),
                          ],
                        ),
                        AppTextField(
                          textFieldType: TextFieldType.EMAIL_ENHANCED,
                          controller: emailController,
                          focus: emailFocus,
                          decoration: inputDecoration(
                            context,
                            hint: languages.hintEmailAddressTxt,
                          ),
                          suffix: Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: context.iconColor,
                          ).paddingAll(14),
                          isValidationRequired: true,
                          errorThisFieldRequired: languages.hintRequired,
                          errorInvalidEmail: languages.enterValidEmail,
                        ),
                        DropdownButtonFormField<StaticDataModel>(
                          isExpanded: true,
                          dropdownColor: context.cardColor,
                          value: shopStatusModel ?? statusListStaticData.first,
                          items: statusListStaticData.map((StaticDataModel data) {
                            return DropdownMenuItem<StaticDataModel>(
                              value: data,
                              child: Text(data.value.validate(), style: primaryTextStyle()),
                            );
                          }).toList(),
                          decoration: inputDecoration(context, hint: languages.lblStatus),
                          onChanged: (StaticDataModel? value) async {
                            if (value == null) return;
                            shopStatus = value.key.validate();
                            shopStatusModel = value;
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null) return errorThisFieldRequired;
                            return null;
                          },
                        ),
                        FormField<List<int>>(
                          initialValue: serviceList
                              .where((s) => s.isSelected.validate())
                              .map((s) => s.id.validate())
                              .toList(),
                          validator: (_) {
                            if (!serviceList.any(
                                (element) => element.isSelected.validate())) {
                              return languages.pleaseSelectService;
                            }
                            return null;
                          },
                          builder: (field) {
                            final bool hasServiceError = field.hasError;

                            return Container(
                              width: context.width(),
                              decoration: boxDecorationWithRoundedCorners(
                                borderRadius: radius(),
                                backgroundColor: context.cardColor,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languages.selectService,
                                    style: boldTextStyle(),
                                  ),
                                  12.height,
                                  if (serviceList.isEmpty)
                                    Text(
                                      languages.noServiceFound,
                                      style: secondaryTextStyle(),
                                    ).center(),
                                  if (serviceList.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: boxDecorationDefault(
                                        color: context.scaffoldBackgroundColor,
                                        borderRadius: radius(),
                                        border: Border.all(
                                          color: hasServiceError
                                              ? Colors.red
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          AnimatedWrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            listAnimationType:
                                                ListAnimationType.None,
                                            itemCount: servicePage == 1
                                                ? _initialDisplayServices.length
                                                : _fullSortedServices.length,
                                            itemBuilder: (context, index) {
                                              final List<ServiceData>
                                                  _displayList =
                                                  servicePage == 1
                                                      ? _initialDisplayServices
                                                      : _fullSortedServices;
                                              ServiceData service =
                                                  _displayList[index];
                                              return Theme(
                                                data: ThemeData(
                                                  unselectedWidgetColor:
                                                      appStore.isDarkMode
                                                          ? context.dividerColor
                                                          : context.iconColor,
                                                ),
                                                child: CheckboxListTile(
                                                  checkboxShape:
                                                      RoundedRectangleBorder(
                                                          borderRadius:
                                                              radius(4)),
                                                  autofocus: false,
                                                  activeColor:
                                                      context.primaryColor,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  dense: true,
                                                  checkColor:
                                                      appStore.isDarkMode
                                                          ? context.iconColor
                                                          : context.cardColor,
                                                  title: Marquee(
                                                    child: Text(
                                                      service.name.validate(),
                                                      style: primaryTextStyle(
                                                          size: 14),
                                                    ),
                                                  ),
                                                  value: service.isSelected
                                                      .validate(),
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      service.isSelected =
                                                          value.validate();
                                                    });
                                                    field.didChange(serviceList
                                                        .where((element) =>
                                                            element.isSelected
                                                                .validate())
                                                        .map((element) =>
                                                            element.id
                                                                .validate())
                                                        .toList());
                                                    if (field.hasError) {
                                                      field.validate();
                                                    }
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          if (serviceList.isNotEmpty &&
                                              serviceList.length >= 5)
                                            TextButton(
                                              onPressed: isLastPage
                                                  ? onBackToFirstPage
                                                  : onNextPage,
                                              child: Text(
                                                isLastPage
                                                    ? languages.viewLess
                                                    : languages.viewMore,
                                                style: boldTextStyle(
                                                    color: context.primaryColor,
                                                    size: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  if (hasServiceError)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, top: 6),
                                      child: Text(
                                        field.errorText.validate(),
                                        style: primaryTextStyle(
                                            color: Colors.red, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 32),
                        Observer(
                          builder: (_) => AppButton(
                            text: languages.btnSave,
                            margin: EdgeInsets.only(bottom: 12),
                            height: 40,
                            color: appStore.isLoading
                                ? context.primaryColor.withOpacity(0.6)
                                : context.primaryColor,
                            textStyle: boldTextStyle(color: white),
                            width:
                                context.width() - context.navigationBarHeight,
                            enabled: !appStore.isLoading,
                            onTap: saveShop,
                          ),
                        ).paddingOnly(left: 16.0, right: 16.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Observer(
              builder: (_) =>
                  LoaderWidget().center().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
