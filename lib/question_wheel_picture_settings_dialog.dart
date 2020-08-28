import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

class QuestionWheelPictureSettingsDialog extends StatefulWidget {
  final String initialPicture;

  static const List<String> pictures = [
    "jesus",
    "jesus-alt",
    "jesus-alt-2",
    "jesus-lamb",
  ];

  QuestionWheelPictureSettingsDialog({Key key, String initialPicture})
      : assert(initialPicture != null),
        this.initialPicture = initialPicture == null || initialPicture.isEmpty
            ? JesusWheel.defaultPicture
            : initialPicture,
        super(key: key);

  @override
  QuestionWheelPictureSettingsDialogState createState() =>
      new QuestionWheelPictureSettingsDialogState();
}

class QuestionWheelPictureSettingsDialogState
    extends State<QuestionWheelPictureSettingsDialog>
    with TickerProviderStateMixin {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  String picture;

  @override
  void initState() {
    picture = widget.initialPicture;

    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    return _buildDialogContents(themeData, context);
  }

  void _popPictureDialog(bool savePicture) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    Navigator.of(context).pop(savePicture ? picture : null);
  }

  Widget _buildPictureTile(String tilePicture) {
    return Stack(
      children: <Widget>[
        Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: picture == tilePicture
                    ? Border.all(color: Colors.yellow, width: 5)
                    : null,
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage("assets/images/$tilePicture.jpg")))),
        Material(
          color: Colors.transparent,
          child: InkWell(
            radius: 5.0,
            highlightColor: Colors.white.withAlpha(25),
            splashColor: Colors.transparent,
            customBorder: CircleBorder(),
            onTap: () => _pickPicture(tilePicture),
          ),
        ),
      ],
    );
  }

  void _pickPicture(String pickedPicture) {
    setState(() {
      picture = pickedPicture;
    });
    _popPictureDialog(true);
  }

  Scaffold _buildDialogContents(ThemeData theme, BuildContext context) {
    return Scaffold(
        body: Builder(
      builder: (_) => Container(
          child: Stack(
        children: <Widget>[
          CustomScrollView(
            primary: true,
            slivers: <Widget>[
              SliverPersistentHeader(
                  pinned: true,
                  delegate: FormTitleBarDelegate(
                      onCancelPressed: () => _popPictureDialog(false),
                      title: 'Pick a picture')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                ),
                sliver: SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate(
                        QuestionWheelPictureSettingsDialog.pictures
                            .map<Widget>(_buildPictureTile)
                            .toList()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16),
                  ),
                ),
              )
            ],
          ),
        ],
      )),
    ));
  }
}

class FormTitleBarDelegate extends SliverPersistentHeaderDelegate {
  FormTitleBarDelegate(
      {@required this.title,
      this.onCancelPressed,
      this.onSubmitPressed,
      this.cancelIcon = Icons.close});

  final String title;
  final VoidCallback onCancelPressed;
  final VoidCallback onSubmitPressed;
  final IconData cancelIcon;

  static const Offset collapsedTitleOffsetTopLeft = Offset(72.0, 16.0);
  static const Offset expandedTitleOffsetBottomLeft = Offset(16.0, 32.0);
  static const double collapsedFadeBlur = 20.0;
  static const double collapsedFadeHeight = 10;
  static const double magicNumberThatPreventsToolbarFromCollapsingTooFar = 4;

  // Height of expanded portion of toolbar
  static const double expandedToolbarSize = 96.0;

  @override
  double get minExtent =>
      kToolbarHeight +
      (collapsedFadeHeight * 2) +
      magicNumberThatPreventsToolbarFromCollapsingTooFar;

  @override
  double get maxExtent => kToolbarHeight + expandedToolbarSize;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double expandedRatio =
        min(max(1 - shrinkOffset / (maxExtent - minExtent), 0), 1);

    final double curvedExpandedRatio =
        Curves.easeInOut.transform(expandedRatio);

    final ThemeData themeData = Theme.of(context);
    final TextStyle titleCollapsedTextStyle = themeData.textTheme.title;
    final TextStyle titleExpandedTextStyle = themeData.textTheme.display1;

    final double height = max(maxExtent - shrinkOffset, minExtent);

    final TextStyle lerpedTitleStyle = titleCollapsedTextStyle.copyWith(
        fontSize: lerpDouble(titleCollapsedTextStyle.fontSize,
            titleExpandedTextStyle.fontSize, curvedExpandedRatio),
        fontWeight: FontWeight.bold);

    final double topBarHeight = MediaQuery.of(context).padding.top;

    final double yTitleOffset = (maxExtent -
            lerpedTitleStyle.fontSize -
            topBarHeight -
            collapsedTitleOffsetTopLeft.dy -
            expandedTitleOffsetBottomLeft.dy) *
        curvedExpandedRatio;

    final double xTitleOffset =
        (collapsedTitleOffsetTopLeft.dy - collapsedTitleOffsetTopLeft.dx) *
            curvedExpandedRatio;

    final double dynamicFadeHeight =
        collapsedFadeBlur * (1 - curvedExpandedRatio);
    final double dynamicFadeYOffset =
        collapsedFadeHeight * (1 - curvedExpandedRatio);

    return PreferredSize(
      preferredSize: Size.fromHeight(height * 2),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: themeData.iconTheme.copyWith(color: Colors.black),
        leading: onCancelPressed != null
            ? IconButton(icon: Icon(cancelIcon), onPressed: onCancelPressed)
            : null,
        actions: onSubmitPressed != null
            ? <Widget>[
                Tooltip(
                  message: 'Submit',
                  child: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: onSubmitPressed,
                  ),
                ),
              ]
            : null,
        flexibleSpace: Stack(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: <Color>[
                    Colors.yellow[200],
                    Colors.yellow[200].withOpacity(1),
                    Colors.yellow[200].withOpacity(0),
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.yellow[200],
                        blurRadius: dynamicFadeHeight,
                        spreadRadius: dynamicFadeYOffset)
                  ]),
              child: SizedBox.fromSize(
                size:
                    Size.fromHeight(height + topBarHeight + dynamicFadeYOffset),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    top: collapsedTitleOffsetTopLeft.dy,
                    left: collapsedTitleOffsetTopLeft.dx),
                child: Transform.translate(
                    offset: Offset(xTitleOffset, yTitleOffset),
                    child: Text(
                      title,
                      softWrap: false,
                      style: lerpedTitleStyle,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant FormTitleBarDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}
