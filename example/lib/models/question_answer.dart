class QuestionAnswer {
  final String question;
  final StringBuffer answer;
  List<String>? imgUrls;

  QuestionAnswer({
    required this.question,
    required this.answer,
    this.imgUrls,
  });

  bool isImagesEmpty() {
    return imgUrls == null || imgUrls!.isEmpty;
  }

  QuestionAnswer copyWith({
    String? newQuestion,
    StringBuffer? newAnswer,
    List<String>? newImgUrls,
  }) {
    return QuestionAnswer(
      question: newQuestion ?? question,
      answer: newAnswer ?? answer,
      imgUrls: newImgUrls ?? imgUrls,
    );
  }
}
