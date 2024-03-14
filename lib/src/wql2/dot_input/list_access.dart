sealed class ListAccess {
  const ListAccess();
  dynamic process(dynamic input);
}

class FirstAccess extends ListAccess {
  const FirstAccess();
  @override
  dynamic process(dynamic input) => input.first;
}

class LastAccess extends ListAccess {
  const LastAccess();
  @override
  dynamic process(dynamic input) => input.last;
}

class EvenAccess extends ListAccess {
  const EvenAccess();
  @override
  List process(dynamic input) {
    final List<dynamic> result = [];
    for (var i = 0; i < input.length; i += 2) {
      result.add(input[i]);
    }
    return result;
  }
}

class OddAccess extends ListAccess {
  const OddAccess();
  @override
  List process(dynamic input) {
    final List<dynamic> result = [];
    for (var i = 1; i < input.length; i += 2) {
      result.add(input[i]);
    }
    return result;
  }
}

int indexAccess(int index, int length) => index < 0 ? length + index : index;

class Index1Access extends ListAccess {
  final int index;

  const Index1Access(this.index);

  @override
  dynamic process(dynamic input) {
    return input[indexAccess(index, input.length)];
  }
}

class IndexRangeAccess extends ListAccess {
  final int start;
  final int end;
  const IndexRangeAccess(this.start, this.end);
  @override
  List process(dynamic input) {
    final int trueStart = indexAccess(start, input.length);
    final int trueEnd = indexAccess(end, input.length);

    final int min = trueStart < trueEnd ? trueStart : trueEnd;
    final int max = trueStart < trueEnd ? trueEnd : trueStart;

    final List<dynamic> result = [];
    for (var i = min; i < max; i++) {
      result.add(input[i]);
    }
    return result;
  }
}

class IndexRangeStepAccess extends ListAccess {
  final int start;
  final int end;
  final int step;
  const IndexRangeStepAccess(this.start, this.end, this.step);
  @override
  List process(dynamic input) {
    final int trueStart = indexAccess(start, input.length);
    final int trueEnd = indexAccess(end, input.length);

    final int min = trueStart < trueEnd ? trueStart : trueEnd;
    final int max = trueStart < trueEnd ? trueEnd : trueStart;

    final List<dynamic> result = [];
    for (var i = min; i < max; i += step) {
      result.add(input[i]);
    }
    return result;
  }
}

class AllAccess extends ListAccess {
  const AllAccess();
  @override
  List process(dynamic input) => input is List ? input : [input];
}
