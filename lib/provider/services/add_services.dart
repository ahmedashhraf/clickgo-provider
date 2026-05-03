import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/custom_image_picker.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/attachment_model.dart';
import 'package:handyman_provider_flutter/models/service_detail_response.dart';
import 'package:handyman_provider_flutter/models/shop_model.dart';
import 'package:handyman_provider_flutter/models/visit_type_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/services/components/category_sub_cat_drop_down.dart';
import 'package:handyman_provider_flutter/provider/services/components/service_address_component.dart';
import 'package:handyman_provider_flutter/provider/timeSlots/my_time_slots_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/chat_gpt_loder.dart';
import '../../models/multi_language_request_model.dart';
import '../../models/static_data_model.dart';
import 'components/service_shop_component.dart';

class AddServices extends StatefulWidget {
  final ServiceDetailResponse? data;

  AddServices({this.data});

  @override
  State<AddServices> createState() => _AddServicesState();
}

class _AddServicesState extends State<AddServices> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  UniqueKey uniqueKey = UniqueKey();
  UniqueKey formWidgetKey = UniqueKey();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool isLastPage = false;

  /// TextEditingController
  TextEditingController serviceNameCont = TextEditingController();
  TextEditingController priceCont = TextEditingController();
  TextEditingController discountCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();
  TextEditingController durationContHr = TextEditingController();
  TextEditingController durationContMin = TextEditingController();
  TextEditingController prePayAmountController = TextEditingController();
  TextEditingController hoursCont = TextEditingController();
  TextEditingController miutesCont = TextEditingController();

  /// FocusNode
  FocusNode serviceNameFocus = FocusNode();
  FocusNode priceFocus = FocusNode();
  FocusNode discountFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode durationHrFocus = FocusNode();
  FocusNode durationMinFocus = FocusNode();
  FocusNode prePayAmountFocus = FocusNode();

  String serviceType = SERVICE_TYPE_FIXED;
  String serviceStatus = ACTIVE;
  int? categoryId = -1;
  int? subCategoryId = -1;

  TimeOfDay? currentTime;

  bool isUpdate = false;
  bool isFeature = false;
  bool isTimeSlotAvailable = false;
  bool isAdvancePayment = false;
  bool isAdvancePaymentAllowedBySystem = appConfigurationStore.isAdvancePaymentAllowed;
  List<File> imageFiles = [];
  List<Attachments> tempAttachments = [];
  VisitTypeData? selectedVisitType;
  List<VisitTypeData> visitTypeData = [
    VisitTypeData(isEnabled: false, title: languages.onSiteVisit, key: VISIT_OPTION_ON_SITE),
    if (appConfigurationStore.digitalServiceStatus) VisitTypeData(isEnabled: false, title: languages.onlineRemoteService, key: VISIT_OPTION_ONLINE),
    if (appConfigurationStore.digitalServiceStatus) VisitTypeData(isEnabled: false, title: languages.shop, key: VISIT_OPTION_SHOP),
  ];

  List<StaticDataModel> typeStaticData = [
    StaticDataModel(key: SERVICE_TYPE_FREE, value: languages.lblFree),
    StaticDataModel(key: SERVICE_TYPE_FIXED, value: languages.lblFixed),
    StaticDataModel(key: SERVICE_TYPE_HOURLY, value: languages.lblHourly),
  ];

  List<StaticDataModel> statusListStaticData = [
    StaticDataModel(key: ACTIVE, value: languages.active),
    StaticDataModel(key: INACTIVE, value: languages.inactive),
  ];

  StaticDataModel? serviceStatusModel;

  List<int> serviceZoneList = [];
  List<int> serviceShopsList = [];
  Map<String, MultiLanguageRequest> translations = {};
  MultiLanguageRequest enTranslations = MultiLanguageRequest();
  String selectedFormLanguageCode = DEFAULT_LANGUAGE;
  List<ShopModel> shopList = [];

  int shopPage = 1;
  bool isLastShopPage = false;

  ServiceDetailResponse? serviceDetail;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    selectedFormLanguageCode = appStore.selectedLanguage.languageCode
            .validate()
            .isNotEmpty
        ? appStore.selectedLanguage.languageCode.validate()
        : DEFAULT_LANGUAGE;

    isUpdate = widget.data != null;
    selectedVisitType = visitTypeData.first;
    if (isUpdate) {
      tempAttachments = widget.data!.serviceDetail!.attchments.validate();
      imageFiles = widget.data!.serviceDetail!.attchments.validate().map((e) => File(e.url.toString())).toList();
      if (widget.data?.serviceDetail?.translations?.isNotEmpty ?? false) {
        translations = await widget.data!.serviceDetail!.translations!;
        enTranslations =
            translations[DEFAULT_LANGUAGE] ?? MultiLanguageRequest();
      }
      final currentLang = selectedFormLanguageCode;

      if (currentLang == DEFAULT_LANGUAGE) {
        final String englishName = enTranslations.name.validate();
        final String englishDescription = enTranslations.description.validate();
        serviceNameCont.text = englishName.isNotEmpty
          ? englishName
          : widget.data?.serviceDetail?.name.validate() ?? "";
        descriptionCont.text = englishDescription.isNotEmpty
          ? englishDescription
          : widget.data?.serviceDetail?.description.validate() ?? "";
      } else {
        serviceNameCont.text = translations[currentLang]?.name.validate() ?? "";
        descriptionCont.text =
            translations[currentLang]?.description.validate() ?? "";
      }
      priceCont.text = widget.data!.serviceDetail!.price.toString().validate();
      discountCont.text = widget.data!.serviceDetail!.discount.toString().validate();
      categoryId = widget.data!.serviceDetail!.categoryId.validate();
      subCategoryId = widget.data!.serviceDetail!.subCategoryId.validate();
      isFeature = widget.data!.serviceDetail!.isFeatured.validate() == 1 ? true : false;
      serviceType = widget.data!.serviceDetail!.type.validate();
      serviceStatus = widget.data!.serviceDetail!.status.validate() == 1 ? ACTIVE : INACTIVE;
      if (serviceStatus == ACTIVE) {
        serviceStatusModel = statusListStaticData.first;
      } else {
        serviceStatusModel = statusListStaticData[1];
      }
      serviceZoneList = widget.data?.zones?.map((e) => e.id.validate()).toList() ?? [];

      currentTime = TimeOfDay(hour: widget.data!.serviceDetail!.duration.validate().splitBefore(':').toInt(), minute: widget.data!.serviceDetail!.duration.validate().splitAfter(':').toInt());
      durationContHr.text = "${currentTime!.hour}";
      durationContMin.text = "${currentTime!.minute}";
      isTimeSlotAvailable = widget.data!.serviceDetail!.isSlot.validate() == 1 ? true : false;
      isAdvancePayment = widget.data!.serviceDetail!.isAdvancePayment;
      if (widget.data!.serviceDetail!.advancePaymentAmount != null) {
        prePayAmountController.text = widget.data!.serviceDetail!.advancePaymentAmount.validate().toString();
      }

      timeSlotStore.initializeSlots(value: widget.data!.serviceDetail!.providerSlotData.validate());

      selectedVisitType = visitTypeData.firstWhere((element) => element.key == widget.data!.serviceDetail!.visitType.validate(), orElse: () => visitTypeData.first);
    }

    setState(() {});
    await timeSlotStore.timeSlotForProvider();
    await getShops(serviceId: isUpdate ? widget.data!.serviceDetail!.id.validate() : 0);
  }

  Future<void> getShops({int serviceId = 0}) async {
    await getShopList(
      shopPage,
      perPage: serviceId > 0 ? PER_PAGE_ITEM_ALL : 10,
      shopList: shopList,
      serviceIds: serviceId > 0 ? serviceId.toString() : "",
      lastPageCallBack: (b) {
        isLastShopPage = b;
      },
    )
        .whenComplete(
      () => appStore.setLoading(false),
    )
        .then((value) {
      if (serviceId > 0) {
        // service-linked shops
        selectedShops = value;
        
        // Populate serviceShopsList with selected shop IDs
        serviceShopsList = selectedShops.map((shop) => shop.id.validate()).toList();

        // mark selected
        for (var shop in shopList) {
          shop.isSelected = selectedShops.any((sel) => sel.id == shop.id);
        }

        // sort: selected first
        shopList.sort((a, b) {
          if (a.isSelected && !b.isSelected) return -1;
          if (!a.isSelected && b.isSelected) return 1;
          return 0;
        });

        // initially show 5 (2 selected + 3 unselected)
        if (shopList.length > 5) {
          shopList = shopList.take(5).toList();
          isLastShopPage = false; // so "View More" button shows
        } else {
          isLastShopPage = true;
        }
        
        setState(() {});
      }
    });
  }

  Future<void> reloadDataForLanguage() async {
    setState(() {
      formWidgetKey = UniqueKey();
    });
  }

//region Add Service
  Future<void> checkValidation({required bool isSave, LanguageDataModel? code}) async {
    if (!isSave) {
      selectedFormLanguageCode = code!.languageCode.validate();
      disposeAllTextFieldsController();
      getTranslation();
      await checkValidationLanguage();
      setState(() {
        formWidgetKey = UniqueKey();
        formKey = GlobalKey<FormState>();
        _autoValidateMode = AutovalidateMode.disabled;
      });
      await reloadDataForLanguage();
      return;
    }

    if (!formKey.currentState!.validate()) {
      if (_autoValidateMode != AutovalidateMode.onUserInteraction) {
        setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      }
      return;
    }

    formKey.currentState!.save();
    hideKeyboard(context);

    // Validate shop selection when visit type is Shop
    if (selectedVisitType?.key == VISIT_OPTION_SHOP) {
      if (serviceShopsList.isEmpty) {
        toast("Please select at least one shop");
        return;
      }
    }

    updateTranslation();
    await removeEnTranslations();
    final req = _buildServiceRequest();
    await _submitService(req);
    // Refresh service detail cache so subsequent edits see latest shop mapping
    try {
      if (isUpdate) {
        await getServiceDetail({'service_id': widget.data!.serviceDetail!.id.validate()});
      }
    } catch (e) {}
  }

//endregion

//region remove en translations
  removeEnTranslations() {
    if (translations.containsKey(DEFAULT_LANGUAGE)) {
      translations.remove(DEFAULT_LANGUAGE);
    }
  }

//endregion
  int servicePage = 1;

  Future<void> onNextPage() async {
    if (appStore.isLoading) return;
    if (!isLastPage) {
      servicePage++;
      await getShops();
    }
  }

//region service request
  String _resolvedEnglishServiceName() {
    final String englishName = enTranslations.name.validate().trim();
    if (englishName.isNotEmpty) return englishName;

    final String currentName = serviceNameCont.text.validate().trim();
    if (currentName.isNotEmpty) return currentName;

    final String selectedLangName = translations[selectedFormLanguageCode]?.name.validate().trim() ?? '';
    if (selectedLangName.isNotEmpty) return selectedLangName;

    for (final MultiLanguageRequest translation in translations.values) {
      final String fallbackName = translation.name.validate().trim();
      if (fallbackName.isNotEmpty) return fallbackName;
    }

    return '';
  }

  String _resolvedEnglishServiceDescription() {
    final String englishDescription = enTranslations.description.validate().trim();
    if (englishDescription.isNotEmpty) return englishDescription;

    final String currentDescription = descriptionCont.text.validate().trim();
    if (currentDescription.isNotEmpty) return currentDescription;

    final String selectedLangDescription = translations[selectedFormLanguageCode]?.description.validate().trim() ?? '';
    if (selectedLangDescription.isNotEmpty) return selectedLangDescription;

    for (final MultiLanguageRequest translation in translations.values) {
      final String fallbackDescription = translation.description.validate().trim();
      if (fallbackDescription.isNotEmpty) return fallbackDescription;
    }

    return '';
  }

  Map<String, dynamic> _buildServiceRequest() {
    final req = {
      AddServiceKey.name: _resolvedEnglishServiceName(),
      AddServiceKey.providerId: appStore.userId.validate(),
      AddServiceKey.categoryId: categoryId,
      AddServiceKey.type: serviceType.validate(),
      AddServiceKey.price: priceCont.text,
      AddServiceKey.discountPrice: discountCont.text,
      AddServiceKey.description: _resolvedEnglishServiceDescription(),
      AddServiceKey.isFeatured: isFeature ? '1' : '0',
      AddServiceKey.isSlot: isTimeSlotAvailable ? '1' : '0',
      AddServiceKey.status: serviceStatus.validate() == ACTIVE ? '1' : '0',
      if (durationContHr.text.trim().isNotEmpty ||
          durationContMin.text.trim().isNotEmpty)
        AddServiceKey.duration:
            "${int.tryParse(durationContHr.text.trim()) ?? 0}:${int.tryParse(durationContMin.text.trim()) ?? 0}",
      AddServiceKey.visitType: selectedVisitType!.key,
      AddServiceKey.isServiceRequest: '1',
      AdvancePaymentKey.isEnableAdvancePayment: isAdvancePayment ? 1 : 0,
    };

    if (subCategoryId != -1) {
      req.putIfAbsent(AddServiceKey.subCategoryId, () => subCategoryId);
    }

    if (translations.isNotEmpty) {
      req.putIfAbsent(AddServiceKey.translations, () => jsonEncode(translations));
    }

    if (isUpdate) {
      req.putIfAbsent(AddServiceKey.id, () => widget.data!.serviceDetail!.id.validate());
      req.putIfAbsent(AddServiceKey.providerZoneId, () => widget.data!.zones?.map((e) => e.id.validate()).toList());
    }
    if (isAdvancePaymentAllowedBySystem && isAdvancePayment) {
      req.putIfAbsent(AdvancePaymentKey.advancePaymentAmount, () => prePayAmountController.text.validate().toDouble());
    }
    if (selectedVisitType!.key == VISIT_OPTION_SHOP) {
      req.putIfAbsent(AddServiceKey.shopIds, () => serviceShopsList);
    }

    return req;
  }

  //endregion

//region Service APi Call
  Future<void> _submitService(Map<String, dynamic> req) async {
    try {
      await addServiceMultiPart(
        value: req,
        serviceAddressList: serviceZoneList,
        imageFile: imageFiles.where((element) => !element.path.contains('http')).toList(),
      );
    } catch (e) {
      toast(e.toString());
    }
  }

//endregion

//region Update Translation
  void updateTranslation() {
    appStore.setLoading(true);
    final languageCode = selectedFormLanguageCode;
    if (serviceNameCont.text.isEmpty && descriptionCont.text.isEmpty) {
      translations.remove(languageCode);
    } else {
      if (languageCode != DEFAULT_LANGUAGE) {
        translations[languageCode] = translations[languageCode]?.copyWith(
              name: serviceNameCont.text.validate(),
              description: descriptionCont.text.validate(),
            ) ??
            MultiLanguageRequest(
              name: serviceNameCont.text.validate(),
              description: descriptionCont.text.validate(),
            );
      } else {
        enTranslations = enTranslations.copyWith(
          name: serviceNameCont.text.validate(),
          description: descriptionCont.text.validate(),
        );
      }
    }
    appStore.setLoading(false);
  }

//endregion

//region Get Translation Details
  void getTranslation() {
    final languageCode = selectedFormLanguageCode;
    if (languageCode == DEFAULT_LANGUAGE) {
      serviceNameCont.text = enTranslations.name.validate();
      descriptionCont.text = enTranslations.description.validate();
    } else {
      final translation = translations[languageCode] ?? MultiLanguageRequest();
      final name = translation.name.validate();
      final description = translation.description.validate();
      serviceNameCont.text = name;
      descriptionCont.text = description;
    }
    setState(() {});
  }

//endregion

//region Dispose All TextControllers
  void disposeAllTextFieldsController() {
    serviceNameCont.clear();
    descriptionCont.clear();
    setState(() {});
  }

//endregion

//region language wise validation
  bool checkValidationLanguage() {
    return true;
  }

//endregion

//region Remove Attachment
  Future<void> removeAttachment({required int id}) async {
    appStore.setLoading(true);

    Map req = {
      CommonKeys.type: 'service_attachment',
      CommonKeys.id: id,
    };

    await deleteImage(req).then((value) {
      tempAttachments.validate().removeWhere((element) => element.id == id);
      setState(() {});

      uniqueKey = UniqueKey();

      appStore.setLoading(false);
      toast(value.message.validate(), print: true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  List<ShopModel> selectedShops = [];

//endregion

//region Build Widget
  Widget buildFormWidget() {
    return Container(
      key: formWidgetKey,
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(),
        backgroundColor: context.cardColor,
      ),
      child: Form(
        key: formKey,
        autovalidateMode: _autoValidateMode,
        child: Wrap(
          runSpacing: 16,
          children: [
            FormField<List<String>>(
              initialValue:
                  imageFiles.validate().map((e) => e.path.validate()).toList(),
              validator: (_) {
                if (imageFiles.isEmpty) return languages.pleaseSelectImages;
                return null;
              },
              builder: (field) {
                final bool hasImageError = field.hasError;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImagePicker(
                      key: uniqueKey,
                      dottedBorderColor:
                          hasImageError ? Colors.red : context.primaryColor,
                      errorText:
                          hasImageError ? field.errorText.validate() : null,
                      showErrorUnderBorder: true,
                      compactWhenNoImages: true,
                      onRemoveClick: (value) {
                        if (tempAttachments.validate().isNotEmpty &&
                            imageFiles.isNotEmpty) {
                          showConfirmDialogCustom(
                            context,
                            dialogType: DialogType.DELETE,
                            positiveText: languages.lblDelete,
                            negativeText: languages.lblCancel,
                            onAccept: (p0) {
                              imageFiles.removeWhere(
                                  (element) => element.path == value);
                              field.didChange(imageFiles
                                  .map((e) => e.path.validate())
                                  .toList());
                              field.validate();

                              if (value.startsWith('http')) {
                                removeAttachment(
                                  id: tempAttachments
                                      .validate()
                                      .firstWhere(
                                          (element) => element.url == value)
                                      .id
                                      .validate(),
                                );
                              }

                              setState(() {});
                            },
                          );
                        } else {
                          showConfirmDialogCustom(
                            context,
                            dialogType: DialogType.DELETE,
                            positiveText: languages.lblDelete,
                            negativeText: languages.lblCancel,
                            onAccept: (p0) {
                              imageFiles.removeWhere(
                                  (element) => element.path == value);
                              if (isUpdate) {
                                uniqueKey = UniqueKey();
                              }
                              field.didChange(imageFiles
                                  .map((e) => e.path.validate())
                                  .toList());
                              field.validate();
                              setState(() {});
                            },
                          );
                        }
                      },
                      isMultipleImages: true,
                      selectedImages: widget.data != null
                          ? imageFiles
                              .validate()
                              .map((e) => e.path.validate())
                              .toList()
                          : null,
                      height: 140,
                      width: double.infinity,
                      onFileSelected: (List<File> files) async {
                        imageFiles = files;
                        field.didChange(
                            imageFiles.map((e) => e.path.validate()).toList());
                        field.validate();
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
            AppTextField(
              textFieldType: TextFieldType.NAME,
              controller: serviceNameCont,
              focus: serviceNameFocus,
              nextFocus: priceFocus,
              isValidationRequired: checkValidationLanguage(),
              errorThisFieldRequired: languages.hintRequired,
              decoration: inputDecoration(context, hint: languages.hintServiceName, fillColor: context.scaffoldBackgroundColor),
            ),
            16.height,
            CategorySubCatDropDown(
              categoryId: categoryId == -1 ? null : categoryId,
              subCategoryId: subCategoryId == -1 ? null : subCategoryId,
              languageCode: appStore.selectedLanguage.languageCode,
              isCategoryValidate: true,
              onCategorySelect: (int? val) {
                categoryId = val!;
                setState(() {});
              },
              onSubCategorySelect: (int? val) {
                subCategoryId = val!;
                setState(() {});
              },
            ),
            FormField<List<int>>(
              initialValue: serviceZoneList,
              validator: (_) {
                if (serviceZoneList.validate().isEmpty) {
                  return languages.plzSelectOneZone;
                }
                return null;
              },
              builder: (field) {
                return ServiceAddressComponent(
                  selectedList: serviceZoneList,
                  errorText: field.errorText,
                  onSelectedList: (val) {
                    serviceZoneList = val;
                    field.didChange(val);
                    if (field.hasError) {
                      field.validate();
                    }
                    setState(() {});
                  },
                );
              },
            ),
            Row(
              children: [
                DropdownButtonFormField<StaticDataModel>(
                  decoration: inputDecoration(context, fillColor: context.scaffoldBackgroundColor, hint: languages.lblType),
                  isExpanded: true,
                  initialValue: serviceType.isNotEmpty ? getServiceType : null,
                  dropdownColor: context.cardColor,
                  items: typeStaticData.map((StaticDataModel data) {
                    return DropdownMenuItem<StaticDataModel>(
                      value: data,
                      child: Text(data.value.validate(), style: primaryTextStyle()),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) return errorThisFieldRequired;
                    return null;
                  },
                  onChanged: (StaticDataModel? value) async {
                    serviceType = value!.key.validate();

                    if (serviceType == SERVICE_TYPE_FREE) {
                      priceCont.text = '0';
                      discountCont.text = '0';
                    } else if (widget.data != null) {
                      priceCont.text = widget.data!.serviceDetail!.price.validate().toString();
                      discountCont.text = widget.data!.serviceDetail!.discount.validate().toString();
                    } else {
                      priceCont.text = '';
                      discountCont.text = '';
                    }

                    // Reset advance payment when service type is not fixed
                    if (serviceType != SERVICE_TYPE_FIXED) {
                      isAdvancePayment = false;
                      prePayAmountController.clear();
                    }

                    setState(() {});
                  },
                ).expand(),
                16.width,
                DropdownButtonFormField<StaticDataModel>(
                  isExpanded: true,
                  dropdownColor: context.cardColor,
                  initialValue: serviceStatusModel != null ? serviceStatusModel : statusListStaticData.first,
                  items: statusListStaticData.map((StaticDataModel data) {
                    return DropdownMenuItem<StaticDataModel>(
                      value: data,
                      child: Text(data.value.validate(), style: primaryTextStyle()),
                    );
                  }).toList(),
                  decoration: inputDecoration(context, fillColor: context.scaffoldBackgroundColor, hint: languages.lblStatus),
                  onChanged: (StaticDataModel? value) async {
                    serviceStatus = value!.key.validate();
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null) return errorThisFieldRequired;
                    return null;
                  },
                ).expand(),
              ],
            ),
            Row(
              children: [
                AppTextField(
                  textFieldType: TextFieldType.PHONE,
                  controller: priceCont,
                  focus: priceFocus,
                  nextFocus: discountFocus,
                  enabled: serviceType != SERVICE_TYPE_FREE,
                  errorThisFieldRequired: languages.hintRequired,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: inputDecoration(
                    context,
                    hint: languages.hintPrice,
                    fillColor: context.scaffoldBackgroundColor,
                  ),
                  validator: (s) {
                    if (s!.isEmpty) return errorThisFieldRequired;

                    if (s.toDouble() <= 0 && serviceType != SERVICE_TYPE_FREE) return languages.priceAmountValidationMessage;
                    return null;
                  },
                ).expand(),
                16.width,
                AppTextField(
                  textFieldType: TextFieldType.PHONE,
                  controller: discountCont,
                  focus: discountFocus,
                  nextFocus: durationHrFocus,
                  enabled: serviceType != SERVICE_TYPE_FREE,
                  decoration: inputDecoration(
                    context,
                    hint: languages.hintDiscount.capitalizeFirstLetter().suffixText(value: ' (%)'),
                    fillColor: context.scaffoldBackgroundColor,
                  ),
                  isValidationRequired: serviceType != SERVICE_TYPE_FREE,
                  validator: (s) {
                    int discount = int.tryParse(s.validate()).validate();
                    if ((discount < 0 || discount >= 100))
                      return languages.valueConditionMessage;
                    else
                      return null;
                  },
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ).expand(),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    textFieldType: TextFieldType.PHONE,
                    controller: durationContHr,
                    focus: durationHrFocus,
                    nextFocus: durationMinFocus,
                    maxLength: 3,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final int hour = int.tryParse(value) ?? 0;
                      final int minute = int.tryParse(durationContMin.text.trim()) ?? 0;
                      if (value.trim().isEmpty && durationContMin.text.trim().isEmpty) {
                        currentTime = null;
                      } else {
                        currentTime = TimeOfDay(
                          hour: hour.clamp(0, 23).toInt(),
                          minute: minute.clamp(0, 59).toInt(),
                        );
                      }
                    },
                    isValidationRequired: false,
                    errorThisFieldRequired: languages.hintRequired,
                    decoration: inputDecoration(
                      context,
                      hint: languages.lblDurationHr,
                      fillColor: context.scaffoldBackgroundColor,
                      counterText: '',
                    ),
                  ),
                ),
                10.width,
                Expanded(
                  child: AppTextField(
                    textFieldType: TextFieldType.PHONE,
                    controller: durationContMin,
                    focus: durationMinFocus,
                    nextFocus: descriptionFocus,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    onChanged: (value) {
                      final int hour = int.tryParse(durationContHr.text.trim()) ?? 0;
                      final int minute = int.tryParse(value) ?? 0;
                      if (durationContHr.text.trim().isEmpty && value.trim().isEmpty) {
                        currentTime = null;
                      } else {
                        currentTime = TimeOfDay(
                          hour: hour.clamp(0, 23).toInt(),
                          minute: minute.clamp(0, 59).toInt(),
                        );
                      }
                    },
                    isValidationRequired: false,
                    errorThisFieldRequired: languages.hintRequired,
                    decoration: inputDecoration(
                      context,
                      hint: languages.lblDurationMin,
                      fillColor: context.scaffoldBackgroundColor,
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            AppTextField(
              textFieldType: TextFieldType.MULTILINE,
              minLines: 5,
              controller: descriptionCont,
              focus: descriptionFocus,
              enableChatGPT: appConfigurationStore.chatGPTStatus,
              promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                hintText: languages.writeHere,
                fillColor: context.scaffoldBackgroundColor,
                filled: true,
              ),
              testWithoutKeyChatGPT: appConfigurationStore.testWithoutKey,
              loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
              errorThisFieldRequired: languages.hintRequired,
              isValidationRequired: false,
              decoration: inputDecoration(
                context,
                hint: languages.hintDescription,
                fillColor: context.scaffoldBackgroundColor,
              ),
            ),
            Container(
              decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor, borderRadius: radius()),
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Theme(
                data: ThemeData(
                  unselectedWidgetColor: appStore.isDarkMode ? context.dividerColor : context.iconColor,
                ),
                child: CheckboxListTile(
                  checkboxShape: RoundedRectangleBorder(borderRadius: radius(4)),
                  activeColor: context.primaryColor,
                  checkColor: appStore.isDarkMode ? context.iconColor : context.cardColor,
                  value: isFeature,
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: radius(), side: const BorderSide(color: primaryColor)),
                  title: Text(languages.hintSetAsFeature, style: secondaryTextStyle()),
                  onChanged: (bool? v) {
                    isFeature = v.validate();
                    setState(() {});
                  },
                ),
              ),
            ),
            Container(
              width: context.width(),
              decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor, borderRadius: radius()),
              padding: const EdgeInsets.only(left: 16, right: 4, top: 8),
              child: Theme(
                data: ThemeData(
                  unselectedWidgetColor: appStore.isDarkMode ? context.dividerColor : context.iconColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(languages.visitOption, style: boldTextStyle()),
                    8.height,
                    AnimatedWrap(
                      itemCount: visitTypeData.length,
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                      spacing: 8,
                      runSpacing: 4,
                      itemBuilder: (context, index) {
                        VisitTypeData value = visitTypeData[index];

                        return Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                width: context.width() * 0.5 - 70,
                                height: 60,
                                padding: const EdgeInsets.all(8),
                                decoration: boxDecorationDefault(
                                  borderRadius: radius(8),
                                  color: appStore.isDarkMode ? cardDarkColor : cardLightColor,
                                  border: Border.all(color: primaryColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(value.title.validate(), style: primaryTextStyle(size: 12), textAlign: TextAlign.center),
                              ).onTap(() {
                                selectedVisitType = value;

                                setState(() {});
                              }),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: selectedVisitType == value ? const EdgeInsets.all(2) : EdgeInsets.zero,
                                decoration: boxDecorationDefault(color: context.primaryColor),
                                child: selectedVisitType == value ? const Icon(Icons.done, size: 16, color: Colors.white) : const Offstage(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    8.height,
                  ],
                ),
              ),
            ),
            if (selectedVisitType?.key == VISIT_OPTION_SHOP)
              ServiceShopComponent(
                key: ValueKey(selectedShops.length),
                selectedList: selectedShops.map((shop) => shop.id.validate()).toList(),
                onSelectedList: (val) {
                  serviceShopsList = val;
                  for (var shop in shopList) {
                    shop.isSelected = val.contains(shop.id);
                  }
                  selectedShops = shopList.where((shop) => shop.isSelected).toList();
                  setState(() {});
                },
              ),
            if (appConfigurationStore.slotServiceStatus)
              Container(
                decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor, borderRadius: radius()),
                child: SettingItemWidget(
                  title: languages.timeSlotAvailable,
                  subTitle: languages.doesThisServicesContainsTimeslot,
                  trailing: Observer(builder: (context) {
                    return Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        activeTrackColor: primaryColor,
                        value: isTimeSlotAvailable,
                        onChanged: (v) async {
                          if (!v) {
                            isTimeSlotAvailable = v;
                            setState(() {});
                            return;
                          }
                          if (timeSlotStore.isTimeSlotAvailable) {
                            isTimeSlotAvailable = v;
                            setState(() {});
                          } else {
                            toast(languages.pleaseEnterTheDefaultTimeslotsFirst);
                            MyTimeSlotsScreen(isFromService: true).launch(context).then((value) {
                              if (value != null) {
                                if (value) {
                                  isTimeSlotAvailable = v;
                                  setState(() {});
                                }
                              }
                            });
                          }
                        },
                      ).visible(!timeSlotStore.isLoading, defaultWidget: LoaderWidget(size: 26)),
                    );
                  }),
                ),
              ),
            if (isAdvancePaymentAllowedBySystem && serviceType == SERVICE_TYPE_FIXED)
              Container(
                decoration: boxDecorationDefault(color: context.scaffoldBackgroundColor, borderRadius: radius()),
                child: SettingItemWidget(
                  title: languages.enablePrePayment,
                  subTitle: languages.enablePrePaymentMessage,
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      activeTrackColor: primaryColor,
                      value: isAdvancePayment,
                      onChanged: (v) async {
                        isAdvancePayment = !isAdvancePayment;
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            if (isAdvancePaymentAllowedBySystem && isAdvancePayment && serviceType == SERVICE_TYPE_FIXED)
              AppTextField(
                textFieldType: TextFieldType.PHONE,
                controller: prePayAmountController,
                focus: prePayAmountFocus,
                maxLength: 3,
                errorThisFieldRequired: languages.hintRequired,
                decoration: inputDecoration(
                  context,
                  hint: languages.advancePayAmountPer,
                  fillColor: context.scaffoldBackgroundColor,
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                validator: (s) {
                  if (s!.isEmpty) return errorThisFieldRequired;

                  if (s.toInt() <= 0 || s.toInt() >= 100) return languages.valueConditionMessage;
                  return null;
                },
              ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

//endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    setStatusBarColor(Colors.transparent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBarWidget(
        isUpdate ? languages.lblEditService : languages.hintAddService,
        textColor: white,
        color: context.primaryColor,
        backWidget: BackWidget(),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              8.height,
              MultiLanguageWidget(
                selectedLanguageCode: selectedFormLanguageCode,
                onTap: (LanguageDataModel code) {
                  checkValidation(isSave: false, code: code);
                },
              ),
              8.height,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      buildFormWidget(),
                    ],
                  ).paddingOnly(left: 16.0, right: 16.0),
                ),
              ),
              Observer(
                builder: (_) => AppButton(
                  margin: const EdgeInsets.only(bottom: 12),
                  text: languages.btnSave,
                  height: 40,
                  color: appStore.isLoading ? primaryColor.withValues(alpha: 0.5) : primaryColor,
                  textStyle: boldTextStyle(color: white),
                  width: context.width() - context.navigationBarHeight,
                  onTap: appStore.isLoading
                      ? () {}
                      : () {
                          checkValidation(isSave: true);
                        },
                ),
              ).paddingOnly(left: 16.0, right: 16.0),
            ],
          ),
          Observer(builder: (_) => LoaderWidget().center().visible(appStore.isLoading)),
        ],
      ),
    );
  }

  StaticDataModel get getServiceType => serviceType == SERVICE_TYPE_FREE
      ? typeStaticData[0]
      : serviceType == SERVICE_TYPE_FIXED
          ? typeStaticData[1]
          : typeStaticData[2];
}
