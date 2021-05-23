// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

class _$NewsApiService extends NewsApiService {
  _$NewsApiService([ChopperClient client]) {
    if (client == null) return;
    this.client = client;
  }

  final definitionType = NewsApiService;

  Future<Response> getNews(
      {String q = "tesla",
      String from = "2021-05-21",
      String sort = "publishedAt",
      // ignore: invalid_override_different_default_values_named
      String apiKey = "76602acb8dd54507881b7ba66b93db76",}) {
    final $url = '/';
    final Map<String, dynamic> $params = {
      'q': q,
      'from': from,
      'sortBy': sort,
      'apiKey': apiKey
    };
    final $request = Request('GET', $url, client.baseUrl, parameters: $params);
    return client.send<dynamic, dynamic>($request);
  }
}
