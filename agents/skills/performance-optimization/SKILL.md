---
name: performance-optimization
description: This skill should be used when the user asks to "optimize performance", "make this faster", "profile this code", "fix slow code", "reduce memory usage", "improve efficiency", "find bottlenecks", or mentions performance issues, slow execution, or memory leaks.
version: 2.0.0
---

> **Note:** This skill should NOT be used proactively. Only use when the user explicitly requests performance optimization or reports a performance problem. Do not suggest optimizations unsolicited.

# Performance Optimization

Optimize code for speed, memory efficiency, and scalability across Python, TypeScript, and general algorithms.

**v2.0 Update**: Added ROI-first approach. Always calculate expected real-world impact before optimizing. A 100x speedup on a function taking 1% of total time = only 1% overall improvement. Focus on the critical path.

## Optimization Workflow

### Step 0: ROI Analysis (NEW - CRITICAL)

Before optimizing ANY code, calculate the expected Return on Investment.

**The Golden Rule**: Only optimize code that is on the **critical path** of user-facing operations.

**Real-World Case Study**:
```
Function isolated speedup: 64x faster 🚀
Real-world system speedup: 1% faster 😐

Why? The function took 1% of total time.
External dependency took 93% - that was the real bottleneck.
```

**ROI Calculation Framework**:

| Metric | Formula | Example |
|--------|---------|---------|
| Current % of total | `function_time / total_time` | 70ms / 7000ms = 1% |
| Max possible speedup | `1 / (1 - current_fraction)` | 1 / (1 - 0.01) = 1.01x |
| Real-world impact | `isolated_speedup × current_fraction` | 64 × 0.01 = 1% |
| Implementation cost | Hours to implement + test | 4 hours |
| Value delivered | Real-world impact / Cost | 1% / 4h = LOW |

**Decision Matrix**:

| Current % of Total | Isolated Speedup | Real-World Impact | Optimize? |
|-------------------|-----------------|-------------------|-----------|
| > 50% | 2x+ | > 25% | ✅ **YES** |
| > 50% | 1.5x | > 15% | ✅ **YES** |
| 20-50% | 5x+ | > 4% | ✅ **YES** |
| 20-50% | 2x | 1-4% | ⚠️ Maybe |
| < 10% | ANY | < 2% | ❌ **NO** |
| < 5% | ANY | < 1% | ❌ **NO** |

**When to skip optimization despite impressive isolated speedup**:
- Function is NOT on the user-facing critical path
- Dominated by I/O, network, or external dependency (database, API, third-party library)
- Code runs infrequently (startup, batch jobs)
- Readability/maintainability would significantly suffer

### Step 1: Measure First

Never optimize without profiling. Identify actual bottlenecks before making changes.

**For ROI Analysis: Get Percentage Breakdown**

```bash
# Python: Get cumulative time percentage (most useful for ROI)
python -m cProfile -s cumtime script.py | head -30

# Sort output shows:
# ncalls  tottime  percall  cumtime  percall filename:lineno(function)
# The cumtime column is critical - it shows % of total time including called functions
```

**Interpreting cProfile output for ROI**:
```
   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
     5000    0.003    0.000    0.050    0.001 file.py:42(process_data)
   100000    0.150    0.000    0.150    0.000 file.py:58(helper_func)
        1    6.500    6.500    7.000    7.000 external_lib.py:10(heavy_lifting)

# Analysis:
# - helper_func: 0.150s / 7.000s = 2% of total → NOT worth optimizing
# - heavy_lifting: 6.500s / 7.000s = 93% of total → THIS is the bottleneck
```

**Python Profiling:**

```bash
# CPU profiling (sorted by cumulative time)
python -m cProfile -s cumtime script.py > profile.txt
head -30 profile.txt

# Line-by-line profiling (install: pip install line_profiler)
kernprof -l -v script.py

# Memory profiling (install: pip install memory_profiler)
python -m memory_profiler script.py

# Visual profiling
python -m cProfile -o output.prof script.py
snakeviz output.prof  # Opens browser visualization
```

**TypeScript/Node.js Profiling:**
```bash
# CPU profiling
node --prof app.js
node --prof-process isolate-*.log > profile.txt

# Heap snapshots
node --inspect --expose-gc app.js
# Then use Chrome DevTools Memory tab

# Memory leak detection
node --expose-gc --max-old-space-size=256 app.js
```

### Step 2: Identify Bottleneck Category + ROI-Based Prioritization

**First: Calculate % of total time for each candidate**

| Symptom | Likely Cause | Solution Category | ROI Priority |
|---------|--------------|-------------------|--------------|
| High CPU time in one function (>20% of total) | Algorithm complexity | Algorithm optimization | ✅ **HIGH** |
| Many small function calls (>20% total) | Loop overhead | Vectorization/batching | ✅ **HIGH** |
| External lib dominates (>50% of total) | Can't optimize directly | Consider replacement/config | ⚠️ **MEDIUM** |
| Slow I/O operations (>10% of total) | Blocking calls | Async/parallel I/O | ✅ **HIGH** |
| Growing memory over time | Memory leak | Resource cleanup | ✅ **HIGH** |
| Cache misses (<5% of total) | Data locality | Data structure change | ❌ **LOW** |
| Function takes <5% of total | Not on critical path | Skip optimization | ❌ **SKIP** |

### Step 3: Apply Targeted Optimization

**Priority Order:**
1. **Algorithm complexity** - Biggest wins (O(n²) → O(n log n))
2. **I/O optimization** - Parallel/async operations
3. **Memory access patterns** - Cache-friendly data structures
4. **Micro-optimizations** - Only after profiling confirms need

## Quick Reference: Common Patterns

### Python Hot Paths

| Anti-Pattern | Optimized | Speedup |
|--------------|-----------|---------|
| `for` loop over array | NumPy vectorization | 10-100x |
| Repeated string concat | `''.join(list)` | 5-10x |
| `list.append` in loop | List comprehension | 2-3x |
| Global variable access | Local variable | 10-20% |
| `if x in list` | `if x in set` | O(n) → O(1) |

```python
# Before: O(n) loop
result = []
for x in data:
    result.append(x * 2)

# After: Vectorized O(1) operations
import numpy as np
result = np.array(data) * 2
```

### TypeScript Hot Paths

| Anti-Pattern | Optimized | Impact |
|--------------|-----------|--------|
| `await` in loop | `Promise.all()` | Parallel execution |
| Event listener leak | `removeEventListener` | Prevents memory leak |
| Large object copies | Immutable updates | Reduced GC pressure |
| Sync file I/O | Async streams | Non-blocking |
| `setInterval` leak | `clearInterval` | Prevents memory leak |

```typescript
// Before: Sequential (slow)
for (const item of items) {
    await fetch(item.url);
}

// After: Parallel (fast)
await Promise.all(items.map(item => fetch(item.url)));
```

### React Performance

| Anti-Pattern | Optimized | Impact |
|--------------|-----------|--------|
| Expensive calc on every render | `useMemo` | Cache until deps change |
| New function each render | `useCallback` | Stable ref for memo |
| Render 10,000 items | Virtualization | Only render visible |
| Import heavy component | `React.lazy()` | Code split on demand |

```typescript
// useMemo: Cache expensive computations
const processed = useMemo(() => expensiveCalc(data), [data]);

// useCallback: Stable function reference
const handleClick = useCallback(() => { /* ... */ }, [deps]);

// Virtualization for long lists (react-window or react-virtualized)
import { FixedSizeList } from 'react-window';

// Lazy loading heavy components
const HeavyChart = lazy(() => import('./HeavyChart'));
```

### Algorithm Complexity Improvements

| Problem | Naive | Optimized |
|---------|-------|-----------|
| Find duplicates | O(n²) nested loops | O(n) with Set |
| Sort + search | O(n²) + O(n) | O(n log n) + O(log n) |
| String matching | O(nm) brute force | O(n+m) KMP/Rabin-Karp |
| Graph traversal | O(V²) adjacency matrix | O(V+E) adjacency list |

**Complexity Quick Reference:**

| Complexity | Name | 1K items | 1M items | Example |
|------------|------|----------|----------|---------|
| O(1) | Constant | 1 op | 1 op | Hash lookup |
| O(log n) | Logarithmic | 10 ops | 20 ops | Binary search |
| O(n) | Linear | 1K ops | 1M ops | Single pass |
| O(n log n) | Linearithmic | 10K ops | 20M ops | Merge sort |
| O(n²) | Quadratic | 1M ops | 1T ops | Nested loops |

## Memory Optimization

### Python Memory Patterns

```python
# Use generators for large datasets
def process_large_file(path):
    with open(path) as f:
        for line in f:  # Streams, doesn't load all
            yield process(line)

# Use __slots__ for memory-constrained classes
class Point:
    __slots__ = ['x', 'y']
    def __init__(self, x, y):
        self.x, self.y = x, y
```

### TypeScript Memory Patterns

```typescript
// Use WeakMap for object metadata (auto-cleanup)
const metadata = new WeakMap<object, Data>();

// Clean up event listeners
const handler = () => { /* ... */ };
element.addEventListener('click', handler);
// Later:
element.removeEventListener('click', handler);

// Clear intervals
const id = setInterval(callback, 1000);
// Later:
clearInterval(id);
```

## Validation Checklist

**Before starting optimization:**
- [ ] Profiled to identify actual bottleneck (not assumed)
- [ ] Calculated ROI: function % of total time × expected speedup
- [ ] Confirmed function is on critical path of user-facing operation
- [ ] Expected real-world improvement ≥ 5-10%

**After implementing optimization:**
- [ ] Profiled before AND after changes
- [ ] Measured actual speedup in isolation (benchmarks)
- [ ] Measured actual speedup in real-world usage (end-to-end)
- [ ] Verified correctness (tests still pass)
- [ ] Checked memory usage didn't increase
- [ ] Documented complexity change (if applicable)

**Red flag**: If isolated speedup is 10x+ but real-world speedup is <5%, you optimized the wrong thing.

## When NOT to Optimize

**ROI Rule**: If optimization won't deliver at least 5-10% real-world improvement, don't do it.

**Specific reasons to skip**:
- Code runs infrequently (startup, config loading, one-time setup)
- Profiling shows <10% of total time in user-facing operation
- Dominated by external dependency you can't control (database, API, third-party service)
- Optimization sacrifices readability significantly
- No measurable user-facing impact
- Implementation time > user time saved over 1 year

**Remember**: A 100x speedup on a function taking 1% of total time = 1% overall improvement. A 2x speedup on a function taking 50% of total time = 25% overall improvement. **Focus on the latter.**

## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:
- **`references/python-patterns.md`** - NumPy vectorization, memory profiling, caching
- **`references/typescript-patterns.md`** - Async patterns, memory leaks, Web Workers
- **`references/algorithm-patterns.md`** - Complexity analysis, data structures, memoization

### Scripts

- **`scripts/profile-python.sh`** - All-in-one Python profiling (CPU, memory, line-by-line)

```bash
# CPU profiling (default)
./profile-python.sh script.py

# Memory profiling
PROFILE_TYPE=memory ./profile-python.sh script.py

# Line-by-line profiling (requires @profile decorator)
PROFILE_TYPE=line ./profile-python.sh script.py
```
