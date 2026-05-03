import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/user_data.dart';
import 'package:handyman_provider_flutter/screens/chat/components/last_messege_chat.dart';
import 'package:handyman_provider_flutter/screens/chat/user_chat_screen.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/shimmer/shimmer.dart';
import 'package:nb_utils/nb_utils.dart';

class UserItemWidget extends StatefulWidget {
  final String userUid;

  UserItemWidget({super.key, required this.userUid});

  @override
  State<UserItemWidget> createState() => _UserItemWidgetState();
}

class _UserItemWidgetState extends State<UserItemWidget>
    with AutomaticKeepAliveClientMixin {
  late Stream<UserData> _userStream;
  late Stream<int> _unReadCountStream;
  late Stream<QuerySnapshot> _lastMessageStream;

  @override
  void initState() {
    super.initState();
    _bindStreams();
  }

  @override
  void didUpdateWidget(covariant UserItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userUid != widget.userUid) {
      _bindStreams();
    }
  }

  void _bindStreams() {
    _userStream = userService.singleUser(widget.userUid);
    _unReadCountStream = chatServices.getUnReadCount(
      senderId: appStore.uid.validate(),
      receiverId: widget.userUid,
    );
    _lastMessageStream = chatServices.fetchLastMessageBetween(
      senderId: appStore.uid.validate(),
      receiverId: widget.userUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<UserData>(
        stream: _userStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for data
            final baseColor = appStore.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade300;

            final highlightColor = appStore.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade100;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile shimmer
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                height: 14,
                                width: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Shimmer.fromColors(
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                          child: Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          if (snap.hasError || !snap.hasData || snap.data == null) {
            return const SizedBox.shrink();
          }
          UserData data = snap.data!;
          return InkWell(
            onTap: () {
              UserChatScreen(receiverUser: data).launch(context,
                  pageRouteAnimation: PageRouteAnimation.Fade,
                  duration: 300.milliseconds);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (data.profileImage.validate().isEmpty)
                    Container(
                      height: 40,
                      width: 40,
                      padding: const EdgeInsets.all(10),
                      color: context.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        data.displayName.validate()[0].validate().toUpperCase(),
                        style: boldTextStyle(color: context.primaryColor),
                      ).center().fit(),
                    ).cornerRadiusWithClipRRect(50)
                  else
                    CachedImageWidget(
                        url: data.profileImage.validate(),
                        height: 40,
                        circle: true,
                        fit: BoxFit.cover),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data.firstName.validate() +
                                " " +
                                data.lastName.validate(),
                            style: boldTextStyle(),
                            maxLines: 1,
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                          ).expand(),
                          StreamBuilder<int>(
                            stream: _unReadCountStream,
                            builder: (context, snap) {
                              if (snap.hasData && snap.data != 0) {
                                return Container(
                                  height: 18,
                                  width: 18,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: primaryColor),
                                  child: Text(
                                    snap.data.validate().toString(),
                                    style: secondaryTextStyle(color: white),
                                    textAlign: TextAlign.center,
                                  ).center(),
                                );
                              }
                              return const Offstage();
                            },
                          ),
                        ],
                      ),
                      LastMessageChat(stream: _lastMessageStream),
                    ],
                  ).expand()
                ],
              ),
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
