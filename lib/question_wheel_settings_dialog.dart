import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';
import 'package:teaching_question_wheel/question.dart';
import 'package:teaching_question_wheel/question_wheel_data.dart';

class QuestionWheelSettingsDialog extends StatefulWidget {
  final QuestionWheelData initialData;

  QuestionWheelSettingsDialog({Key key, QuestionWheelData initialData})
      : assert(initialData != null),
        this.initialData = initialData.questions == null
            ? new QuestionWheelData([Question("", null)])
            : initialData,
        super(key: key);

  @override
  QuestionWheelSettingsDialogState createState() =>
      new QuestionWheelSettingsDialogState();
}

class QuestionWheelSettingsDialogState
    extends State<QuestionWheelSettingsDialog> with TickerProviderStateMixin {

  List<_QuestionInputListItem> _questionListItems;

  @override
  void initState() {
    int index = -1;

    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    setState(() {
      _questionListItems = widget.initialData.questions
          .map<_QuestionInputListItem>((Question question) {
        index++;
        return _QuestionInputListItem(
            question.text,
            question.media,
            index,
            new TextEditingController(text: question.text),
            AnimationController(
              duration: new Duration(milliseconds: 200),
              vsync: this,
            ));
      }).toList();
    });

    super.initState();
  }

  @override
  void dispose() {
    for (_QuestionInputListItem _questionInputListItem in _questionListItems) {
      _questionInputListItem.animationController.dispose();
      _questionInputListItem.textEditingController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    return _buildFormWrapper(themeData, context);
  }

  void _popQuestionsDialog(bool saveQuestions) {
    List<Question> questions = _questionListItems
        .where((_QuestionInputListItem questionListItem) =>
            questionListItem.text.isNotEmpty)
        .map<Question>(
            (_QuestionInputListItem item) => new Question(item.text, item.file))
        .toList();

    SystemChrome.setEnabledSystemUIOverlays([]);

    Navigator.of(context)
        .pop(saveQuestions ? new QuestionWheelData(questions) : null);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _QuestionInputListItem item = _questionListItems.removeAt(oldIndex);
      _questionListItems.insert(newIndex, item);
    });
  }

  void _deleteItem(_QuestionInputListItem item) {
    setState(() {
      _questionListItems.remove(item);
    });
  }

  void _addItem() {
    setState(() {
      _questionListItems.add(_QuestionInputListItem(
          "",
          null,
          _questionListItems.length,
          TextEditingController(),
          new AnimationController(
            duration: new Duration(milliseconds: 200),
            vsync: this,
          )));
    });
  }

  Widget _buildQuestionInputTile(_QuestionInputListItem item) {
    Widget listTile = QuestionInputListTile(
      key: Key(item.index.toString()),
      text: item.text,
      file: item.file,
      animationController: item.animationController,
      textEditingController: item.textEditingController,
      onDeleted: () => _deleteItem(item),
      onChanged: (Question newValue) {
        setState(() {
          item.text = newValue.text;
          item.file = newValue.media;
        });
      },
    );

    item.animationController.forward();

    return listTile;
  }

  Scaffold _buildFormWrapper(ThemeData theme, BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addItem(),
          child: Icon(Icons.add),
        ),
        bottomNavigationBar: BottomSheet(
            builder: (BuildContext context) => Container(
                  color: theme.textTheme.body1.color,
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        RichText(
                            text: TextSpan(
                                style: theme.textTheme.subhead.copyWith(
                                    color:
                                        ThemeData.dark().textTheme.body1.color),
                                children: [
                              TextSpan(text: "Click "),
                              WidgetSpan(
                                  child: Transform.translate(
                                      offset: Offset(0, 2),
                                      child: Icon(
                                        Icons.videocam,
                                        color: ThemeData.dark()
                                            .textTheme
                                            .body1
                                            .color,
                                      ))),
                              TextSpan(
                                  text: " to add a video to a question"),
                            ]))
                      ],
                    ),
                  ),
                ),
            onClosing: () => null),
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
                          onCancelPressed: () => _popQuestionsDialog(false),
                          onSubmitPressed: () => _popQuestionsDialog(true),
                          title: 'Edit questions')),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    sliver: ReorderableSliverList(
                      delegate: ReorderableSliverChildListDelegate(
                          _questionListItems
                              .map<Widget>(_buildQuestionInputTile)
                              .toList()),
                      onReorder: _onReorder,
                    ),
                  )
                ],
              ),
            ],
          )),
        ));
  }
}

class _QuestionInputListItem {
  int index;
  String text;
  File file;
  TextEditingController textEditingController;
  AnimationController animationController;

  _QuestionInputListItem(this.text, this.file, this.index,
      this.textEditingController, this.animationController);
}

class QuestionInputListTile extends StatelessWidget {
  final String text;
  final File file;

  final ValueChanged<Question> onChanged;
  final VoidCallback onDeleted;
  final TextEditingController textEditingController;

  final AnimationController animationController;

  final Animatable<double> _scaleTween = Tween<double>(
    begin: 0.8,
    end: 1,
  ).chain(CurveTween(
    curve: Cubic(0.0, 0.99, 0.99, 1.0),
  ));

  QuestionInputListTile(
      {Key key,
      this.text,
      this.file,
      this.onChanged,
      this.onDeleted,
      this.textEditingController,
      this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animationController.drive(_scaleTween),
      child: FadeTransition(
        opacity:
            CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        child: ListTile(
          leading: Icon(Icons.drag_handle),
          title: new TextField(
            maxLines: 4,
            maxLength: 110,
            decoration: InputDecoration(
                hintText: "Write a question...",
                border: UnderlineInputBorder(),
                filled: true),
            controller: textEditingController,
            onChanged: (value) => onChanged(Question(value, file)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: InkResponse(
                    onTap: () => _handleDeleteButtonClicked(),
                    child: Icon(
                      Icons.delete,
                    )),
              ),
              IconButton(
                icon: InkResponse(
                    onTap: () => _handleFileButtonClicked(),
                    onLongPress: () => _cancelFile(),
                    child: Icon(
                      Icons.videocam,
                      color: file == null ? Colors.red : Colors.green,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleDeleteButtonClicked() {
    onDeleted();
  }

  void _cancelFile() {
    onChanged(Question(text, null));
  }

  void _handleFileButtonClicked() async {
    File video;
    try {
      video = await ImagePicker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      rethrow;
    }
    onChanged(Question(text, video));
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
