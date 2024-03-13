sealed class ListAccess {
  const ListAccess();
  List process(List input);
}

class FirstAccess extends ListAccess {
  const FirstAccess();
  @override
  List process(List input) => [input.first];
}

class LastAccess extends ListAccess {
  const LastAccess();
  @override
  List process(List input) => [input.last];
}

class EvenAccess extends ListAccess {
  const EvenAccess();
  @override
  List process(List input) {
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
  List process(List input) {
    final List<dynamic> result = [];
    for (var i = 1; i < input.length; i += 2) {
      result.add(input[i]);
    }
    return result;
  }
}

class Index1Access extends ListAccess {
  final int index;

  const Index1Access(this.index);

  @override
  List process(List input) {
    final trueIndex = index < 0 ? input.length + index : index;
    return [input[trueIndex]];
  }
}

class IndexRangeAccess extends ListAccess {
  final int start;
  final int end;
  const IndexRangeAccess(this.start, this.end);
  @override
  List process(List input) {
    final int trueStart = start < 0 ? input.length + start : start;
    final int trueEnd = end < 0 ? input.length + end : end;

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
  List process(List input) {
    final int trueStart = start < 0 ? input.length + start : start;
    final int trueEnd = end < 0 ? input.length + end : end;

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
  AllAccess();
  @override
  List process(List input) => input;
}