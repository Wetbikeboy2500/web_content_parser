# WQL (Web Query Language) Documentation

## Variable Assignment

```wql
// Global variable assignment
variableName = value;
// Local variable assignment for a block scope
_variableName = value;
```

## Data Types

```wql
// String with single quotes
string = s'string';
// String with backticks
string = s`string`;
// Escaped characters: newline, carriage return, tab, backslash
escapedChars = s'\n\r\t\\';
// Number with single quotes
number = n'123';
// Number with backticks
number = n`123`;
// Boolean with single quotes
boolean = b'true';
// Boolean with backticks
boolean = b`false`;
// Empty list, no other input allowed in declaration
list = l'';
// Empty list, no other input allowed in declaration
list = l``;
```

## Array Operations

```wql
// All elements
array[];
// All elements (alternative)
array[all];
// First element by index
array[0];
// Last element using negative index
array[-1];
// First element
array[first];
// Last element
array[last];
// Range slice
array[1:3];
// Range slice with step
array[1:-1:2];
// Even-indexed elements
array[even];
// Odd-indexed elements
array[odd];

// Chain array operations. Get even-indexed elements, get 1st and 2nd elements, expand expanded elements for looping
array[even,1:3,all];
```

## File Operations

```wql
// Read file contents
readFile(s'path/to/file');
```

## String Operations

```wql
// Split string into array
string.split(s'\n');
// Remove whitespace
string.trim();
// Get all regex matches
string.allMatches(pattern);
// Check if regex pattern matches
string.hasMatch(pattern);
// Join array elements
string.join(separator);
// Reverse string
string.reverse();
```

## Number Operations

```wql
// Addition
number.add(n);
// Subtraction
number.subtract(n);
// Multiplication
number.multiply(n);
// Absolute value
number.abs();
// Less than comparison
number.lessThan(n);
// Greater than comparison
number.greaterThan(n);
```

## Array Methods

```wql
// Get array length
array.length();
// Get element at index
array.at(index);
// Flatten nested array
array.flatten();
// Check if all elements are true
array.every();
// Sort array
array.sort();
// Convert elements to numbers
array.toNumber();
```

## Control Flow

```wql
// If statement
if {condition}
// Else clause
.else {alternative}
// Evaluation block
.eval {block};

// Array iteration
array[].eval {
    // * refers to current context element
};
```

## Utility Functions

```wql
// Create number range
createRange(start, end);
// Minimum of two values
min(a, b);
// Merge arrays
merge(array1, array2);
// Concatenate values
concat(val1, val2, val3);
// Add numbers
add(a, b);
// Multiply numbers
multiply(a, b);
```

## Special Characters

```wql
eval {
    // Current value/context in block
    *;
    // Sets the return value of a block
    * = s`return value`;
};
// Sets return value of the script
* = s`return value`;
```
