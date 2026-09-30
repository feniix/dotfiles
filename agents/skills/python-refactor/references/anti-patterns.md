# Python Anti-Patterns

Common Python mistakes and their correct alternatives.

## Table of Contents

1. [Mutable Default Arguments](#mutable-default-arguments)
2. [Using `is` for Value Comparison](#using-is-for-value-comparison)
3. [Not Using Context Managers](#not-using-context-managers)
4. [Ignoring Type Hints](#ignoring-type-hints)
5. [Bare Except Clauses](#bare-except-clauses)
6. [String Concatenation in Loops](#string-concatenation-in-loops)
7. [Not Using `enumerate()`](#not-using-enumerate)
8. [Reinventing the Wheel](#reinventing-the-wheel)
9. [Over-Using Single Letter Variables](#over-using-single-letter-variables)
10. [Premature Optimization](#premature-optimization)
11. [God Objects](#god-objects)
12. [Shotgun Surgery](#shotgun-surgery)

---

## Mutable Default Arguments

**Problem:** Mutable defaults are shared across calls.

```python
# WRONG - dangerous!
def process_data(data: list, cache: dict = {}) -> dict:
    if data not in cache:
        cache[data] = expensive_computation(data)
    return cache[data]

# First call
result1 = process_data([1, 2, 3])  # cache = {}

# Second call - cache still has previous data!
result2 = process_data([4, 5, 6])  # cache = {[1,2,3]: result}
```

**Solution:** Use `None` as default and create new object.

```python
# CORRECT
def process_data(data: list, cache: Optional[dict] = None) -> dict:
    cache = cache if cache is not None else {}
    if data not in cache:
        cache[data] = expensive_computation(data)
    return cache[data]
```

---

## Using `is` for Value Comparison

**Problem:** `is` checks identity, not equality.

```python
# WRONG - can fail unexpectedly
if x == 1:
    pass

if x is 1:  # May fail due to interning
    pass

# DANGER: This is always False!
if 500 is 500:  # CPython doesn't intern large integers
    pass

# WRONG
if result is True:
    pass
```

**Solution:** Use `==` for value comparison, `is` for None/True/False/Singletons.

```python
# CORRECT
if x == 1:
    pass

# CORRECT - None is a singleton
if cache is None:
    cache = {}

# CORRECT - for bool checks, just use the value
if result:
    pass

# Only use 'is True' if you specifically need to distinguish True from truthy values
def is_specifically_true(value: bool) -> bool:
    return value is True
```

---

## Not Using Context Managers

**Problem:** Resources not properly cleaned up.

```python
# WRONG - file not closed if exception occurs
def read_file(path: str) -> str:
    f = open(path)
    data = f.read()
    f.close()
    return data

# WRONG - video capture not released on error
def process_video(path: str):
    cap = cv2.VideoCapture(path)
    frames = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(process(frame))  # If this raises, cap not released
    cap.release()
    return frames
```

**Solution:** Use context managers.

```python
# CORRECT
def read_file(path: str) -> str:
    with open(path) as f:
        return f.read()

# CORRECT - even if process() raises, cap is released
def process_video(path: str):
    with contextlib.closing(cv2.VideoCapture(path)) as cap:
        frames = []
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            frames.append(process(frame))
        return frames
```

---

## Ignoring Type Hints

**Problem:** Code is hard to understand and prone to errors.

```python
# WRONG - no type information
def process(data, config, options=None):
    result = []
    for item in data:
        if options:
            result.append(transform(item, config))
        else:
            result.append(item)
    return result
```

**Solution:** Add proper type hints.

```python
# CORRECT
from typing import Optional, Sequence, List
from numpy.typing import NDArray

def process(
    data: NDArray[np.float64],
    config: AnalysisConfig,
    options: Optional[ProcessOptions] = None
) -> NDArray[np.float64]:
    if options is None:
        return data
    return transform(data, config)
```

---

## Bare Except Clauses

**Problem:** Catches system-exiting exceptions and hides bugs.

```python
# WRONG - catches KeyboardInterrupt, SystemExit too!
try:
    process_video(path)
except:
    pass  # Silent failure - bad!

# WRONG - hides bugs
try:
    result = calculate_metrics(data)
except Exception:
    return None  # Was it KeyError? ValueError? We'll never know!
```

**Solution:** Catch specific exceptions.

```python
# CORRECT
try:
    process_video(path)
except (OSError, cv2.error) as e:
    logger.error(f"Video processing failed: {e}")
    raise

# CORRECT - specific for expected errors
try:
    result = calculate_metrics(data)
except (ValueError, KeyError) as e:
    logger.warning(f"Metrics calculation failed: {e}")
    return None
```

---

## String Concatenation in Loops

**Problem:** O(n²) performance for large strings.

```python
# WRONG - creates new string each iteration
def build_html(items: list[str]) -> str:
    html = ""
    for item in items:
        html += f"<li>{item}</li>"
    return html

# WRONG - same issue
lines = []
for i in range(10000):
    lines.append(f"Line {i}\n")
result = "".join(lines)  # This join is fine, but...
```

**Solution:** Use list comprehension or generators.

```python
# CORRECT
def build_html(items: list[str]) -> str:
    return "\n".join(f"<li>{item}</li>" for item in items)

# CORRECT for building from generator
def get_log_lines(count: int) -> str:
    return "".join(f"Line {i}\n" for i in range(count))
```

---

## Not Using `enumerate()`

**Problem:** Manual index tracking is error-prone.

```python
# WRONG
for i in range(len(items)):
    item = items[i]
    do_something(i, item)

# WRONG
index = 0
for item in items:
    do_something(index, item)
    index += 1
```

**Solution:** Use `enumerate()`.

```python
# CORRECT
for index, item in enumerate(items):
    do_something(index, item)

# With start index
for i, item in enumerate(items, start=1):
    print(f"Item {i}: {item}")
```

---

## Reinventing the Wheel

**Problem:** Writing code that exists in stdlib.

```python
# WRONG - manual implementation
def flatten(nested):
    result = []
    for sublist in nested:
        for item in sublist:
            result.append(item)
    return result

# WRONG - manual groupby
def group_by_key(items, key_func):
    groups = {}
    for item in items:
        key = key_func(item)
        if key not in groups:
            groups[key] = []
        groups[key].append(item)
    return groups
```

**Solution:** Use standard library.

```python
# CORRECT - use itertools
from itertools import chain

def flatten(nested: list[list[T]]) -> list[T]:
    return list(chain.from_iterable(nested))

# CORRECT - use itertools
from itertools import groupby
from operator import attrgetter

def group_by_key(items: list[T], key: Callable[[T], Any]) -> dict:
    sorted_items = sorted(items, key=key)
    return {
        k: list(g)
        for k, g in groupby(sorted_items, key=key)
    }
```

---

## Over-Using Single Letter Variables

**Problem:** Code is hard to understand.

```python
# WRONG - what do these mean?
def calc(a, b, c):
    d = a * b
    e = d / c
    return e

# WRONG - slightly better but still unclear
def calc(x, y, z):
    result = x * y
    output = result / z
    return output
```

**Solution:** Use meaningful names.

```python
# CORRECT
def calculate_total_price(quantity: int, unit_price: float, discount_rate: float) -> float:
    subtotal = quantity * unit_price
    total = subtotal / (1 + discount_rate)
    return total

# Exception: loop index, coordinate math are fine with short names
for i, item in enumerate(items):
    x, y = point  # coordinates - short is fine
```

---

## Premature Optimization

**Problem:** Optimizing before measuring.

```python
# WRONG - micro-optimization without profiling
# "Cache this because it might be slow"
_CACHE = {}

def get_landmarks(video_path: str):
    if video_path not in _CACHE:
        _CACHE[video_path] = expensive_operation(video_path)
    return _CACHE[video_path]

# But: 1) Memory leak  2) No profiling showed this was slow
#     3) The video_path is unique each time anyway!
```

**Solution:** Profile first, optimize hot paths only.

```python
# CORRECT approach
import cProfile
import pstats

def main():
    # First, make it work
    result = process_videos(video_paths)

    # If slow, profile to find bottleneck
    # cProfile.run('process_videos(video_paths)', 'output.stats')
    # pstats.Stats('output.stats').sort_stats('cumtime').print_stats(10)

    # Only optimize the actual bottleneck
```

---

## God Objects

**Problem:** One class does everything.

```python
# WRONG - knows and does too much
class VideoProcessor:
    def __init__(self):
        self.video_loader = VideoLoader()
        self.pose_detector = PoseDetector()
        self.filter = ButterworthFilter()
        self.metrics_calculator = MetricsCalculator()
        self.visualizer = Visualizer()
        self.exporter = Exporter()
        self.config = Config()
        self.logger = Logger()

    def process(self, path):
        # 200 lines of coordination logic
        pass

    def detect_pose(self):
        pass

    def filter_signal(self):
        pass

    def calculate_metrics(self):
        pass

    def visualize(self):
        pass

    def export(self):
        pass

    # ... 20 more methods
```

**Solution:** Single Responsibility Principle.

```python
# CORRECT - each class has one job
class VideoProcessor:
    def __init__(self, pipeline: ProcessingPipeline):
        self.pipeline = pipeline

    def process(self, path: str) -> ProcessResult:
        video = self.pipeline.load(path)
        return self.pipeline.execute(video)

class ProcessingPipeline:
    def __init__(
        self,
        detector: PoseDetector,
        filter: SignalFilter,
        calculator: MetricsCalculator
    ):
        self.detector = detector
        self.filter = filter
        self.calculator = calculator

    def execute(self, video: Video) -> ProcessResult:
        landmarks = self.detector.detect(video)
        filtered = self.filter.apply(landmarks)
        return self.calculator.calculate(filtered)
```

---

## Shotgun Surgery

**Problem:** Adding one feature requires changes in many places.

```python
# WRONG - scattered logic
class CMJAnalyzer:
    def analyze(self, data):
        # Phase detection
        phases = self._detect_phases(data)

        # Metrics calculation
        height = self._calculate_height(phases)
        depth = self._calculate_depth(phases)

        # Validation
        if height > 100:
            logger.warning("Suspicious height")
        if depth < 10:
            logger.warning("Suspicious depth")

        return {"height": height, "depth": depth}

class DropJumpAnalyzer:
    def analyze(self, data):
        # Same validation logic repeated
        if rsi > 3:
            logger.warning("Suspicious RSI")
        # ...
```

**Solution:** Centralize related logic.

```python
# CORRECT - validation in one place
class MetricsValidator:
    def validate(self, metrics: dict, jump_type: str) -> ValidationResult:
        bounds = self._get_bounds(jump_type)
        return self._check_bounds(metrics, bounds)

# CORRECT - analyzer focuses on analysis
class CMJAnalyzer:
    def __init__(self, validator: MetricsValidator):
        self.validator = validator

    def analyze(self, data: np.ndarray) -> dict:
        metrics = self._calculate_metrics(data)
        return self.validator.validate(metrics, "cmj")
```

---

## Summary: Refactoring Principles

**DO:**
- Write tests before refactoring
- Make small, incremental changes
- Run tests after each change
- Use descriptive names
- Follow Python idioms
- Profile before optimizing

**DON'T:**
- Change functionality while refactoring
- Skip tests to "save time"
- Create single-use abstractions
- Over-engineer simple problems
- Optimize without measuring
- Refactor code you don't understand
