import 'package:teaching_question_wheel/question.dart';

class QuestionWheelData {
  final List<Question> questions;

  QuestionWheelData(this.questions);

  QuestionWheelData withQuestion(Question question) {
    List<Question> questions = this.questions;
    questions.add(question);
    return new QuestionWheelData(questions);
  }

  QuestionWheelData insertQuestion(Question question, int index) {
    if (this.questions.length < index) {
      throw RangeError(
          "Cannot insert question at index greater than array length: Index is $index, but questions length is ${this.questions.length}");
    }

    List<Question> questions = this.questions;
    questions[index] = question;
    return new QuestionWheelData(questions);
  }
}
