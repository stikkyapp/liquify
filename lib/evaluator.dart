import 'package:liquid_grammar/context.dart';
import 'package:liquid_grammar/registry.dart';

import 'ast.dart';
import 'visitor.dart';

class Evaluator implements ASTVisitor<dynamic> {
  final Environment context;
  StringBuffer buffer = StringBuffer();
  final Map<String, ASTNode> nodeMap = {};

  Evaluator(this.context);

  Evaluator.withBuffer(this.context, this.buffer);

  Evaluator createInnerEvaluator() {
    final innerContext = context.clone();
    return Evaluator.withBuffer(innerContext, buffer);
  }

  void buildNodeMap(List<ASTNode> nodes) {
    for (final node in nodes) {
      nodeMap[node.id] = node;
      if (node is Document) {
        buildNodeMap(node.children);
      } else if (node is Tag) {
        buildNodeMap(node.content);
      }
    }
  }

  dynamic evaluate(ASTNode node) {
    return node.accept(this);
  }

  dynamic evaluateNodes(List<ASTNode> nodes) {
    buildNodeMap(nodes);
    for (final node in nodes) {
      if (node is Tag && TagRegistry.hasEndTag(node.name)) {
        evaluateTagWithEndTag(nodes, node);
      } else {
        node.accept(this);
      }
    }
    return buffer.toString();
  }

  dynamic evaluateTagWithEndTag(List<ASTNode> nodes, Tag startTag) {
    final endTagName = 'end${startTag.name}';
    var foundEndTag = false;
    final startIndex = nodes.indexOf(startTag);
    int nestedCount = 0;

    for (int i = startIndex + 1; i < nodes.length; i++) {
      final child = nodes[i];
      if (child is Tag) {
        if (child.name == startTag.name) {
          nestedCount++;
        } else if (child.name == endTagName) {
          if (nestedCount == 0) {
            foundEndTag = true;
            final tag = TagRegistry.createTag(
                startTag.name, startTag.content, startTag.filters);
            tag?.body = nodes.sublist(startIndex + 1, i);
            tag?.preprocess(this);
            tag?.evaluate(this, buffer);
            break;
          } else {
            nestedCount--;
          }
        }
      }
    }

    if (!foundEndTag) {
      throw Exception('Missing end tag: $endTagName');
    }
  }

  @override
  dynamic visitLiteral(Literal node) {
    return node.value;
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    final value = context.getVariable(node.name);
    return value;
  }

  @override
  dynamic visitBinaryOperation(BinaryOperation node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);
    dynamic result;
    switch (node.operator) {
      case '+':
        result = left + right;
        break;
      case '-':
        result = left - right;
        break;
      case '*':
        result = left * right;
        break;
      case '/':
        result = left / right;
        break;
      case '==':
        result = left == right;
        break;
      case '!=':
        result = left != right;
        break;
      case '<':
        result = left < right;
        break;
      case '>':
        result = left > right;
        break;
      case '<=':
        result = left <= right;
        break;
      case '>=':
        result = left >= right;
        break;
      case 'and':
        result = left && right;
        break;
      case 'or':
        result = left || right;
        break;
      case '..':
        result = List.generate(right - left + 1, (index) => left + index);
        break;
      case 'in':
        if (right is! Iterable) {
          throw Exception('Right side of "in" operator must be iterable.');
        }
        result = right.contains(left);
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
  }

  @override
  dynamic visitUnaryOperation(UnaryOperation node) {
    final expr = node.expression.accept(this);
    dynamic result;
    switch (node.operator) {
      case 'not':
      case '!':
        result = !expr;
        break;
      default:
        throw UnsupportedError('Unsupported operator: ${node.operator}');
    }
    return result;
  }

  @override
  dynamic visitGroupedExpression(GroupedExpression node) {
    return node.expression.accept(this);
  }

  @override
  dynamic visitAssignment(Assignment node) {
    final value = node.value.accept(this);
    if (node.variable is Identifier) {
      context.setVariable((node.variable as Identifier).name, value);
    } else if (node.variable is MemberAccess) {
      final memberAccess = node.variable as MemberAccess;

      final objName = (memberAccess.object as Identifier).name;

      if (!context.variables.containsKey(objName)) {
        context.variables[objName] = {};
      }

      var objectVal = context.variables[objName];

      for (var i = 0; i < memberAccess.members.length; i++) {
        if (i == memberAccess.members.length - 1) {
          objectVal[memberAccess.members[i]] = value;
        } else {
          if (!(objectVal as Map).containsKey(memberAccess.members[i])) {
            objectVal[memberAccess.members[i]] = {};
          }
          objectVal = objectVal[memberAccess.members[i]];
        }
      }
    }
  }

  @override
  dynamic visitDocument(Document node) {
    return evaluateNodes(node.children);
  }

  @override
  dynamic visitFilter(Filter node) {
    final filterFunction = context.getFilter(node.name.name);
    if (filterFunction == null) {
      throw Exception('Undefined filter: ${node.name.name}');
    }
    final args = <dynamic>[];
    final namedArgs = <String, dynamic>{};

    for (final arg in node.arguments) {
      if (arg is NamedArgument) {
        namedArgs[arg.name.name] = arg.value.accept(this);
      } else {
        args.add(arg.accept(this));
      }
    }

    return (value) => filterFunction(value, args, namedArgs);
  }

  @override
  dynamic visitFilterExpression(FilteredExpression node) {
    var value = node.expression.accept(this);
    for (final filter in node.filters) {
      final filterFunction = filter.accept(this);
      value = filterFunction(value);
    }
    return value;
  }

  @override
  dynamic visitMemberAccess(MemberAccess node) {
    var object = node.object;
    final objName = (object as Identifier).name;

    if (!context.variables.containsKey(objName)) return null;

    var objectVal = context.variables[objName];

    if (objectVal is Map) {
      for (final member in node.members) {
        if (objectVal is Map && objectVal.containsKey(member)) {
          objectVal = objectVal[member];
        } else {
          return null;
        }
      }
    }
    return objectVal;
  }

  @override
  dynamic visitNamedArgument(NamedArgument node) {
    return MapEntry(node.name.name, node.value.accept(this));
  }

  @override
  dynamic visitTag(Tag node) {
    if (TagRegistry.hasEndTag(node.name)) {
      return evaluateTagWithEndTag(node.content, node);
    } else {
      final tag = TagRegistry.createTag(node.name, node.content, node.filters);
      tag?.preprocess(this);
      return tag?.evaluate(this, buffer);
    }
  }

  @override
  dynamic visitTextNode(TextNode node) {
    return node.text;
  }

  @override
  dynamic visitVariable(Variable node) {
    final value = node.expression.accept(this);
    return value;
  }
}