# Algorithm Optimization Patterns

Language-agnostic patterns for improving algorithmic complexity.

## Complexity Analysis Quick Reference

| Complexity | Name | Example | 1000 items | 1M items |
|------------|------|---------|------------|----------|
| O(1) | Constant | Hash lookup | 1 | 1 |
| O(log n) | Logarithmic | Binary search | 10 | 20 |
| O(n) | Linear | Single pass | 1000 | 1M |
| O(n log n) | Linearithmic | Merge sort | 10K | 20M |
| O(n²) | Quadratic | Nested loops | 1M | 1T |
| O(2^n) | Exponential | Subset enumeration | 10^301 | ∞ |

## Common Complexity Improvements

### Nested Loops → Hash Table

```
Problem: Find if two arrays share any element

SLOW O(n²):
for each item in array1:
    for each item in array2:
        if item1 == item2: return true

FAST O(n):
set1 = Set(array1)
for each item in array2:
    if item in set1: return true
```

### Linear Search → Binary Search

```
Prerequisite: Sorted data

SLOW O(n):
for each item in array:
    if item == target: return index

FAST O(log n):
low, high = 0, len(array) - 1
while low <= high:
    mid = (low + high) // 2
    if array[mid] == target: return mid
    elif array[mid] < target: low = mid + 1
    else: high = mid - 1
```

### Repeated Computation → Memoization

```
Problem: Fibonacci numbers

SLOW O(2^n) - Exponential:
fib(n) = fib(n-1) + fib(n-2)
# Recomputes same values repeatedly

FAST O(n) - Linear with memoization:
cache = {}
fib(n):
    if n in cache: return cache[n]
    result = fib(n-1) + fib(n-2)
    cache[n] = result
    return result
```

### Multiple Passes → Single Pass

```
Problem: Find min, max, and sum

SLOW O(3n):
min_val = min(array)
max_val = max(array)
sum_val = sum(array)

FAST O(n):
min_val, max_val, sum_val = array[0], array[0], 0
for item in array:
    min_val = min(min_val, item)
    max_val = max(max_val, item)
    sum_val += item
```

## Data Structure Selection Guide

| Use Case | Best Structure | Complexity |
|----------|---------------|------------|
| Frequent lookups by key | Hash Map/Dict | O(1) |
| Ordered data + range queries | Balanced BST / Sorted Array | O(log n) |
| Queue operations | Deque | O(1) both ends |
| Priority ordering | Heap / Priority Queue | O(log n) insert/extract |
| Membership testing | Set | O(1) |
| Graph with dense edges | Adjacency Matrix | O(1) edge lookup |
| Graph with sparse edges | Adjacency List | O(E/V) avg edge lookup |

## Caching Strategies

### LRU Cache (Least Recently Used)

```
Use when: Recent items more likely to be accessed again

Structure: Hash map + Doubly linked list
- O(1) get and put
- Automatic eviction of oldest items

Implementation:
- Hash map: key → node pointer
- Linked list: maintains access order
- On access: move node to front
- On full: remove from back
```

### Memoization Patterns

```
Use when: Function called repeatedly with same arguments

Function requirements:
- Pure (no side effects)
- Deterministic (same input → same output)

Trade-off: Memory for speed
- Good: Fibonacci, path finding, string parsing
- Bad: Functions with changing external state
```

### Precomputation

```
Use when: Same derived values needed multiple times

Examples:
- Prefix sums for range queries
- Lookup tables for math functions
- Index structures for search

Trade-off: Startup time for query time
```

## Space-Time Trade-offs

### Example: Two Sum Problem

```
Find two numbers in array that sum to target

Space O(1), Time O(n²): Nested loops
Space O(n), Time O(n): Hash set complement lookup
Space O(1), Time O(n log n): Sort + two pointers
```

### Example: String Anagram Check

```
Check if two strings are anagrams

Space O(n log n), Time O(n log n): Sort both, compare
Space O(k), Time O(n): Character frequency count (k = alphabet size)
```

## Algorithmic Techniques

### Sliding Window

```
Use when: Contiguous subarray/substring problems

Pattern:
- Maintain window [left, right]
- Expand right to include elements
- Shrink left when constraint violated
- Track best result

Complexity: O(n) - each element visited at most twice
```

### Two Pointers

```
Use when: Sorted array, find pairs, partition

Pattern:
- Left pointer at start, right at end
- Move pointers based on comparison
- Meet in middle

Complexity: O(n) single pass
```

### Divide and Conquer

```
Use when: Problem can be split into independent subproblems

Pattern:
- Divide: Split problem in half
- Conquer: Solve subproblems recursively
- Combine: Merge results

Examples: Merge sort, Quick sort, Binary search
Complexity: Usually O(n log n)
```

### Dynamic Programming

```
Use when: Overlapping subproblems, optimal substructure

Pattern:
- Define state: dp[i] = optimal solution for subproblem i
- Find recurrence: dp[i] = f(dp[j]) for some j < i
- Base case: dp[0] = initial value
- Build bottom-up or top-down with memoization

Complexity: O(states × transition cost)
```

## Early Termination Patterns

### Short-Circuit Evaluation

```
SLOW: Always computes everything
result = expensive_check_1() and expensive_check_2()

FAST: Stops at first failure
if not cheap_check():
    return False
if not expensive_check_1():
    return False
return expensive_check_2()
```

### Bounds Checking

```
Use when: Can prove optimum exists in subrange

Pattern:
- Track current best
- Skip branches that can't improve
- Prune search space

Examples: Branch and bound, Alpha-beta pruning
```

## Common Pitfalls

### Premature Optimization

```
DON'T: Optimize without measuring
- Guess where bottlenecks are
- Complicate code for theoretical gains
- Micro-optimize cold paths

DO: Profile first
- Identify actual bottlenecks
- Focus on hot paths
- Measure before and after
```

### Hidden Complexity

```
Watch for:
- String concatenation in loops: O(n²) hidden
- List/array insert at front: O(n) per operation
- Repeated list membership checks: O(n) each
- Sorting in inner loop: O(n² log n)
```

### Worst-Case vs Average-Case

```
Hash table: O(1) average, O(n) worst
Quick sort: O(n log n) average, O(n²) worst
Binary search tree: O(log n) average, O(n) worst (unbalanced)

Consider:
- Is worst case acceptable?
- Can adversarial input trigger worst case?
- Use randomization to prevent worst case?
```
