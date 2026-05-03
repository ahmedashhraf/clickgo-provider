// ignore_for_file: body_might_complete_normally_catch_error


import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/network_utils.dart';
import 'package:handyman_provider_flutter/provider/payment/components/phone_pe/phone_pe_view_page.dart';
import 'package:handyman_provider_flutter/services/phone_number_service.dart';
import 'package:handyman_provider_flutter/utils/app_configuration.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

class PhonePeServices {
  late PaymentSetting paymentSetting;
  int bookingId = 0;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;
  bool isTest = false;
  String environmentValue = '';
  String merchantId = "";
  String appId = "";
  String saltKey = "";
  int saltIndex = 1;
  bool enableLogging = false;

  String currencyCode;
  String? callbackUrl;
  String? appSchema;
  String createOrderEndpoint;
  String verifyOrderEndpoint;
  String initiateEndpoint;
  String initiateV2Endpoint;
  num? minAmount;
  bool forceNativeSDK;
  int maxVerificationRetries;
  final PhoneNumberService _phoneNumberService = const PhoneNumberService();

  PhonePeServices({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    int bookingId = 0,
    required Function(Map<String, dynamic>) onComplete,
    this.currencyCode = 'INR',
    this.callbackUrl,
    this.appSchema,
    this.createOrderEndpoint = 'phonepe/create-order',
    this.verifyOrderEndpoint = 'phonepe/verify-order',
    this.initiateEndpoint = 'phonepe/initiate',
    this.initiateV2Endpoint = 'phonepe/initiate-v2',
    this.enableLogging = true,
    this.minAmount,
    this.forceNativeSDK = false,
    this.maxVerificationRetries = 3,
  }) {
    isTest = paymentSetting.isTest == 1;
    environmentValue = isTest ? "SANDBOX" : "PRODUCTION";

    if (isTest) {
      merchantId = ((paymentSetting.testValue?.merchantIdV2 ?? paymentSetting.testValue?.merchantIdV1) ?? "").toString().trim();
      appId = ((paymentSetting.testValue?.clientIdV2) ?? "").toString().trim();
      saltKey = ((paymentSetting.testValue?.saltKeyV1) ?? "").toString().trim();
      saltIndex = int.tryParse(((paymentSetting.testValue?.saltIndexV1) ?? "1").toString().trim()) ?? 1;
    } else {
      merchantId = ((paymentSetting.liveValue?.merchantIdV2 ?? paymentSetting.liveValue?.merchantIdV1) ?? "").toString().trim();
      appId = ((paymentSetting.liveValue?.clientIdV2) ?? "").toString().trim();
      saltKey = ((paymentSetting.liveValue?.saltKeyV1) ?? "").toString().trim();
      saltIndex = int.tryParse(((paymentSetting.liveValue?.saltIndexV1) ?? "1").toString().trim()) ?? 1;
    }

    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
    this.bookingId = bookingId;
  }

  String txnId = "";

  bool _isSuccessStatus(String status) {
    final successStatuses = [
      'SUCCESS',
      'COMPLETED',
      'PAID',
      'PAYMENT_SUCCESS',
      'VERIFIED',
      'APPROVED',
    ];
    return successStatuses.contains(status.toUpperCase());
  }

  bool _isPendingStatus(String status) {
    final pendingStatuses = [
      'PENDING',
      'PAYMENT_PENDING',
      'PROCESSING',
      'INITIATED',
    ];
    return pendingStatuses.contains(status.toUpperCase());
  }
  
  bool _isFailedStatus(String status) {
    final failedStatuses = [
      'FAILED',
      'PAYMENT_ERROR',
      'PAYMENT_DECLINED',
      'PAYMENT_CANCELLED',
      'DECLINED',
      'CANCELLED',
      'ERROR',
    ];
    return failedStatuses.contains(status.toUpperCase());
  }

  Future<void> initPhonePeSDK() async {
    try {
      String flowId = appId.isNotEmpty ? appId : "FLOW_${appStore.userId}_${DateTime.now().millisecondsSinceEpoch}";

      PhonePePaymentSdk.init(
        environmentValue, 
        merchantId, 
        flowId, 
        enableLogging, 
      ).then((_) {}).catchError((error) {
        throw error;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> phonePeCheckout(BuildContext context, {bool isV2 = false}) async {
    try {
      appStore.setLoading(true);

      txnId = "TXN_${DateTime.now().millisecondsSinceEpoch}_$bookingId";

      if (minAmount != null && totalAmount < minAmount!) {
        throw "The amount must be at least $minAmount. Current amount: $totalAmount";
      }

      if (forceNativeSDK || (merchantId.isNotEmpty && appId.isNotEmpty)) {
        await _phonePeCheckoutNative(context);
      } else {
        await _phonePeCheckoutWebView(context, isV2: isV2);
      }
    } catch (e) {
      appStore.setLoading(false);
      toast("PhonePe payment failed: ${e.toString()}");
      onComplete({
        "status": 'payment_error',
        "error": e.toString(),
      });
    }
  }

  Future<void> _phonePeCheckoutNative(BuildContext context) async {
    try {
      await initPhonePeSDK();

      appStore.setLoading(true);

      var multiPartRequest = await getMultiPartRequest(createOrderEndpoint);
      multiPartRequest.headers.addAll(buildHeaderTokens());

      multiPartRequest.fields['amount'] = totalAmount.toString();
      multiPartRequest.fields['booking_id'] = bookingId.toString();
      multiPartRequest.fields['transaction_id'] = txnId.toString();
      multiPartRequest.fields['mobile_number'] = _phoneNumberService.buildE164(
        mobileNumber: appStore.userContactNumber.validate(),
        countryCode: '',
      );
      multiPartRequest.fields['merchant_id'] = merchantId;
      multiPartRequest.fields['app_id'] = appId;
      multiPartRequest.fields['currency'] = currencyCode;
      if (callbackUrl != null && callbackUrl!.isNotEmpty) {
        multiPartRequest.fields['callback_url'] = callbackUrl!;
      }

      var response = await http.Response.fromStream(await multiPartRequest.send());
      final orderData = await handleResponse(response) as Map<String, dynamic>;

      String orderId = "";
      String merchantOrderId = "";
      String token = "";
      String phonePeMerchantId = merchantId;

      if (orderData.containsKey('data') && orderData['data'] is Map) {
        Map dataMap = orderData['data'];
        orderId = dataMap['orderId']?.toString() ?? dataMap['order_id']?.toString() ?? "";
        merchantOrderId = dataMap['merchantOrderId']?.toString() ?? dataMap['merchant_order_id']?.toString() ?? "";
        token = dataMap['token']?.toString() ?? "";
        if (dataMap.containsKey('merchantId')) phonePeMerchantId = dataMap['merchantId'].toString();
      }

      if (orderId.isEmpty) orderId = orderData['orderId']?.toString() ?? orderData['order_id']?.toString() ?? orderData['id']?.toString() ?? "";
      if (merchantOrderId.isEmpty) merchantOrderId = orderData['merchantOrderId']?.toString() ?? orderData['merchant_order_id']?.toString() ?? "";
      if (token.isEmpty) token = orderData['token']?.toString() ?? "";

      if (orderId.isEmpty || token.isEmpty) {
        throw "Order id or token is empty or not found in backend response";
      }

      String orderIdForVerification = merchantOrderId.isNotEmpty ? merchantOrderId : orderId;

      Map<String, dynamic> payload = {
        "orderId": orderId,
        "merchantId": phonePeMerchantId,
        "token": token,
        "paymentMode": {"type": "PAY_PAGE"} 
      };

      String request = jsonEncode(payload);

      appStore.setLoading(false);

      PhonePePaymentSdk.startTransaction(
        request,
        appSchema ?? "",
      ).then((response) async {
        await _handlePhonePeResponse(response, orderIdForVerification);
      }).catchError((error) {
        appStore.setLoading(false);
        toast("PhonePe payment failed: ${error.toString()}");
        onComplete({
          "status": 'payment_error',
          "error": error.toString(),
        });
      });
    } catch (e) {
      appStore.setLoading(false);
      toast("PhonePe payment failed: ${e.toString()}");
      onComplete({
        "status": 'payment_error',
        "error": e.toString(),
      });
    }
  }

  Future<void> _handlePhonePeResponse(Map<dynamic, dynamic>? response, String orderId) async {
    if (response != null) {
      String status = response['status']?.toString() ?? '';
      String error = response['error']?.toString() ?? '';

      await _verifyAndCompletePayment(status, error, orderId);
    } else {
      onComplete({
        "status": 'payment_error',
        "error": "No response from PhonePe SDK",
      });
    }
  }

  Future<Map<String, dynamic>?> _verifyOrder(String orderId, {int retryCount = 0}) async {
    try {
      final uri = Uri.parse('$BASE_URL$verifyOrderEndpoint').replace(
        queryParameters: {'order_id': orderId},
      );

      final response = await http.post(
        uri,
        headers: buildHeaderTokens(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data.isEmpty || (data is Map && data.keys.isEmpty)) {
          if (retryCount < maxVerificationRetries - 1) {
            await Future.delayed(Duration(seconds: 3));
            return await _verifyOrder(orderId, retryCount: retryCount + 1);
          }
          return {};
        }
        
        if (data.containsKey('state') && data['state']?.toString().toUpperCase() == 'PENDING') {
          if (retryCount < maxVerificationRetries - 1) {
            await Future.delayed(Duration(seconds: 3));
            return await _verifyOrder(orderId, retryCount: retryCount + 1);
          }
        }
        
        if (data.containsKey('code') && data['code']?.toString().toUpperCase() == 'PAYMENT_PENDING') {
          if (retryCount < maxVerificationRetries - 1) {
            await Future.delayed(Duration(seconds: 3));
            return await _verifyOrder(orderId, retryCount: retryCount + 1);
          }
        }
        
        return data;
      } else {
        throw Exception('Verification failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (retryCount < maxVerificationRetries) {
        await Future.delayed(Duration(seconds: 2));
        return await _verifyOrder(orderId, retryCount: retryCount + 1);
      } else {
        return null;
      }
    }
  }

  Future<void> _verifyAndCompletePayment(String sdkStatus, String error, String orderId) async {
    try {
      appStore.setLoading(true);
      
      await Future.delayed(Duration(seconds: 2));
      
      final verificationResult = await _verifyOrder(orderId);
      
      appStore.setLoading(false);

      if (verificationResult != null && verificationResult.isNotEmpty) {
        bool isVerified = false;
        String verificationStatus = '';
        String verificationMessage = '';

        if (verificationResult.containsKey('state')) {
          verificationStatus = verificationResult['state']?.toString().toUpperCase() ?? '';
          isVerified = verificationStatus == 'COMPLETED';
          
          if (verificationResult.containsKey('paymentDetails') && verificationResult['paymentDetails'] is List) {
            final paymentDetails = verificationResult['paymentDetails'] as List;
            if (paymentDetails.isNotEmpty) {
              final latestPayment = paymentDetails.last;
              verificationMessage = 'Transaction ID: ${latestPayment['transactionId'] ?? 'N/A'}';
            }
          }
        } else if (verificationResult.containsKey('code')) {
          verificationStatus = verificationResult['code']?.toString().toUpperCase() ?? '';
          verificationMessage = verificationResult['message']?.toString() ?? '';
          isVerified = verificationStatus == 'PAYMENT_SUCCESS';
        } else if (verificationResult.containsKey('data')) {
          final data = verificationResult['data'];
          if (data.containsKey('paymentState')) {
            verificationStatus = data['paymentState']?.toString().toUpperCase() ?? '';
            isVerified = verificationStatus == 'COMPLETED';
          } else {
            verificationStatus = data['status']?.toString().toUpperCase() ?? '';
            isVerified = _isSuccessStatus(verificationStatus);
          }
          verificationMessage = data['message']?.toString() ?? '';
        } else {
          verificationStatus = verificationResult['status']?.toString().toUpperCase() ?? '';
          verificationMessage = verificationResult['message']?.toString() ?? '';
          isVerified = _isSuccessStatus(verificationStatus);
        }

        if (sdkStatus == 'SUCCESS' && isVerified) {
          onComplete({
            "transactionId": txnId,
            "orderId": orderId,
            "merchantId": merchantId,
            "status": 'payment_success',
            "verificationStatus": verificationStatus,
          });
        } else if (sdkStatus == 'SUCCESS' && _isPendingStatus(verificationStatus)) {
          onComplete({
            "status": 'payment_pending',
            "transactionId": txnId,
            "orderId": orderId,
            "error": 'Payment is pending verification',
            "verificationStatus": verificationStatus,
          });
        } else if (sdkStatus == 'SUCCESS' && _isFailedStatus(verificationStatus)) {
          String errorMsg = verificationMessage.isNotEmpty 
              ? verificationMessage 
              : 'Payment failed during verification: $verificationStatus';
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": errorMsg,
            "verificationStatus": verificationStatus,
          });
        } else if (sdkStatus == 'SUCCESS' && !isVerified) {
          String errorMsg = verificationMessage.isNotEmpty 
              ? verificationMessage 
              : 'Payment verification mismatch: $verificationStatus';
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": errorMsg,
            "verificationStatus": verificationStatus,
          });
        } else if (sdkStatus == 'FAILURE') {
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": error.isNotEmpty ? error : 'Payment failed',
            "verificationStatus": verificationStatus,
          });
        } else if (sdkStatus == 'INTERRUPTED') {
          onComplete({
            "status": 'payment_cancelled',
            "transactionId": txnId,
            "orderId": orderId,
            "error": 'Payment interrupted by user',
            "verificationStatus": verificationStatus,
          });
        } else {
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": "Unknown status: $sdkStatus",
            "verificationStatus": verificationStatus,
          });
        }
      } else {
        if (sdkStatus == 'SUCCESS') {
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": 'Payment verification failed. Please check your transaction status or contact support.',
            "verificationStatus": 'VERIFICATION_FAILED',
          });
        } else if (sdkStatus == 'FAILURE') {
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": error.isNotEmpty ? error : 'Payment failed',
          });
        } else if (sdkStatus == 'INTERRUPTED') {
          onComplete({
            "status": 'payment_cancelled',
            "transactionId": txnId,
            "orderId": orderId,
            "error": 'Payment interrupted by user',
          });
        } else {
          onComplete({
            "status": 'payment_error',
            "transactionId": txnId,
            "orderId": orderId,
            "error": "Unknown status: $sdkStatus",
          });
        }
      }
    } catch (e) {
      appStore.setLoading(false);
      onComplete({
        "status": 'payment_error',
        "transactionId": txnId,
        "orderId": orderId,
        "error": 'Verification error: ${e.toString()}',
      });
    }
  }

  
  Future<void> _phonePeCheckoutWebView(BuildContext context, {bool isV2 = false}) async {
    try {
      Map<String, dynamic> requestData = {
        "amount": double.parse(totalAmount.toStringAsFixed(2)),
        "booking_id": bookingId,
        "transaction_id": txnId,
        "currency": currencyCode,
      };

      if (callbackUrl != null && callbackUrl!.isNotEmpty) {
        requestData['callback_url'] = callbackUrl!;
      }

      final response = await buildHttpResponse(
        isV2 ? initiateV2Endpoint : initiateEndpoint,
        method: HttpMethodType.POST,
        request: requestData,
      );

      final data = await handleResponse(response) as Map<String, dynamic>;

      String redirectUrl = "";
      if (isV2) {
        redirectUrl = data['redirectUrl'];
      } else {
        redirectUrl = data['data']?['instrumentResponse']?['redirectInfo']?['url']?.toString() ?? "";
      }

      if (redirectUrl.isEmpty) {
        throw Exception("Invalid redirect URL in backend response: ${response.body}");
      }

      appStore.setLoading(false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhonePeWebViewPage(
            redirectUrl: redirectUrl,
            transactionId: txnId,
            onComplete: onComplete,
          ),
        ),
      );
    } catch (e) {
      appStore.setLoading(false);
      rethrow;
    }
  }
}
