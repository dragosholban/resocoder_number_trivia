import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:number_trivia/core/error/exceptions.dart';
import 'package:number_trivia/features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'package:number_trivia/features/number_trivia/data/models/number_trivia_model.dart';

import '../../../../fixtures/fixture_reader.dart';
import 'number_trivia_remote_data_source_test.mocks.dart';

@GenerateMocks([http.Client])
main() {
  late NumberTriviaRemoteDataSourceImpl datasource;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    datasource = NumberTriviaRemoteDataSourceImpl(client: mockHttpClient);
  });

  void setUpMockHttClientSuccess200() {
    when(mockHttpClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(fixture('trivia.json'), 200));
  }

  void setUpMockHttClientFailure404() {
    when(mockHttpClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('Something went wrong', 404));
  }

  group('getConcreteNumberTrivia', () {
    const tNumber = 1;
    final tNumberTriviaModel =
        NumberTriviaModel.fromJson(json.decode(fixture('trivia.json')));

    test('''should perform a get request on a URL with number
        being the endpoint and with application/json header''', () async {
      // arrange
      setUpMockHttClientSuccess200();
      // act
      datasource.getConcreteNumberTrivia(tNumber);
      // assert
      verify(mockHttpClient.get(
        Uri.parse('http://numbersapi.com/$tNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
    });

    test('should return NumberTrivia when the response is 200 (success)',
        () async {
      // arrange
      setUpMockHttClientSuccess200();
      // act
      final result = await datasource.getConcreteNumberTrivia(tNumber);
      // assert
      expect(result, equals(tNumberTriviaModel));
    });

    test(
        'should throw a ServerException when the response code is 4040 or other',
        () async {
      // arrange
      setUpMockHttClientFailure404();
      // act
      final call = datasource.getConcreteNumberTrivia;
      // assert
      expect(
          () => call(tNumber), throwsA(const TypeMatcher<ServerException>()));
    });
  });

  group('getRandomNumberTrivia', () {
    final tNumberTriviaModel =
        NumberTriviaModel.fromJson(json.decode(fixture('trivia.json')));

    test('''should perform a get request on a URL with number
        being the endpoint and with application/json header''', () async {
      // arrange
      setUpMockHttClientSuccess200();
      // act
      datasource.getRandomNumberTrivia();
      // assert
      verify(mockHttpClient.get(
        Uri.parse('http://numbersapi.com/random'),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
    });

    test('should return NumberTrivia when the response is 200 (success)',
        () async {
      // arrange
      setUpMockHttClientSuccess200();
      // act
      final result = await datasource.getRandomNumberTrivia();
      // assert
      expect(result, equals(tNumberTriviaModel));
    });

    test(
        'should throw a ServerException whne the response code is 4040 or other',
        () async {
      // arrange
      setUpMockHttClientFailure404();
      // act
      final call = datasource.getRandomNumberTrivia;
      // assert
      expect(() => call(), throwsA(const TypeMatcher<ServerException>()));
    });
  });
}
