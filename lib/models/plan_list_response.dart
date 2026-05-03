import 'package:handyman_provider_flutter/models/provider_subscription_model.dart';

class PlanListResponse {
  List<ProviderSubscriptionModel>? data;
  ProviderSubscriptionModel? currentPlan;

  PlanListResponse({this.data, this.currentPlan});

  factory PlanListResponse.fromJson(Map<String, dynamic> json) {
    return PlanListResponse(
      data: json['data'] != null ? (json['data'] as List).map((i) => ProviderSubscriptionModel.fromJson(i)).toList() : null,
      currentPlan: json['current_plan'] != null ? ProviderSubscriptionModel.fromJson(json['current_plan']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (currentPlan != null) {
      data['current_plan'] = currentPlan!.toJson();
    }
    return data;
  }
}
