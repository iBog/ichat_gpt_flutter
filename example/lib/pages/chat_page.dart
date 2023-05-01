import 'dart:async';
import 'dart:developer';

import 'package:chat_gpt_flutter/chat_gpt_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../models/question_answer.dart';
import '../tools/utils.dart';

const apiKey = 'GPT API KEY';
const double chatMessageRadius = 16.0;
const double avatarSize = 48.0;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // String? answer;
  final chatGpt = ChatGpt(apiKey: apiKey);
  bool loading = false;
  final ScrollController scrollController = ScrollController();
  final List<QuestionAnswer> questionAnswers = [];
  late TextEditingController textEditingController;
  StreamSubscription<StreamCompletionResponse>? streamSubscription;

  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChatGPT")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: questionAnswers.length,
                  itemBuilder: (context, index) {
                    return _buildChatLine(questionAnswers[index]);
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: textEditingController,
                      decoration: const InputDecoration(hintText: 'Type in...'),
                      onFieldSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipOval(
                    child: Material(
                      color: Colors.blue, // Button color
                      child: InkWell(
                        onTap: _sendMessage,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 64.0),
        child: FloatingActionButton.small(
          onPressed: _scrollDown,
          child: const Icon(Icons.arrow_downward),
        ),
      ),
    );
  }

  void _scrollDown() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget _buildChatLine(QuestionAnswer questionAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMyMessage(questionAnswer.question),
        const SizedBox(height: 12),
        if (questionAnswer.question.isEmpty && loading)
          const Center(child: CircularProgressIndicator())
        else
          _buildGptMessage(questionAnswer.answer.toString()),
        if (!questionAnswer.isImagesEmpty())
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200.0,
                height: 200.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(questionAnswer.imgUrls!.first),
                    fit: BoxFit.contain,
                  ),
                  color: Colors.red,
                ),
              ),
              InkWell(
                child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8.0)),
                    child: const Icon(Icons.save, color: Colors.white)),
                onTap: () async {
                  Utils.saveImageFromUrl(
                      context,
                      questionAnswer.imgUrls!.first,
                      questionAnswer.question
                          .replaceFirst('generate image: ', ''));
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMyMessage(String message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          child: Text("You"),
        ),
        const SizedBox(width: 16.0),
        Container(
          margin: const EdgeInsets.only(top: 8.0),
          decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius:
                  BorderRadius.all(Radius.circular(chatMessageRadius))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        _buildShareIcons(message),
      ],
    );
  }

  Widget _buildGptMessage(String message) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (message.isNotEmpty) _buildShareIcons(message),
        if (message.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius:
                    BorderRadius.all(Radius.circular(chatMessageRadius))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        const SizedBox(width: 16.0),
        Container(
          margin: const EdgeInsets.only(right: 16.0),
          child: SvgPicture.asset(
            'assets/images/chat_gpt_logo.svg',
            semanticsLabel: 'GPT Logo',
            height: avatarSize,
            width: avatarSize,
          ),
        ),
      ],
    );
  }

  _sendMessage() async {
    final question = textEditingController.text;
    if (question.toLowerCase().startsWith('generate image: ')) {
      setState(() {
        textEditingController.clear();
        loading = true;
        questionAnswers.add(
          QuestionAnswer(
            question: question,
            answer: StringBuffer(),
          ),
        );
      });
      String prompt = question.replaceFirst('generate image: ', '');
      final imageRequest = CreateImageRequest(prompt: prompt);
      ImageResponse? imageResponse = await _createImage(imageRequest);
      if (imageResponse != null && !imageResponse.isEmpty()) {
        questionAnswers.last.imgUrls = [];
        setState(() {
          for (int i = 0; i < imageResponse.data!.length; i++) {
            String? url = imageResponse.data![i].url;
            if (url != null) {
              questionAnswers.last.imgUrls!.add(url);
            }
          }
        });
      }
      setState(() => loading = false);
    } else {
      setState(() {
        textEditingController.clear();
        loading = true;
        questionAnswers.add(
          QuestionAnswer(
            question: question,
            answer: StringBuffer(),
          ),
        );
      });
      final testRequest = CompletionRequest(
        stream: true,
        maxTokens: 2000,
        messages: [Message(role: Role.user.name, content: question)],
      );
      await _streamResponse(testRequest);
      setState(() => loading = false);
    }
  }

  _streamResponse(CompletionRequest request) async {
    streamSubscription?.cancel();
    try {
      final stream = await chatGpt.createChatCompletionStream(request);
      streamSubscription = stream?.listen(
        (event) => setState(
          () {
            if (event.streamMessageEnd) {
              streamSubscription?.cancel();
            } else {
              return questionAnswers.last.answer.write(
                event.choices?.first.delta?.content,
              );
            }
          },
        ),
      );
    } catch (error) {
      setState(() {
        loading = false;
        questionAnswers.last.answer.write("Error");
      });
      log("Error occurred: $error");
    }
  }

  Future<ImageResponse?> _createImage(CreateImageRequest request) async {
    try {
      final ImageResponse? imageResponse = await chatGpt.createImage(request);
      return imageResponse;
    } catch (error) {
      setState(() {
        loading = false;
        questionAnswers.last.answer.write("Image generate Error");
      });
      log("Error occurred: $error");
      return null;
    }
  }

  Widget _buildShareIcons(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 8),
        InkWell(
            onTap: () {
              Share.share(message);
            },
            child: const Icon(
              Icons.share_rounded,
              size: 16,
              color: Colors.grey,
            )),
        const SizedBox(width: 8),
        InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
            },
            child:
                const Icon(Icons.copy_rounded, size: 16, color: Colors.grey)),
        const SizedBox(width: 8),
      ],
    );
  }
}
