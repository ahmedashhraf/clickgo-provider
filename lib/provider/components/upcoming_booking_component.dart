import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/booking_list_response.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/booking_item_component.dart';
import '../../components/view_all_label_component.dart';
import '../../utils/constant.dart';

class UpcomingBookingComponent extends StatefulWidget {
  final List<BookingData> bookingData;

  const UpcomingBookingComponent({required this.bookingData});

  @override
  State<UpcomingBookingComponent> createState() =>
      _UpcomingBookingComponentState();
}

class _UpcomingBookingComponentState extends State<UpcomingBookingComponent> {
  late List<BookingData> _upcomingBookingData;

  @override
  void initState() {
    super.initState();
    _upcomingBookingData = List<BookingData>.from(widget.bookingData);
  }

  @override
  void didUpdateWidget(covariant UpcomingBookingComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bookingData, widget.bookingData)) {
      _upcomingBookingData = List<BookingData>.from(widget.bookingData);
    }
  }

  void _onBookingStatusUpdated(int bookingId, String updatedStatus) {
    if (updatedStatus != BOOKING_STATUS_REJECTED &&
        updatedStatus != BOOKING_STATUS_CANCELLED) {
      return;
    }

    setState(() {
      _upcomingBookingData.removeWhere((element) => element.id == bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_upcomingBookingData.isEmpty) return const Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        ViewAllLabel(
          label: languages.upcomingBookings,
          list: _upcomingBookingData,
          onTap: () {
            LiveStream().emit(LIVESTREAM_PROVIDER_ALL_BOOKING, 1);
            // LiveStream().emit(LIVESTREAM_HANDYMAN_ALL_BOOKING, 1);
            LiveStream().emit(LIVESTREAM_CHANGE_HANDYMAN_TAB, {"index": 1});
          },
        ),
        8.height,
        AnimatedListView(
          itemCount: _upcomingBookingData.length,
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) => BookingItemComponent(
            bookingData: _upcomingBookingData[i],
            showDescription: false,
            index: i,
            onBookingStatusUpdated: _onBookingStatusUpdated,
          ),
        ),
      ],
    ).paddingSymmetric(horizontal: 16);
  }
}
