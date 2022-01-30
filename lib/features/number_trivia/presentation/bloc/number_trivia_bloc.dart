import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:number_trivia/core/error/failure.dart';
import 'package:number_trivia/core/usecases/usecase.dart';
import 'package:number_trivia/core/util/input_converter.dart';
import 'package:number_trivia/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:number_trivia/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:number_trivia/features/number_trivia/domain/usecases/get_random_number_trivia.dart';

part 'number_trivia_event.dart';
part 'number_trivia_state.dart';

const String kServerFailureMessage = 'Server Failure';
const String kCacheFailureMessage = 'Cache Failure';
const String kInvalidInputFailureMessage =
    'Invalid Input - The number must be a positive integer or zero.';

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc({
    required GetConcreteNumberTrivia concrete,
    required GetRandomNumberTrivia random,
    required this.inputConverter,
  })  : getConcreteNumberTrivia = concrete,
        getRandomNumberTrivia = random,
        super(Empty()) {
    on<NumberTriviaEvent>((event, emit) async {
      if (event is GetTriviaForConcreteNumber) {
        final inputEither =
            inputConverter.stringToUnsignedInteger(event.numberString);

        await inputEither.fold(
          (failure) {
            emit(const Error(message: kInvalidInputFailureMessage));
          },
          (integer) async {
            emit(Loading());
            final failureOrTrivia =
                await getConcreteNumberTrivia(Params(number: integer));
            emit(_eitherLoadedOrErrorState(failureOrTrivia));
          },
        );
      } else if (event is GetTriviaForRandomNumber) {
        emit(Loading());
        final failureOrTrivia = await getRandomNumberTrivia(NoParams());
        emit(_eitherLoadedOrErrorState(failureOrTrivia));
      }
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return kServerFailureMessage;
      case CacheFailure:
        return kCacheFailureMessage;
      default:
        return 'Unexpected error';
    }
  }

  NumberTriviaState _eitherLoadedOrErrorState(
          Either<Failure, NumberTrivia> failureOrTrivia) =>
      failureOrTrivia.fold(
        (failure) => Error(
          message: _mapFailureToMessage(failure),
        ),
        (trivia) => Loaded(trivia: trivia),
      );
}
