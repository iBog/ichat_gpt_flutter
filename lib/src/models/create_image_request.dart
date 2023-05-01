import 'package:json_annotation/json_annotation.dart';

part 'create_image_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateImageRequest {
  final String prompt;
  final int n;
  final String size;
  final String? responseFormat;

  CreateImageRequest({
    required this.prompt,
    this.n = 1,
    this.size = '512x512',//Must be one of 256x256, 512x512, or 1024x1024
    this.responseFormat = 'url',
  });

  factory CreateImageRequest.fromJson(Map<String, dynamic> data) =>
      _$CreateImageRequestFromJson(data);

  Map<String, dynamic> toJson() => _$CreateImageRequestToJson(this);
}
