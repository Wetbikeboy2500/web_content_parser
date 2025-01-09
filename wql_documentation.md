# WQL (Web Query Language) Documentation

## Overview
WQL is a specialized query language designed for data transformation and analysis. It follows a unique syntax with specific limitations and patterns to ensure consistent data processing.

## Core Concepts

### Variables and Assignment
```wql
// Global scope
globalVar = value;
// Block-local scope
_localVar = value;
```

### Data Types and Declaration
```wql
// Strings (use single quotes or backticks)
str1 = s'hello';
str2 = s`world`;

// Numbers
num1 = n'123';
num2 = n`456`;

// Booleans
bool1 = b'true';
bool2 = b`false';

// Lists (must be declared empty)
list1 = l'';
list2 = l``;
```

### Context Management
The context system is fundamental to WQL operations:

- `*` - References current context/value
- `^` - References global context

```wql
// Example of context usage
value = s'test';
result = value.eval {
    // * refers to 'test'
    * = *.trim();  // Must use * = for return values
};

// Context switching example
data1 = s'hello';
data2 = s'world';
data1.print().^.data2.print();  // Prints "hello world"
```

Important: Context operators cannot be used inside array selection brackets.

## Block Structure and Return Values

### eval Blocks
Return values in eval blocks are optional. If no return value is set using `* =`, the block returns its input context:

```wql
numbers = createRange(n'1', n'5');

// Single execution - returns transformed array
result1 = numbers.eval {
    * = *.sort();  // Explicitly return sorted array
};

// Returns original array since no return set
result2 = numbers.eval {
    print(*);  // Just prints, returns input
};

// Iteration with explicit returns
result3 = numbers[].eval {
    * = *.multiply(n'2');  // Transform each element
};

// Iteration without returns - returns original elements
result4 = numbers[].eval {
    print(*);  // Just prints each element
};
```

### Conditional Blocks
```wql
// Returns result if set, otherwise returns input
if {condition}
.else {alternative}
.eval {
    if (needsTransform) {
        * = transform(*);  // Explicit return
    }
    // Otherwise returns input
};
```

## Best Practices

### Return Values
Only set returns when transformation is needed:
```wql
// Good - explicit return for transformation
data.eval {
    processed = *.transform();
    * = processed;  // New value needed
};

// Good - implicit return when just performing actions
data.eval {
    print(*);  // Original data returned
};

// Unnecessary - returns same as input
data.eval {
    * = *;  // Redundant return
};
```

## Array Operations

### Valid Array Selectors
Only these selectors are allowed in array brackets:
- Numbers: `array[0]`, `array[-1]`
- Keywords: `[first]`, `[last]`, `[all]`, `[even]`, `[odd]`
- Ranges: `[1:3]`, `[1:-1:2]`
- Multiple selectors: `[even,1:3,all]`

```wql
array = createRange(n'1', n'5');

first = array[0];       // First element
last = array[last];     // Last element
evens = array[even];    // Even-indexed elements
slice = array[1:3];     // Range slice
```

Invalid: `array[variable]`, `array[^]`, `array[*]`

## Common Operations

### String Operations
```wql
text = s'  hello world  ';
split = text.split(s' ');
trimmed = text.trim();
matches = text.allMatches(pattern);
joined = split.join(s',');
reversed = text.reverse();
```

### Number Operations
```wql
num = n'10';
sum = num.add(n'5');
diff = num.subtract(n'3');
product = num.multiply(n'2');
absValue = num.abs();
isLess = num.lessThan(n'20');
isMore = num.greaterThan(n'5');
```

### Array Methods
```wql
array = createRange(n'1', n'5');
len = array.length();
element = array.at(n'2');
flat = array.flatten();
allTrue = array.every();
sorted = array.sort();
nums = array.toNumber();
```

## Best Practices

### Declarative Pattern
Prefer transforming data through chains:
```wql
// Good
result = input
    .split(s'\n')
    .eval {
        * = *.trim();
    }
    .toNumber()
    .sort();

// Avoid
result = l'';
input.split(s'\n')[].eval {
    temp = *.trim();
    result = merge(result, temp);
};
result = result.toNumber().sort();
```

### Context Management
Always be explicit about context changes:
```wql
// Good
data.eval {
    current = *;
    * = current.transform();
};

// Avoid
data.eval {
    transform();  // Unclear context
};
```

## Common Pitfalls

### Return Values
```wql
// Both valid depending on needs
data.eval {
    processed = *.transform();
    * = processed;  // Explicit return of new value
};

data.eval {
    print(*);  // Implicit return of input
};
```

### Array Selection
```wql
index = n'0';
// Wrong
array[index];
array[^];

// Correct
array.at(index);
```

## Utility Functions
- `createRange(start, end)` - Create number sequence
- `min(a, b)` - Find minimum value
- `merge(array1, array2)` - Combine arrays
- `concat(val1, val2, ...)` - Join values
- `add(a, b)` - Add numbers
- `multiply(a, b)` - Multiply numbers

## Limitations
- No direct mathematical operators (`+`, `-`, `*`, `/`)
- No variable references in array selection
- No implicit type conversion
- No direct object/map support
- eval blocks, else blocks, and the top level script do not have implicit returns
- No explicit async operator for flow control. Will await everything that returns a Future from Dart.
