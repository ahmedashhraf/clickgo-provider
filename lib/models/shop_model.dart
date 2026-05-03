import 'dart:convert';

import 'package:handyman_provider_flutter/models/service_model.dart';
import 'package:handyman_provider_flutter/models/shop_hours_model.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopModel {
  int id;
  String registrationNumber;
  String name;
  bool isActive;
  int countryId;
  String countryName;
  int stateId;
  String stateName;
  int cityId;
  String cityName;
  String address;
  String shopStartTime;
  String shopEndTime;
  double latitude;
  double longitude;
  String contactNumber;
  String email;
  List<String> shopImage;
  List<ServiceData> services;
  List<ShopDayModel> shopHour;
  int providerId;
  String providerName;
  String providerImage;
  int isFavourite;
  int serviceCount;
  Map<String, Map<String, String>>? translations;

  bool isSelected = false;

  String get shopFirstImage => shopImage.isNotEmpty ? shopImage.first : '';

  String buildFullAddress() {
    List<String> addressParts = [];

    if (address.isNotEmpty) {
      addressParts.add(address);
    }

    if ((cityName).isNotEmpty) {
      addressParts.add(cityName.validate());
    }
    if ((stateName).isNotEmpty) {
      addressParts.add(stateName.validate());
    }
    if ((countryName).isNotEmpty) {
      addressParts.add(countryName.validate());
    }

    if (addressParts.isEmpty) return '---';

    return addressParts.join(', ');
  }

  ShopModel({
    this.id = -1,
    this.registrationNumber = "",
    this.name = "",
    this.isActive = true,
    this.countryId = -1,
    this.countryName = "",
    this.stateId = -1,
    this.stateName = "",
    this.cityId = -1,
    this.cityName = "",
    this.address = "",
    this.shopStartTime = "",
    this.shopEndTime = "",
    this.latitude = 0,
    this.longitude = 0,
    this.contactNumber = "",
    this.email = "",
    this.shopImage = const <String>[],
    this.services = const <ServiceData>[],
    this.shopHour = const <ShopDayModel>[],
    this.providerId = -1,
    this.providerName = "",
    this.providerImage = "",
    this.isFavourite = 0,
    this.serviceCount = 0,
    this.translations,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] is int ? json['id'] : -1,
      registrationNumber: json['registration_number'] is String ? json['registration_number'] : "",
      name: json['name'] is String ? json['name'] : "",
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      countryId: json['country_id'] is int ? json['country_id'] : -1,
      countryName: json['country_name'] is String ? json['country_name'] : "",
      stateId: json['state_id'] is int ? json['state_id'] : -1,
      stateName: json['state_name'] is String ? json['state_name'] : "",
      cityId: json['city_id'] is int ? json['city_id'] : -1,
      cityName: json['city_name'] is String ? json['city_name'] : "",
      address: json['address'] is String ? json['address'] : "",
      shopStartTime: json['shop_start_time'] is String ? json['shop_start_time'] : "",
      shopEndTime: json['shop_end_time'] is String ? json['shop_end_time'] : "",
      latitude: json['latitude'] is double ? json['latitude'] : 0,
      longitude: json['longitude'] is double ? json['longitude'] : 0,
      contactNumber: json['contact_number'] is String ? json['contact_number'] : "",
      email: json['email'] is String ? json['email'] : "",
      shopImage: json['shop_image'] is List ? List<String>.from(json['shop_image']) : [],
      services: json['services'] is List ? List<ServiceData>.from(json['services'].map((x) => ServiceData.fromJson(x))) : [],
      shopHour: json['shop_hour'] is List
          ? List<ShopDayModel>.from((json['shop_hour'] as List).map((x) => ShopDayModel.fromJson(x is Map<String, dynamic> ? x : <String, dynamic>{})))
          : (json['shop_hours'] is List
              ? List<ShopDayModel>.from((json['shop_hours'] as List).map((x) => ShopDayModel.fromJson(x is Map<String, dynamic> ? x : <String, dynamic>{})))
              : []),
      providerId: json['provider_id'] is int ? json['provider_id'] : -1,
      providerName: json['provider_name'] is String ? json['provider_name'] : "",
      providerImage: json['provider_image'] is String ? json['provider_image'] : "",
      isFavourite: json['is_favourite'] is int ? json['is_favourite'] : 0,
      serviceCount: json['services_count'] is int ? json['services_count'] : 0,
      translations: () {
        if (json['translations'] == null) return null;
        var transData = json['translations'];
        if (transData is String && transData.isNotEmpty) {
          try {
            transData = jsonDecode(transData);
          } catch (e) {
            return null;
          }
        }
        if (transData is Map) {
          return (transData as Map<String, dynamic>).map(
            (k, v) => MapEntry(
              k,
              v is Map
                  ? Map<String, String>.from(v.map((a, b) => MapEntry(a.toString(), b.toString())))
                  : <String, String>{},
            ),
          );
        }
        return null;
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'name': name,
      'is_active': isActive,
      'country_id': countryId,
      'country_name': countryName,
      'state_id': stateId,
      'state_name': stateName,
      'city_id': cityId,
      'city_name': cityName,
      'address': address,
      'shop_start_time': shopStartTime,
      'shop_end_time': shopEndTime,
      'latitude': latitude,
      'longitude': longitude,
      'contact_number': contactNumber,
      'email': email,
      'shop_image': shopImage.map((e) => e).toList(),
      'services': services.map((e) => e.toJson()).toList(),
      'shop_hour': shopHour.map((e) => e.toJson()).toList(),
      'provider_id': providerId,
      'provider_name': providerName,
      'provider_image': providerImage,
      'is_favourite': isFavourite,
      if (translations != null) 'translations': translations,
    };
  }
}

class ShopListResponse {
  List<ShopModel> shopList;

  ShopListResponse({this.shopList = const <ShopModel>[]});

  factory ShopListResponse.fromJson(Map<String, dynamic> json) {
    return ShopListResponse(
      shopList: json['data'] is List ? List<ShopModel>.from(json['data'].map((x) => ShopModel.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.shopList.map((v) => v.toJson()).toList();
    return data;
  }
}

class ShopDetailResponse {
  ShopModel? shopDetail;

  ShopDetailResponse({this.shopDetail});

  factory ShopDetailResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponse(
      shopDetail: json['shop'] != null ? ShopModel.fromJson(json['shop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.shopDetail != null) {
      data['shop'] = this.shopDetail!.toJson();
    }
    return data;
  }
}