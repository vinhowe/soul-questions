import 'dart:io';

class Question {
  final String text;
  final File media;

  Question(this.text, this.media) : assert(text != null);
}