class ApiResponse<T> {
  const ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? data)? dataParser,
  }) {
    final rawData = json['data'];
    final rawMessage = json['message'];

    return ApiResponse<T>(
      success: json['success'] == true,
      message: rawMessage is String ? rawMessage : '',
      data: dataParser != null ? dataParser(rawData) : rawData as T?,
    );
  }

  final bool success;
  final String message;
  final T? data;
}
