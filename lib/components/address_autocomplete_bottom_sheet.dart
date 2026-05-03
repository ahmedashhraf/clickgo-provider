import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/google_places_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:nb_utils/nb_utils.dart';

/// Bottom sheet with Google Places Autocomplete. Returns a map with
/// 'address', 'latitude', 'longitude' when user selects a place.
Future<Map<String, dynamic>?> showAddressAutocompleteBottomSheet(
  BuildContext context, {
  String? initialAddress,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    backgroundColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    shape: RoundedRectangleBorder(
      borderRadius: radiusOnly(
        topLeft: defaultRadius,
        topRight: defaultRadius,
      ),
    ),
    builder: (context) => AddressAutocompleteBottomSheet(
      initialAddress: initialAddress,
    ),
  );
}

class AddressAutocompleteBottomSheet extends StatefulWidget {
  final String? initialAddress;

  const AddressAutocompleteBottomSheet({super.key, this.initialAddress});

  @override
  State<AddressAutocompleteBottomSheet> createState() => _AddressAutocompleteBottomSheetState();
}

class _AddressAutocompleteBottomSheetState extends State<AddressAutocompleteBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<GooglePlacesModel> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
      _fetchSuggestions(widget.initialAddress!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final list = await getSuggestion(input);
      if (mounted) {
        setState(() {
          _suggestions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        toast(e.toString());
      }
    }
  }

  Future<void> _onPlaceSelected(GooglePlacesModel place) async {
    final placeId = place.placeId;
    if (placeId == null || placeId.isEmpty) {
      toast(languages.lblFailedToLoadPredictions);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final details = await getPlaceDetails(placeId);
      if (mounted && details != null) {
        Navigator.of(context).pop(details);
      } else if (mounted) {
        setState(() => _isLoading = false);
        toast(languages.lblFailedToLoadPredictions);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        toast(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radiusOnly(
              topLeft: defaultRadius,
              topRight: defaultRadius,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  languages.hintAddress,
                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AppTextField(
                  textFieldType: TextFieldType.OTHER,
                  controller: _searchController,
                  focus: _searchFocus,
                  decoration: inputDecoration(
                    context,
                    hint: languages.lblSearchHere,
                    fillColor: context.scaffoldBackgroundColor,
                  ),
                  suffix: Image.asset(ic_location, width: 18, height: 18, color: context.iconColor).paddingAll(14),
                  onChanged: _onSearchChanged,
                ),
              ),
              Flexible(
                child: _isLoading ? LoaderWidget().center() : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    final mainText = place.structuredFormatting?.mainText ?? place.description ?? '';
                    final secondaryText = place.structuredFormatting?.secondaryText ?? '';
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: context.iconColor, size: 22),
                      title: Text(
                        mainText,
                        style: primaryTextStyle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: secondaryText.isNotEmpty
                          ? Text(
                              secondaryText,
                              style: secondaryTextStyle(size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => _onPlaceSelected(place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
