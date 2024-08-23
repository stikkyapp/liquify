import 'package:liquify/src/tag.dart';

class CycleTag extends AbstractTag with CustomTagParser {
  late List<dynamic> items;
  String? groupName;

  CycleTag(super.content, super.filters);

  @override
  void preprocess(Evaluator evaluator) {
    if (content.isEmpty) {
      throw Exception('CycleTag requires at least one argument.');
    }

    final firstNamedArg = namedArgs.firstOrNull;

    if (firstNamedArg != null) {
      groupName = firstNamedArg.identifier.name;
      items = ((firstNamedArg.value as Literal).value as List)
          .where((e) => e is! NamedArgument)
          .map((e) => evaluator.evaluate(e))
          .toList();
    } else {
      items = content
          .where((e) => e is Identifier || e is Literal)
          .map((e) => evaluator.evaluate(e))
          .toList();
    }

    if (items.isEmpty) {
      throw Exception('CycleTag requires at least one item to cycle through.');
    }
  }

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final cycleState = _getCycleState(evaluator);
    final currentIndex = cycleState['index'] as int;
    final currentItem = items[currentIndex];

    buffer.write(currentItem);

    cycleState['index'] = (currentIndex + 1) % items.length;
    _setCycleState(evaluator, cycleState);
  }

  Map<String, dynamic> _getCycleState(Evaluator evaluator) {
    final key = _getStateKey();
    final existingState =
        evaluator.context.getVariable(key) as Map<String, dynamic>?;
    return existingState ?? {'index': 0};
  }

  void _setCycleState(Evaluator evaluator, Map<String, dynamic> state) {
    final key = _getStateKey();
    evaluator.context.setVariable(key, state);
  }

  String _getStateKey() {
    return groupName != null ? 'cycle:$groupName' : 'cycle:${items.join(",")}';
  }

  @override
  Parser parser() {
    return seq3(tagStart() & string('cycle').trim(),
            ref0(cycleArguments).trim(), tagEnd())
        .map((values) {
      return Tag(
          'cycle',
          values.$2 is List
              ? values.$2.cast<ASTNode>()
              : <ASTNode>[values.$2 as ASTNode]);
    });
  }

  Parser cycleArguments() {
    return ref0(cycleNamedArgument).or(ref0(cycleSimpleArguments));
  }

  Parser cycleNamedArgument() {
    return seq3(
            ref0(stringLiteral), char(':').trim(), ref0(cycleSimpleArguments))
        .map((values) {
      final name = values.$1 as Literal;
      final args = (values.$3 as List).cast<ASTNode>();
      return NamedArgument(
          Identifier(name.value), Literal(args, LiteralType.array));
    });
  }

  Parser cycleSimpleArguments() {
    return ref0(expression)
        .plusSeparated(char(',').trim())
        .map((result) => result.elements);
  }
}