import 'package:chat_gpt_flutter/src/models/chat_gpt_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'completion_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CompletionRequest {
  final ChatGptModel model;
  final List<String>? prompt;
  final int? maxTokens;
  final double? temperature;
  final double? topP;
  final int? n;
  final bool? stream;

  CompletionRequest({
    this.model = ChatGptModel.textDavinci003,
    required this.prompt,
    this.temperature = 0,
    this.maxTokens = 16,
    this.topP,
    this.n = 1,
    this.stream,
  }) : assert(!(temperature != null && topP != null));

  factory CompletionRequest.fromJson(Map<String, dynamic> data) =>
      _$CompletionRequestFromJson(data);

  Map<String, dynamic> toJson() => _$CompletionRequestToJson(this);
}
