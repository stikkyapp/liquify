import 'package:intl/intl.dart';
import 'package:liquify/src/filters/array.dart';
import 'package:liquify/src/filters/date.dart';
import 'package:liquify/src/filters/html.dart' as html;
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUp(() {
    ensureTimezonesInitialized();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('Array Filters', () {
    test('join', () {
      expect(join([1, 2, 3], [', '], {}), equals('1, 2, 3'));
      expect(
          join(['a', 'b', 'c'], [], {}), equals('a b c')); // default separator
      expect(join('not a list', [', '], {}), equals('not a list'));
    });

    test('first', () {
      expect(first([1, 2, 3], [], {}), equals(1));
      expect(first([], [], {}), equals(''));
      expect(first('not a list', [], {}), equals(''));
    });

    test('last', () {
      expect(last([1, 2, 3], [], {}), equals(3));
      expect(last([], [], {}), equals(''));
      expect(last('not a list', [], {}), equals(''));
    });

    test('reverse', () {
      expect(reverse([1, 2, 3], [], {}), equals([3, 2, 1]));
      expect(reverse([], [], {}), equals([]));
      expect(reverse('not a list', [], {}), equals('not a list'));
    });

    test('size', () {
      expect(size([1, 2, 3], [], {}), equals(3));
      expect(size([], [], {}), equals(0));
      expect(size('string', [], {}), equals(6));
      expect(size(123, [], {}), equals(0)); // non-string, non-list
    });

    test('sort', () {
      expect(sort([3, 1, 2], [], {}), equals([1, 2, 3]));
      expect(sort(['c', 'a', 'b'], [], {}), equals(['a', 'b', 'c']));
      expect(sort([], [], {}), equals([]));
      expect(sort('not a list', [], {}), equals('not a list'));
    });

    test('map', () {
      var input = [
        {'name': 'Alice'},
        {'name': 'Bob'}
      ];
      expect(map(input, ['name'], {}), equals(['Alice', 'Bob']));
      expect(map([], ['name'], {}), equals([]));
      expect(map('not a list', ['name'], {}), equals('not a list'));
      expect(map([1, 2, 3], ['nonexistent'], {}), equals([null, null, null]));
    });

    test('where', () {
      var input = [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 30}
      ];
      expect(
          where(input, ['age', 30], {}),
          equals([
            {'name': 'Alice', 'age': 30},
            {'name': 'Charlie', 'age': 30}
          ]));
      expect(where(input, ['age'], {}), equals(input)); // all have 'age'
      expect(where([], ['age', 30], {}), equals([]));
      expect(where('not a list', ['age', 30], {}), equals('not a list'));
    });

    test('uniq', () {
      expect(uniq([1, 2, 2, 3, 3, 3], [], {}), equals([1, 2, 3]));
      expect(uniq(['a', 'b', 'b', 'c'], [], {}), equals(['a', 'b', 'c']));
      expect(uniq([], [], {}), equals([]));
      expect(uniq('not a list', [], {}), equals('not a list'));
    });

    test('slice', () {
      expect(slice([1, 2, 3, 4, 5], [1, 2], {}), equals([2, 3]));
      expect(slice([1, 2, 3], [1], {}), equals([2])); // default length 1
      expect(slice('abcde', [1, 2], {}), equals('bc'));
      expect(slice([], [1, 2], {}), equals([]));
      expect(slice('', [1, 2], {}), equals(''));
      expect(slice(123, [1, 2], {}), equals(123)); // non-string, non-list
      expect(slice([1, 2, 3], [10, 2], {}), equals([])); // start beyond end
      expect(slice([1, 2, 3], [-1, 2], {}),
          equals([3])); // negative index from end
      expect(slice([1, 2, 3], [-2, 2], {}),
          equals([2, 3])); // negative index from end
      expect(slice([1, 2, 3], [0, 10], {}),
          equals([1, 2, 3])); // length beyond end
      expect(slice('abcde', [3, 5], {}), equals('de')); // string slice
      expect(slice([1], [0, 0], {}), equals([])); // zero length
      expect(slice([1, 2, 3], [1, -1], {}), equals([])); // negative length
      expect(slice([1, 2, 3], [-5, 2], {}),
          equals([1, 2])); // negative index beyond start
    });
  });
  group('URL Filters', () {
    test('urlDecode', () {
      expect(urlDecode('hello+world', [], {}), equals('hello world'));
      expect(urlDecode('hello%20world', [], {}), equals('hello world'));
    });

    test('urlEncode', () {
      expect(urlEncode('hello world', [], {}), equals('hello+world'));
    });

    test('cgiEscape', () {
      expect(cgiEscape("It's a test!", [], {}), equals('It%27s+a+test%21'));
    });

    test('uriEscape', () {
      expect(uriEscape('http://example.com/path[1]/test', [], {}),
          equals('http://example.com/path[1]/test'));
    });

    test('slugify', () {
      expect(slugify('Hello World!', [], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['default'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['ascii'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['pretty'], {}), equals('hello-world!'));
      expect(slugify('Hello  World!', ['raw'], {}), equals('hello-world!'));
      expect(slugify('Hello World!', ['none'], {}), equals('Hello World!'));
      expect(slugify('Héllö Wörld!', ['latin'], {}), equals('hello-world'));
      expect(slugify('Hello World!', ['default', true], {}),
          equals('Hello-World'));
      expect(slugify('Hello, World!', [], {}), equals('hello-world'));
      expect(slugify('   Hello,    World!   ', [], {}), equals('hello-world'));
      expect(slugify('Hello_World', ['pretty'], {}), equals('hello_world'));
      expect(slugify('Hello.World', ['pretty'], {}), equals('hello.world'));
      expect(slugify('Hello World!', ['invalid'], {}),
          equals('hello-world')); // default behavior
      expect(slugify('Hello, World!', ['raw'], {}),
          equals('hello,-world!')); // raw mode preserves punctuation
    });
  });

  group('HTML Filters', () {
    test('escape should escape \' and &', () {
      expect(
        html.escape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('escape should escape normal string', () {
      expect(
        html.escape("Tetsuro Takara", [], {}),
        equals("Tetsuro Takara"),
      );
    });

    test('escape should escape undefined', () {
      expect(
        html.escape(null, [], {}),
        equals(""),
      );
    });

    test('escape_once should do escape', () {
      expect(
        html.escapeOnce("1 < 2 & 3", [], {}),
        equals("1 &lt; 2 &amp; 3"),
      );
    });

    test('escape_once should not escape twice', () {
      expect(
        html.escapeOnce("1 &lt; 2 &amp; 3", [], {}),
        equals("1 &lt; 2 &amp; 3"),
      );
    });

    test('escape_once should escape nil value to empty string', () {
      expect(
        html.escapeOnce(null, [], {}),
        equals(""),
      );
    });

    test('xml_escape should escape \' and &', () {
      expect(
        html.xmlEscape("Have you read 'James & the Giant Peach'?", [], {}),
        equals("Have you read &#39;James &amp; the Giant Peach&#39;?"),
      );
    });

    test('newline_to_br should support string_with_newlines', () {
      final src = "\nHello\nthere\r\n";
      final dst = "<br />\nHello<br />\nthere<br />\n";
      expect(
        html.newlineToBr(src, [], {}),
        equals(dst),
      );
    });

    test('strip_html should strip all tags', () {
      final input =
          'Have <em>you</em> read <cite><a href="https://en.wikipedia.org/wiki/Ulysses_(novel)">Ulysses</a></cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Have you read Ulysses?"),
      );
    });

    test('strip_html should strip all comment tags', () {
      expect(
        html.stripHtml("<!--Have you read-->Ulysses?", [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline comments', () {
      final input = '<!--foo\r\nbar \ncoo\t  \r\n  -->';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should strip all style tags and their contents', () {
      final input =
          '<style>cite { font-style: italic; }</style><cite>Ulysses<cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline styles', () {
      final input = '<style> \n.header {\r\n  color: black;\r\n}\n</style>';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should strip all scripts tags and their contents', () {
      final input =
          '<script async>console.log(\'hello world\')</script><cite>Ulysses<cite>?';
      expect(
        html.stripHtml(input, [], {}),
        equals("Ulysses?"),
      );
    });

    test('strip_html should strip multiline scripts', () {
      final input = '<script> \nfoo\r\nbar\n</script>';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });

    test('strip_html should not strip non-matched <script>', () {
      final input = '<script></script>text<script></script>';
      expect(
        html.stripHtml(input, [], {}),
        equals("text"),
      );
    });

    test('strip_html should strip until empty', () {
      final input = '<br/><br />< p ></p></ p >';
      expect(
        html.stripHtml(input, [], {}),
        equals(""),
      );
    });
  });

  group('Date Filters', () {
    test('date filter', () {
      expect(date('2023-05-15', ['yyyy-MM-dd'], {}), equals('2023-05-15'));
      expect(date('2023-05-15', ['MMMM d, yyyy'], {}), equals('May 15, 2023'));
      expect(date('now', ['yyyy-MM-dd'], {}),
          equals(DateFormat('yyyy-MM-dd').format(tz.TZDateTime.now(tz.local))));
    });

    test('date_to_xmlschema filter', () {
      expect(dateToXmlschema('2023-05-15', [], {}),
          equals('2023-05-15T00:00:00.000-04:00'));
    });

    test('date_to_rfc822 filter', () {
      expect(dateToRfc822('2023-05-15', [], {}),
          equals('Mon, 15 May 2023 00:00:00 -0400'));
    });

    test('date_to_string filter', () {
      expect(dateToString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(
          dateToString('2023-05-15', ['ordinal'], {}), equals('15th May 2023'));
      expect(dateToString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });

    test('date_to_long_string filter', () {
      expect(dateToLongString('2023-05-15', [], {}), equals('15 May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal'], {}),
          equals('15th May 2023'));
      expect(dateToLongString('2023-05-15', ['ordinal', 'US'], {}),
          equals('May 15th, 2023'));
    });
  });
}