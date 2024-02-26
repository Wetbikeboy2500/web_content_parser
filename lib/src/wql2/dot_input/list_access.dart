enum ListAccessType {
  first,
  last,
  even,
  odd,
  index1,
  indexRange,
  indexRangeSkip,
  all,
}

sealed class ListAccess {
  ListAccessType type;
  ListAccess(this.type);
  List process(List input);
}

class FirstAccess extends ListAccess {
  FirstAccess() : super(ListAccessType.first);
  @override
  List process(List input) => [input.first];
}

class LastAccess extends ListAccess {
  LastAccess() : super(ListAccessType.last);
  @override
  List process(List input) => [input.last];
}

class EvenAccess extends ListAccess {
  EvenAccess() : super(ListAccessType.even);
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
  OddAccess() : super(ListAccessType.odd);
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

  Index1Access(this.index) : super(ListAccessType.index1);

  @override
  List process(List input) {
    final trueIndex = index < 0 ? input.length + index : index;
    return [input[trueIndex]];
  }
}

class IndexRangeAccess extends ListAccess {
  final int start;
  final int end;
  IndexRangeAccess(this.start, this.end) : super(ListAccessType.indexRange);
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
  IndexRangeStepAccess(this.start, this.end, this.step) : super(ListAccessType.indexRangeSkip);
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
  AllAccess() : super(ListAccessType.all);
  @override
  List process(List input) => input;
}