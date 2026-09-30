# Python Performance Patterns

Detailed optimization patterns for Python code.

## Profiling Deep Dive

### cProfile Analysis

```bash
# Generate profile
python -m cProfile -o output.prof script.py

# Sort by different metrics
python -m cProfile -s cumtime script.py  # Cumulative time
python -m cProfile -s tottime script.py  # Total time in function
python -m cProfile -s calls script.py    # Number of calls

# Visualize with snakeviz
pip install snakeviz
snakeviz output.prof
```

### Line Profiler

```python
# Install: pip install line_profiler

# Add @profile decorator to functions of interest
@profile
def slow_function(data):
    result = []
    for item in data:
        result.append(process(item))
    return result

# Run with kernprof
# kernprof -l -v script.py
```

Output interpretation:
```
Line #  Hits    Time  Per Hit  % Time  Line Contents
     5   1000   50000    50.0    80.0  result.append(process(item))
```
- **Hits**: Number of times line executed
- **Time**: Total time in microseconds
- **% Time**: Percentage of function time

### Memory Profiler

```python
# Install: pip install memory_profiler

from memory_profiler import profile

@profile
def memory_intensive():
    large_list = [i ** 2 for i in range(1000000)]
    return sum(large_list)

# Run: python -m memory_profiler script.py
```

## NumPy Vectorization

### Replace Loops with Broadcasting

```python
# SLOW: Python loop O(n) with Python overhead
def normalize_slow(data):
    result = []
    for x in data:
        result.append((x - min(data)) / (max(data) - min(data)))
    return result

# FAST: Vectorized O(n) with C-level operations
import numpy as np
def normalize_fast(data):
    arr = np.array(data)
    return (arr - arr.min()) / (arr.max() - arr.min())

# Speedup: 50-100x for large arrays
```

### Avoid Repeated Array Operations

```python
# SLOW: Creates intermediate arrays
result = np.sqrt(np.sum(np.square(arr), axis=1))

# FAST: Use in-place operations where possible
np.linalg.norm(arr, axis=1)  # Optimized implementation
```

### Use NumPy Universal Functions (ufuncs)

```python
# SLOW: Python loop
def clip_values(arr, low, high):
    return [max(low, min(x, high)) for x in arr]

# FAST: NumPy ufunc
np.clip(arr, low, high)
```

### Distance Calculation Example

```python
# SLOW: Double loop O(n²)
def distances_slow(X, Y):
    n, m = len(X), len(Y)
    dists = np.zeros((n, m))
    for i in range(n):
        for j in range(m):
            dists[i, j] = np.sqrt(np.sum((X[i] - Y[j]) ** 2))
    return dists

# FAST: Vectorized with broadcasting O(n*m) but C-level
def distances_fast(X, Y):
    # Using (a-b)² = a² + b² - 2ab
    X_sq = np.sum(X ** 2, axis=1).reshape(-1, 1)
    Y_sq = np.sum(Y ** 2, axis=1).reshape(1, -1)
    return np.sqrt(X_sq + Y_sq - 2 * X @ Y.T)

# Speedup: 100x+ for large matrices
```

## String Operations

### Avoid String Concatenation in Loops

```python
# SLOW: Creates new string each iteration O(n²)
result = ""
for s in strings:
    result += s

# FAST: Join at the end O(n)
result = "".join(strings)

# For formatted strings
# SLOW
result = ""
for item in items:
    result += f"{item.name}: {item.value}\n"

# FAST
result = "\n".join(f"{item.name}: {item.value}" for item in items)
```

## Data Structure Selection

### List vs Set vs Dict Lookup

```python
# O(n) - Linear search
if item in large_list:
    pass

# O(1) - Hash lookup
if item in large_set:
    pass

# O(1) - Hash lookup with value access
if key in large_dict:
    value = large_dict[key]
```

### Use collections.deque for Queue Operations

```python
from collections import deque

# SLOW: list.pop(0) is O(n)
queue = []
queue.append(item)
item = queue.pop(0)  # Shifts all elements

# FAST: deque.popleft() is O(1)
queue = deque()
queue.append(item)
item = queue.popleft()
```

### Use collections.Counter for Frequency

```python
from collections import Counter

# SLOW: Manual counting
freq = {}
for item in items:
    freq[item] = freq.get(item, 0) + 1

# FAST: Counter (optimized C implementation)
freq = Counter(items)
```

## Memory Optimization

### Generators for Large Data

```python
# MEMORY HOG: Loads all into memory
def read_all(path):
    with open(path) as f:
        return f.readlines()  # All lines in memory

# MEMORY EFFICIENT: Streams line by line
def read_stream(path):
    with open(path) as f:
        for line in f:
            yield line.strip()
```

### __slots__ for Memory-Constrained Classes

```python
# STANDARD: Each instance has __dict__ (~300 bytes overhead)
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

# OPTIMIZED: Fixed attributes (~64 bytes per instance)
class PointSlots:
    __slots__ = ['x', 'y']
    def __init__(self, x, y):
        self.x = x
        self.y = y

# For millions of instances: 80% memory reduction
```

### Use array.array for Homogeneous Data

```python
import array

# List of integers: ~28 bytes per int (object overhead)
numbers_list = [1, 2, 3, 4, 5]

# Array of integers: 8 bytes per int (raw storage)
numbers_array = array.array('q', [1, 2, 3, 4, 5])
```

## Caching and Memoization

### functools.lru_cache

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_computation(n):
    # Only computed once per unique n
    return sum(i ** 2 for i in range(n))

# Clear cache if needed
expensive_computation.cache_clear()
```

### functools.cache (Python 3.9+)

```python
from functools import cache

@cache  # Unbounded cache
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

## Parallel Processing

### multiprocessing for CPU-bound

```python
from multiprocessing import Pool

def process_item(item):
    return expensive_computation(item)

# Sequential: slow
results = [process_item(item) for item in items]

# Parallel: uses all CPU cores
with Pool() as pool:
    results = pool.map(process_item, items)
```

### concurrent.futures for Mixed Workloads

```python
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor

# I/O-bound: use threads
with ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(fetch_url, urls))

# CPU-bound: use processes
with ProcessPoolExecutor() as executor:
    results = list(executor.map(compute, data))
```

## Common Anti-Patterns

### Avoid Global Variable Access in Tight Loops

```python
# SLOW: Global lookup each iteration
MULTIPLIER = 2
def process(data):
    return [x * MULTIPLIER for x in data]

# FAST: Local variable
def process(data, multiplier=2):
    return [x * multiplier for x in data]
```

### Avoid Repeated Attribute Access

```python
# SLOW: Repeated method lookup
for item in items:
    result.append(item)

# FAST: Cache the method
append = result.append
for item in items:
    append(item)
```

### Use Built-in Functions

```python
# SLOW: Manual sum
total = 0
for x in numbers:
    total += x

# FAST: Built-in (C implementation)
total = sum(numbers)

# Similarly: min(), max(), any(), all(), sorted()
```
