import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teaching_question_wheel/question.dart';
import 'package:teaching_question_wheel/question_wheel_data.dart';
import 'package:teaching_question_wheel/question_wheel_picture_settings_dialog.dart';
import 'package:teaching_question_wheel/question_wheel_settings_dialog.dart';
import 'package:teaching_question_wheel/video_viewer.dart';
import 'package:teaching_question_wheel/wheel_widget.dart';

void main() => runApp(new JesusWheel());

class JesusWheel extends StatelessWidget {

  static const appName = 'Soul Questions';
  static const defaultPicture = 'jesus';

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
          primaryColor: Colors.yellow[200],
          accentColor: Colors.yellowAccent[100],
          pageTransitionsTheme: PageTransitionsTheme(builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder()
          })),
      home: new QuestionWheelPage(title: appName),
    );
  }
}

class QuestionWheelPage extends StatefulWidget {
  QuestionWheelPage({Key key, this.title}) : super(key: key);

  final String title;


  @override
  _QuestionWheelPageState createState() => new _QuestionWheelPageState();
}

class _QuestionWheelPageState extends State<QuestionWheelPage>
    with SingleTickerProviderStateMixin {
  QuestionWheelData questionWheelData;
  int questionCount = 5;
  String picture;
  bool editingPicture = true;
  Animation<double> animation;
  AnimationController controller;
  Timer _timer;

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this);
    animation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(
          curve: Cubic(0.0, .99, .02, 1.00),
        ))
        .animate(controller)
          ..addListener(() {
            setState(() {
              // the state that has changed here is the animation object’s value
            });
          });

    _loadData();

    super.initState();
  }

  void _runLoadedSpinAnimation() async {
    try {
      await controller.forward();
    } catch (e) {}
    controller.reset();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _loadQuestions(prefs);
    _loadJesus(prefs);
  }

  void _loadQuestions(SharedPreferences prefs) {
    List<String> titles;
    List<String> paths;
    try {
      titles = prefs.getStringList("questionTitles");
      paths = prefs.getStringList("questionFilePaths");
    } catch (e) {
      print(e);
      return;
    }

    if ((titles == null || paths == null || titles.length != paths.length)) {
      _updateQuestions(QuestionWheelData(null));
      return;
    }

    int savedQuestionCount = titles.length;
    List<Question> questions = new List<Question>();

    for (int i = 0; i < savedQuestionCount; i++) {
      File file = paths[i] == "" ? null : new File(paths[i]);

      questions.add(Question(titles[i], file));
    }

    setState(() {
      _timer = new Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _updateQuestions(QuestionWheelData(questions));
          _runLoadedSpinAnimation();
        });
      });
    });
  }

  void _loadJesus(SharedPreferences prefs) {
    String savedPicture;

    try {
      savedPicture = prefs.getString(JesusWheel.defaultPicture);
    } catch (e) {
      print(e);
      return;
    }

    if (savedPicture == null || savedPicture.isEmpty) {
      _updatePicture(JesusWheel.defaultPicture);
      return;
    }

    setState(() {
      picture = savedPicture;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle questionStyle = Theme.of(context)
        .textTheme
        .subhead
        .copyWith(fontWeight: FontWeight.w500);

    Orientation orientation = MediaQuery.of(context).orientation;

    ThemeData theme = Theme.of(context);

    List<Widget> loadedWidgets = [
      AspectRatio(
          aspectRatio: 1.0,
          child: Stack(alignment: Alignment.center, children: <Widget>[
            questionWheelData == null || questionWheelData.questions == null
                ? Container()
                : SizedBox.expand(
                    child: Transform.rotate(
                    angle: animation.value * 4 * pi,
                    child: WheelWidget(
                      spokes: questionCount,
                      orientation: orientation,
                    ),
                  )),
            FractionallySizedBox(
              widthFactor: 0.35,
              heightFactor: 0.35,
              child: Stack(
                children: <Widget>[
                  Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white)),
                  Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: AssetImage(
                                  "assets/images/${picture != null ? picture : JesusWheel.defaultPicture}.jpg")))),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      radius: 5.0,
                      highlightColor: Colors.white.withAlpha(25),
                      splashColor: Colors.transparent,
                      customBorder: CircleBorder(),
                      onLongPress: () => _openPictureSettingsDialog(),
                    ),
                  ),
                ],
              ),
            ),
          ])),
    ];

    Widget loadingWidget = Container(
      child: Center(
          child: Theme(
              data: Theme.of(context).copyWith(accentColor: Colors.white),
              child: SizedBox.fromSize(
                  size: Size.square(180.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                  )))),
    );

    Widget emptyWidget = Align(
      alignment: Alignment.bottomRight,
      child: Theme(
        data: Theme.of(context).copyWith(accentColor: Colors.white),
        child: Padding(
          padding: EdgeInsets.only(bottom: 38.0, right: 100.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Click the pencil icon to add questions"),
              Icon(Icons.arrow_right)
            ],
          ),
        ),
      ),
    );

    if (questionWheelData != null && questionWheelData.questions != null) {
      loadedWidgets.add(Stack(children: _buildQuestions(questionStyle)));
    } else if (questionWheelData != null &&
        questionWheelData.questions == null) {
      loadedWidgets.add(emptyWidget);
    } else {
      loadedWidgets.add(loadingWidget);
    }

    Widget editOverlay = SizedBox.expand(
        child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withAlpha(25),
                    shape: BoxShape.circle),
                child: Material(
                  color: Colors.transparent,
                  child: InkResponse(
                    radius: 24.0,
                    onTap: _openSettingsDialog,
                    child: Opacity(
                      opacity: 0.15,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Icon(Icons.edit),
                      ),
                    ),
                  ),
                ),
              ),
            )));

    List<Widget> stack = loadedWidgets;

    if (questionWheelData != null) {
      stack.add(editOverlay);
    }

    return Scaffold(
      backgroundColor: editingPicture ? Colors.green[200] : null,
      body: Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
                colors: [Colors.white, Colors.yellow, Colors.white],
                stops: [0.1, 0.2, 1.0],
                radius: 1.1)),
        child: Center(
            child: Stack(
          alignment: Alignment.center,
          children: stack,
        )),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> _buildQuestions(TextStyle questionStyle) {
    List<Widget> questions = new List<Widget>();

    for (int i = 0; i < questionCount; i++) {
      questions.add(buildQuestionText(questionStyle, i));
    }

    return questions;
  }

  Widget buildQuestionText(TextStyle questionStyle, int questionIndex) {
    double tau = 2 * pi;

    Orientation orientation = MediaQuery.of(context).orientation;
    double density = MediaQuery.of(context).devicePixelRatio;

    double startAngle = questionCount < 3
        ? orientation == Orientation.portrait ? pi * 2 : pi
        : pi;

    double animationAngle = (animation.value * 4 * pi);

    return SizedBox.expand(
      child: Transform.rotate(
        angle: animationAngle +
            (startAngle / questionCount) +
            (questionIndex * tau / questionCount),
        child: Transform.translate(
          offset: Offset(0.0, -200.0 + (24 * density)),
          child: Transform.rotate(
            angle: -animationAngle +
                (-startAngle / questionCount) -
                (questionIndex * tau / questionCount),
            child: FractionallySizedBox(
              widthFactor: orientation == Orientation.landscape ? 0.18 : 0.30,
              heightFactor: orientation == Orientation.landscape ? 0.28 : 0.15,
              child: Container(
                width: 150.0,
                height: 150.0,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  child: InkWell(
                    splashColor: Colors.white,
                    highlightColor: Colors.yellowAccent.shade100.withAlpha(128),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    onTap: () => _handleQuestionTap(questionIndex),
                    child: Center(
                        child: Opacity(
                      opacity:
                          questionWheelData.questions[questionIndex].media !=
                                  null
                              ? 1.0
                              : 0.25,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 3,
                        children: <Widget>[
                          if (questionWheelData.questions[questionIndex].media ==
                              null)
                            Icon(Icons.videocam_off),
                          Text(
                            questionWheelData.questions[questionIndex].text,
                            style: questionStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateQuestions(QuestionWheelData data) async {
    if (data.questions != null) {
      final prefs = await SharedPreferences.getInstance();

      List<String> titles = [];
      List<String> paths = [];

      for (Question question in data.questions) {
        titles.add(question.text);
        paths.add(question.media != null ? question.media.path : "");
      }

      try {
        await prefs.setStringList("questionTitles", titles);
        await prefs.setStringList("questionFilePaths", paths);
      } catch (e) {
        print(e);
      }
    }

    setState(() {
      questionWheelData = data;
      if (questionWheelData.questions != null) {
        questionCount = questionWheelData.questions.length;
      }
    });
  }

  void _updatePicture(String newPicture) async {
    if (newPicture == null || newPicture.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(JesusWheel.defaultPicture, newPicture);

    setState(() {
      picture = newPicture;
    });
  }

  void _handleQuestionTap(int questionIndex) {
    if (questionWheelData.questions[questionIndex].media == null) {
      _openSettingsDialog();
    } else {
      _viewVideo(questionWheelData.questions[questionIndex].media.path);
    }
  }

  void _viewVideo(String path) async {
    await Navigator.of(context).push(new MaterialPageRoute<String>(
        builder: (BuildContext context) {
          return VideoViewer(path);
        },
        fullscreenDialog: true));
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void _openPictureSettingsDialog() async {
    String data =
        await Navigator.of(context).push(new MaterialPageRoute<String>(
            builder: (BuildContext context) {
              return new QuestionWheelPictureSettingsDialog(
                  initialPicture: picture);
            },
            fullscreenDialog: true));

    SystemChrome.setEnabledSystemUIOverlays([]);

    if (data != null && data.isNotEmpty) {
      _updatePicture(data);
    }
  }

  void _openSettingsDialog() async {
    QuestionWheelData data = await Navigator.of(context)
        .push(new MaterialPageRoute<QuestionWheelData>(
            builder: (BuildContext context) {
              return new QuestionWheelSettingsDialog(
                  initialData: questionWheelData);
            },
            fullscreenDialog: true));

    SystemChrome.setEnabledSystemUIOverlays([]);

    if (data != null) {
      if (data.questions.length == 0) {
        data = QuestionWheelData(null);
      }
      _updateQuestions(data);
    }
  }

  void _toggleEditing() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      editingPicture = !editingPicture;
    });
  }
}
