import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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
      appBar: (Platform.isAndroid || Platform.isIOS)
          ? AppBar(title: const Text("ChatGPT 3.5"))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                controller: scrollController,
                itemCount: questionAnswers.length,
                itemBuilder: (context, index) {
                  return _buildChatLine(questionAnswers[index]);
                },
                separatorBuilder: (context, index) =>
                    const Divider(height: 16.0, thickness: 1.0),
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 1.0, thickness: 1.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniStartDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 84.0),
        child: FloatingActionButton.small(
          onPressed: _scrollDown,
          backgroundColor: Colors.blue,
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
      mainAxisSize: MainAxisSize.min,
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
                margin: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                        questionAnswer.imgUrls!.first,
                        maxWidth: 200,
                        maxHeight: 200),
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
                          .replaceFirst('generate image: ', '')
                          .replaceFirst("draw: ", ''));
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMyMessage(String message) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              child: Text("You"),
            ),
            const SizedBox(width: 16.0, height: 16.0),
            _buildShareIcons(message),
          ],
        ),
        const SizedBox(width: 16.0, height: 16.0),
        Container(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.of(context).size.width - avatarSize * 2),
          ),
          decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius:
                  BorderRadius.all(Radius.circular(chatMessageRadius))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              softWrap: true,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGptMessage(String message) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        if (message.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width - avatarSize * 2),
            ),
            decoration: const BoxDecoration(
                color: Color(0xFF74AA9C),
                borderRadius:
                    BorderRadius.all(Radius.circular(chatMessageRadius))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                softWrap: true,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        if (message.isNotEmpty) const SizedBox(width: 16.0, height: 16.0),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/chat_gpt_logo.svg',
              semanticsLabel: 'GPT Logo',
              height: avatarSize,
              width: avatarSize,
            ),
            if (message.isNotEmpty) const SizedBox(width: 16.0, height: 16.0),
            if (message.isNotEmpty) _buildShareIcons(message),
          ],
        ),
      ],
    );
  }

  _sendMessage() async {
    final question = textEditingController.text;
    if (question.isEmpty) {
      return;
    }
    if (question.toLowerCase().startsWith('generate image: ') ||
        question.toLowerCase().startsWith('draw: ')) {
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
      String prompt = question
          .replaceFirst('generate image: ', '')
          .replaceFirst('draw: ', '');
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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
      ],
    );
  }
}
