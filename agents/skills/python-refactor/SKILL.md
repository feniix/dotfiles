---
name: python-refactor
description: This skill should be used when the user asks to "refactor this", "simplify this code", "improve maintainability", "reduce complexity", "extract method", "reduce code duplication", "apply DRY principle", "clean up this function", or mentions Python code quality, maintainability, or simplification.
version: 1.0.0
---

# Python Refactoring

Simplify and maintain Python code through systematic refactoring. Focus on clarity, reduction of complexity, and elimination of duplication while preserving all functionality.

## Purpose

Refactoring improves code structure without changing behavior. The goal is code that is:
- **Easy to understand** - Clear intent, minimal cognitive load
- **Easy to modify** - Single Responsibility, low coupling
- **Easy to test** - Pure functions, clear dependencies
- **Maintainable** - Low duplication, clear patterns

## When to Use This Skill

Invoke this skill when:
- Functions exceed 15-20 lines or have nesting > 3 levels
- Similar code appears in multiple places (duplication)
- Parameter lists exceed 4-5 parameters
- Variable names are unclear or misleading
- Complex boolean logic or conditionals exist
- NumPy loops could be vectorized
- Type hints are missing or incorrect

## Refactoring Workflow

Follow this systematic process:

### 1. Understand the Code

Before changing anything, understand what the code does:

```python
# Use serena to get symbol overview
get_symbols_overview(relative_path="path/to/file.py")

# Read the specific symbol
find_symbol(name_path_pattern="ClassName/method_name", include_body=True)
```

**Ask:**
- What is the single responsibility of this code?
- What are the inputs and outputs?
- What edge cases are handled?

### 2. Identify Refactoring Opportunities

Look for:
- **Complexity**: Functions with cyclomatic complexity > 10
- **Duplication**: Similar patterns repeated
- **Side effects**: Functions that do multiple things
- **Magic numbers**: Unnamed constants
- **Deep nesting**: More than 3 levels of indentation

```python
# Use serena to search for duplication patterns
search_for_pattern(
    substring_pattern=r"def\s+\w+.*:",
    restrict_search_to_code_files=True
)
```

### 3. Plan the Changes

For complex refactoring, use sequential-thinking to plan:

```python
sequentialthinking(
    "I need to refactor [function_name]. It has [X] issues: "
    "1. [issue1] 2. [issue2] 3. [issue3]. "
    "Plan: Extract [part1] to helper, simplify [part2]..."
)
```

**Verify plan:**
- Each change is small and testable
- No functionality changes
- Tests will pass after each step

### 4. Execute Refactoring

Use serena for precise edits:

```python
# Replace symbol body for functions
replace_symbol_body(
    name_path="function_name",
    relative_path="module/file.py",
    body="# new implementation"
)

# Insert new helper after existing symbol
insert_after_symbol(
    name_path="existing_function",
    relative_path="module/file.py",
    body="# new helper function"
)
```

### 5. Validate

Always verify after refactoring:

```bash
# Run tests
pytest

# Type check
pyright

# Lint
ruff check --fix
```

## Key Refactoring Patterns

### Extract Method

Break large functions into smaller, named pieces:

```python
# Before - 40 lines, hard to understand
def process_video(video_path, quality, output):
    pose = detect_pose(video_path)
    smoothed = smooth_landmarks(pose, quality)
    filtered = filter_signal(smoothed)
    metrics = calculate_metrics(filtered)
    if output:
        save_debug_video(filtered, output)
    return metrics

# After - each piece is clear and testable
def process_video(video_path, quality, output=None):
    landmarks = detect_pose(video_path)
    processed = process_landmarks(landmarks, quality)
    metrics = calculate_metrics(processed.signal)

    if output:
        save_debug_video(processed, output)

    return metrics

def process_landmarks(landmarks, quality):
    smoothed = smooth_landmarks(landmarks, quality)
    return SignalData(smoothed, filter_signal(smoothed))
```

**When to extract:**
- Function exceeds 15-20 lines
- Logic has a clear name/purpose
- Code needs to be tested independently
- Same logic appears in multiple places

### Early Return

Reduce nesting by handling edge cases first:

```python
# Before - nested, hard to follow
def calculate_metrics(data):
    if data is not None:
        if len(data) > 0:
            if all(isinstance(x, (int, float)) for x in data):
                return sum(data) / len(data)
    return None

# After - flat, clear flow
def calculate_metrics(data):
    if data is None:
        return None
    if len(data) == 0:
        return None
    if not all(isinstance(x, (int, float)) for x in data):
        raise TypeError("All values must be numeric")

    return sum(data) / len(data)
```

### Parameter Object

Replace long parameter lists with data structures:

```python
# Before - too many parameters
def analyze_video(
    path,
    quality,
    smoothing_window,
    filter_cutoff,
    min_confidence,
    debug_mode,
    output_path
):
    ...

# After - grouped, extensible
@dataclass
class AnalysisConfig:
    quality: str = "balanced"
    smoothing_window: int = 5
    filter_cutoff: float = 6.0
    min_confidence: float = 0.5

@dataclass
class DebugConfig:
    enabled: bool = False
    output_path: Optional[str] = None

def analyze_video(
    path: str,
    config: AnalysisConfig,
    debug: DebugConfig = DebugConfig()
):
    ...
```

### Extract Function (DRY)

When logic repeats, extract to a shared function:

```python
# Before - duplicated validation
def process_cmj(data):
    if data is None or len(data) == 0:
        raise ValueError("Invalid data")
    # ... CMJ logic

def process_drop_jump(data):
    if data is None or len(data) == 0:
        raise ValueError("Invalid data")
    # ... DJ logic

# After - shared validation
def validate_input(data, name="data"):
    if data is None:
        raise ValueError(f"{name} cannot be None")
    if len(data) == 0:
        raise ValueError(f"{name} cannot be empty")

def process_cmj(data):
    validate_input(data, "CMJ data")
    # ... CMJ logic
```

## NumPy Optimization

### Vectorize Operations

Replace Python loops with NumPy operations:

```python
# Before - slow Python loop
def calculate_velocity(positions, dt):
    velocities = []
    for i in range(len(positions) - 1):
        v = (positions[i+1] - positions[i]) / dt
        velocities.append(v)
    return np.array(velocities)

# After - fast vectorized
def calculate_velocity(positions: NDArray[np.float64], dt: float) -> NDArray[np.float64]:
    return np.diff(positions) / dt
```

### Use Boolean Indexing

Avoid conditional loops:

```python
# Before
filtered = []
for val in data:
    if val > threshold and not np.isnan(val):
        filtered.append(val)

# After
mask = (data > threshold) & ~np.isnan(data)
filtered = data[mask]
```

### Avoid Unnecessary Copies

Use views when possible:

```python
# Before - creates copy
result = array.copy()
result = result * 2 + 1

# After - in-place
result = array * 2 + 1  # Single allocation
```

## Code Quality Checklist

### Complexity
- [ ] Functions under 20 lines (most cases)
- [ ] Nesting ≤ 3 levels
- [ ] Cyclomatic complexity < 10

### Duplication
- [ ] No repeated logic patterns
- [ ] Shared utilities for common operations
- [ ] Similar code uses parameterization

### Clarity
- [ ] Intention-revealing names
- [ ] No magic numbers (use named constants)
- [ ] Boolean conditions read like sentences

### Type Safety
- [ ] All functions have type hints
- [ ] Return types are specific (not `Any`)
- [ ] TypedDict for structured data
- [ ] NDArray with dtype for NumPy arrays

### Documentation
- [ ] Complex logic has inline comments
- [ ] Public APIs have docstrings
- [ ] Edge cases are documented

## Tool Integration

### Serena (Code Analysis)

**Understand structure:**
```python
get_symbols_overview(relative_path="module/file.py")
find_symbol(name_path_pattern="ClassName", depth=1)
```

**Find duplication:**
```python
search_for_pattern(substring_pattern=r"pattern", paths_include_glob="**/*.py")
```

**Make edits:**
```python
replace_symbol_body(name_path="function_name", relative_path="...", body="...")
insert_after_symbol(name_path="existing", relative_path="...", body="...")
```

### Exa (Best Practices)

```python
get_code_context_exa(
    "Python type hints best practices TypedDict NDArray"
)
```

### Ref (Documentation)

```python
ref_search_documentation("Python refactoring patterns clean code")
ref_read_url("https://docs.python.org/3/library/typing.html")
```

### Sequential Thinking (Complex Planning)

```python
# For multi-step refactoring
# Break down the problem, identify alternatives, verify approach
```

## Additional Resources

### Reference Files

For detailed patterns and examples:
- **`references/patterns.md`** - Comprehensive refactoring patterns with before/after
- **`references/anti-patterns.md`** - Common Python mistakes to avoid

## Principles

1. **Do No Harm** - Tests must pass before and after
2. **Small Steps** - One small change at a time
3. **No Over-Engineering** - Simple is better than clever
4. **Preserve Behavior** - Refactoring never changes functionality
5. **Test Coverage** - Ensure tests exist before refactoring

## Common Mistakes to Avoid

- **Over-abstracting** - Don't create single-use "helpers"
- **Premature optimization** - Profile before optimizing
- **Chasing trends** - Use patterns that fit, not what's fashionable
- **Ignoring tests** - Never refactor without test coverage
- **Changing interfaces** - Refactoring is internal, API changes are redesign

---

Remember: The best code is code that doesn't exist. Delete unnecessary code before adding more.
