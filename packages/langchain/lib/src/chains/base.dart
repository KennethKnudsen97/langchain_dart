import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../memory/base.dart';
import 'models/models.dart';

/// {@template base_chain}
/// Base class that defines a chain.
/// {@endtemplate}
abstract class BaseChain {
  /// {@macro base_chain}
  const BaseChain({
    this.memory,
  });

  /// Memory to use for this chain.
  final BaseMemory? memory;

  /// Return the string type key uniquely identifying this class of chain.
  String get chainType;

  /// Input keys for this chain.
  List<String> get inputKeys;

  /// Output keys for this chain.
  List<String> get outputKeys;

  /// Runs the core logic of this chain with the given values.
  /// If [memory] is not null, it will be used to load and save values.
  Future<ChainValues> call(final ChainValues values) async {
    final fullValues = {...values};

    final memory = this.memory;
    if (memory != null) {
      final newValues = await memory.loadMemoryVariables(values);
      fullValues.addAll(newValues);
    }

    final outputValues = await callInternal(fullValues);

    if (memory != null) {
      await memory.saveContext(values, outputValues);
    }

    return outputValues;
  }

  /// Call method to be implemented by subclasses.
  /// This is where the core logic of the chain should be implemented.
  @protected
  Future<ChainValues> callInternal(final ChainValues values);

  /// Call the chain on all inputs in the list.
  Future<List<ChainValues>> apply(final List<ChainValues> inputs) async {
    return Future.wait(inputs.map(call));
  }

  /// Runs the chain as input in, String out.
  ///
  /// The input can be:
  /// - A single value, if the chain has a single input key.
  ///   Eg: `chain.run('Hello world!')`
  /// - A map of key->values, if the chain has multiple input keys.
  ///   Eg: `chain.run({'foo': 'Hello', 'bar': 'world!'})`
  Future<String> run(final dynamic input) async {
    const SetEquality<String> setEq = SetEquality<String>();
    Map<String, dynamic> chainValues;

    if (inputKeys.isEmpty) {
      chainValues = const {};
    } else if (input is Map &&
        setEq.equals(
            inputKeys.toSet(), (input.keys as Iterable<String>).toSet())) {
      chainValues = input as Map<String, dynamic>;
    } else if (inputKeys.length == 1) {
      chainValues = {inputKeys[0]: input};
    } else {
      throw ArgumentError(
        'This chain ($chainType) requires ${inputKeys.length} input values.',
      );
    }

    final returnValues = await call(chainValues);

    if (returnValues.length == 1) {
      return returnValues.values.first.toString();
    }

    throw Exception(
      'The chain returned multiple keys, '
      '`run` only supports one key. Use `call` instead.',
    );
  }
}