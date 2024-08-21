import 'package:liquid_grammar/ast.dart';
import 'package:liquid_grammar/context.dart';
import 'package:liquid_grammar/evaluator.dart';
import 'package:liquid_grammar/filter_registry.dart';
import 'package:liquid_grammar/registry.dart';
import 'package:test/test.dart';

void main() {
  Environment context = Environment();

  group('Evaluator', () {
    final evaluator = Evaluator(context);

    setUp(() {
      // Register custom tags
      registerBuiltIns();
    });

    test('evaluates literals', () {
      expect(evaluator.evaluate(Literal(5, LiteralType.number)), 5);
      expect(evaluator.evaluate(Literal(true, LiteralType.boolean)), true);
      expect(evaluator.evaluate(Literal('hello', LiteralType.string)), 'hello');
    });

    test('evaluates binary operations', () {
      final addition = BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number));
      expect(evaluator.evaluate(addition), 5);

      final multiplication = BinaryOperation(
          Literal(4, LiteralType.number), '*', Literal(2, LiteralType.number));
      expect(evaluator.evaluate(multiplication), 8);
    });

    test('evaluates unary operations', () {
      final notOperation =
          UnaryOperation('not', Literal(false, LiteralType.boolean));
      expect(evaluator.evaluate(notOperation), true);
    });

    test('evaluates grouped expressions', () {
      final grouped = GroupedExpression(BinaryOperation(
          Literal(2, LiteralType.number), '+', Literal(3, LiteralType.number)));
      expect(evaluator.evaluate(grouped), 5);
    });

    test('evaluates assignments', () {
      final assignment =
          Assignment(Identifier('x'), Literal(10, LiteralType.number));
      evaluator.evaluate(assignment);
      expect(evaluator.evaluate(Identifier('x')), 10);
    });

    test('evaluates member access', () {
      evaluator.evaluate(Assignment(
          MemberAccess(
            Identifier('user'),
            ['name'],
          ),
          Literal('John', LiteralType.string)));

      final memberAccess = MemberAccess(Identifier('user'), ['name']);
      expect(evaluator.evaluate(memberAccess), 'John');
    });

    test('evaluates text nodes', () {
      final textNode = TextNode('Hello, World!');
      expect(evaluator.evaluate(textNode), 'Hello, World!');
    });

    test('evaluates variables', () {
      final variable = Variable('x', Literal(42, LiteralType.number));
      expect(evaluator.evaluate(variable), 42);
    });

    test('evaluates complex expressions', () {
      final complexExpression = BinaryOperation(
          GroupedExpression(BinaryOperation(Literal(2, LiteralType.number), '*',
              Literal(3, LiteralType.number))),
          '+',
          Literal(4, LiteralType.number));
      expect(evaluator.evaluate(complexExpression), 10);
    });

    test('applies filters', () {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), [])]);
      expect(evaluator.evaluate(filteredExpression), 'HELLO');
    });

    test('applies multiple filters', () {
      final filteredExpression = FilteredExpression(
          Literal('hello', LiteralType.string),
          [Filter(Identifier('upper'), []), Filter(Identifier('length'), [])]);
      expect(evaluator.evaluate(filteredExpression), 5);
    });

    test('applies filters with named arguments', () {
      FilterRegistry.register('truncate', (value, args, namedArgs) {
        final length = namedArgs['length'] ?? 5;
        return value.toString().substring(0, length);
      });

      final filteredExpression =
          FilteredExpression(Literal('hello world', LiteralType.string), [
        Filter(Identifier('truncate'), [
          NamedArgument(Identifier('length'), Literal(5, LiteralType.number))
        ])
      ]);
      expect(evaluator.evaluate(filteredExpression), 'hello');
    });
  });
}