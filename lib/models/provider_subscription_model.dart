class ProviderSubscriptionModel {
  int? id;
  String? title;
  String? identifier;
  int? amount;
  int? originalAmount;
  String? type;
  String? endAt;
  int? planId;
  String? startAt;
  String? status;
  int? trialPeriod;
  String? description;
  String? duration;
  PlanLimitation? planLimitation;
  String? planType;
  String? paymentMethod;

  SubscriptionOtherDetail? otherDetail;

  String playStoreIdentifier;

  String appStoreIdentifier;

  String activePlanRevenueCatIdentifier;

  ProviderSubscriptionModel({
    this.id,
    this.title,
    this.identifier,
    this.amount,
    this.originalAmount,
    this.type,
    this.endAt,
    this.planId,
    this.startAt,
    this.status,
    this.trialPeriod,
    this.description,
    this.duration,
    this.planLimitation,
    this.planType,
    this.otherDetail,
    this.playStoreIdentifier = '',
    this.appStoreIdentifier = '',
    this.activePlanRevenueCatIdentifier = '',
    this.paymentMethod,
  });

  factory ProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ProviderSubscriptionModel(
      amount: json['amount'],
      originalAmount: json['original_amount'],
      endAt: json['end_at'],
      planLimitation: json['plan_limitation'] != null ? PlanLimitation.fromJson(json['plan_limitation']) : null,
      id: json['id'],
      identifier: json['identifier'],
      planId: json['plan_id'],
      startAt: json['start_at'],
      status: json['status'],
      type: json['type'],
      title: json['title'],
      trialPeriod: json['trial_period'],
      description: json['description'],
      duration: json['duration'],
      planType: json['plan_type'],
      otherDetail: json['other_detail'] != null ? SubscriptionOtherDetail.fromJson(json['other_detail']) : null,
      appStoreIdentifier: json['appstore_identifier'] is String ? json['appstore_identifier'] : "",
      playStoreIdentifier: json['playstore_identifier'] is String ? json['playstore_identifier'] : "",
      activePlanRevenueCatIdentifier: json['active_in_app_purchase_identifier'] is String ? json['active_in_app_purchase_identifier'] : "",
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = amount;
    data['original_amount'] = originalAmount;
    data['end_at'] = endAt;
    data['id'] = id;
    data['identifier'] = identifier;
    data['plan_id'] = planId;
    data['start_at'] = startAt;
    data['status'] = status;
    data['type'] = type;
    data['title'] = title;
    data['trial_period'] = trialPeriod;
    data['description'] = description;
    data['duration'] = duration;
    data['plan_limitation'] = planLimitation;
    data['plan_type'] = planType;
    if (otherDetail != null) {
      data['other_detail'] = otherDetail!.toJson();
    }
    data['active_in_app_purchase_identifier'] = activePlanRevenueCatIdentifier;
    if (planLimitation != null) {
      data['plan_limitation'] = planLimitation!.toJson();
    }
    data['payment_method'] = paymentMethod;
    return data;
  }
}

class PlanLimitation {
  LimitData? featuredService;
  LimitData? handyman;
  LimitData? service;

  PlanLimitation({this.featuredService, this.handyman, this.service});

  factory PlanLimitation.fromJson(Map<String, dynamic> json) {
    return PlanLimitation(
      featuredService: json['featured_service'] != null ? LimitData.fromJson(json['featured_service']) : null,
      handyman: json['handyman'] != null ? LimitData.fromJson(json['handyman']) : null,
      service: json['service'] != null ? LimitData.fromJson(json['service']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (featuredService != null) {
      data['featured_service'] = featuredService!.toJson();
    }
    if (handyman != null) {
      data['handyman'] = handyman!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    return data;
  }
}

class LimitData {
  String? isChecked;
  String? limit;

  LimitData({this.isChecked, this.limit});

  factory LimitData.fromJson(Map<String, dynamic> json) {
    return LimitData(
      isChecked: json['is_checked'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_checked'] = isChecked;
    data['limit'] = limit;
    return data;
  }
}

class SubscriptionOtherDetail {
  String? purchaseType;
  String? previousPlan;
  num? previousPlanPrice;
  num? originalPrice;
  num? paidAmount;
  num? creditApplied;
  num? remainingDays;
  String? reason;

  SubscriptionOtherDetail({
    this.purchaseType,
    this.previousPlan,
    this.previousPlanPrice,
    this.originalPrice,
    this.paidAmount,
    this.creditApplied,
    this.remainingDays,
    this.reason,
  });

  factory SubscriptionOtherDetail.fromJson(Map<String, dynamic> json) {
    return SubscriptionOtherDetail(
      purchaseType: json['purchase_type'],
      previousPlan: json['previous_plan'],
      previousPlanPrice: json['previous_plan_price'],
      originalPrice: json['original_price'],
      paidAmount: json['paid_amount'],
      creditApplied: json['credit_applied'],
      remainingDays: json['remaining_days'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['purchase_type'] = purchaseType;
    data['previous_plan'] = previousPlan;
    data['previous_plan_price'] = previousPlanPrice;
    data['original_price'] = originalPrice;
    data['paid_amount'] = paidAmount;
    data['credit_applied'] = creditApplied;
    data['remaining_days'] = remainingDays;
    data['reason'] = reason;
    return data;
  }
}