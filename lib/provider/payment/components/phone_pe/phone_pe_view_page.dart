import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PhonePeWebViewPage extends StatefulWidget {
  final String redirectUrl;
  final String transactionId;
  final Function(Map<String, dynamic>) onComplete;

  const PhonePeWebViewPage({
    Key? key,
    required this.redirectUrl,
    required this.transactionId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PhonePeWebViewPage> createState() => _PhonePeWebViewPageState();
}

class _PhonePeWebViewPageState extends State<PhonePeWebViewPage> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            if (url.contains('payment/success') || url.contains('status=success') || url.contains('payment_success')) {
              widget.onComplete({
                'transactionId': widget.transactionId,
                'status': 'payment_success',
              });
              finish(context);
              return NavigationDecision.prevent;
            }

            if (url.contains('payment/failure') || url.contains('status=failure') || url.contains('payment_failed')) {
              widget.onComplete({
                'transactionId': widget.transactionId,
                'status': 'payment_error',
                'error': 'Payment failed',
              });
              finish(context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhonePe Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onComplete({
              'transactionId': widget.transactionId,
              'status': 'payment_cancelled',
              'error': 'Payment cancelled by user',
            });
            finish(context);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
