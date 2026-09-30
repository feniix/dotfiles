# Python Refactoring Patterns

Detailed refactoring patterns with before/after examples for common Python code issues.

## Table of Contents

1. [Extract Method](#extract-method)
2. [Extract Function](#extract-function)
3. [Early Return](#early-return)
4. [Guard Clauses](#guard-clauses)
5. [Parameter Object](#parameter-object)
6. [Introduce Named Constant](#introduce-named-constant)
7. [Replace Conditional with Polymorphism](#replace-conditional-with-polymorphism)
8. [Decompose Conditional](#decompose-conditional)
9. [Consolidate Conditional](#consolidate-conditional)
10. [Replace Magic Number with Constant](#replace-magic-number-with-constant)
11. [NumPy Vectorization](#numpy-vectorization)
12. [Generator Expressions](#generator-expressions)

---

## Extract Method

**Problem:** A method is too long or does multiple things.

**Solution:** Extract logical units into separate methods with descriptive names.

```python
# Before
def process_video(video_path, output_path=None):
    cap = cv2.VideoCapture(video_path)
    frames = []
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)
    cap.release()

    pose = pose_detector.detect(frames)
    smoothed = smooth_landmarks(pose, window=5)
    filtered = apply_filter(smoothed, cutoff=6.0)

    metrics = {}
    metrics['height'] = calculate_jump_height(filtered)
    metrics['flight_time'] = calculate_flight_time(filtered)
    metrics['countermovement'] = find_countermovement_depth(filtered)

    if output_path:
        writer = cv2.VideoWriter(output_path, fourcc, 30, (width, height))
        for frame, landmarks in zip(frames, filtered):
            annotated = draw_landmarks(frame, landmarks)
            writer.write(annotated)
        writer.release()

    return metrics

# After
def process_video(video_path: str, output_path: Optional[str] = None) -> dict:
    frames = _load_frames(video_path)
    landmarks = _detect_landmarks(frames)
    processed = _process_landmarks(landmarks)
    metrics = _calculate_all_metrics(processed)

    if output_path:
        _save_debug_video(frames, processed, output_path)

    return metrics

def _load_frames(video_path: str) -> list[np.ndarray]:
    cap = cv2.VideoCapture(video_path)
    frames = []
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)
    cap.release()
    return frames

def _detect_landmarks(frames: list[np.ndarray]) -> np.ndarray:
    return pose_detector.detect(frames)

def _process_landmarks(landmarks: np.ndarray) -> np.ndarray:
    smoothed = smooth_landmarks(landmarks, window=5)
    return apply_filter(smoothed, cutoff=6.0)

def _calculate_all_metrics(processed: np.ndarray) -> dict:
    return {
        'height': calculate_jump_height(processed),
        'flight_time': calculate_flight_time(processed),
        'countermovement': find_countermovement_depth(processed),
    }

def _save_debug_video(frames: list, landmarks: np.ndarray, path: str) -> None:
    writer = cv2.VideoWriter(path, fourcc, 30, (width, height))
    for frame, landmark in zip(frames, landmarks):
        annotated = draw_landmarks(frame, landmark)
        writer.write(annotated)
    writer.release()
```

**Benefits:**
- Each function has a single responsibility
- Easier to test individual components
- Easier to understand the high-level flow
- Can reuse extracted functions

---

## Extract Function

**Problem:** Similar code appears in multiple functions.

**Solution:** Extract shared logic to a function.

```python
# Before - duplicated validation
class CMJAnalyzer:
    def validate(self, data):
        if data is None:
            raise ValueError("Data cannot be None")
        if len(data) == 0:
            raise ValueError("Data cannot be empty")
        if not isinstance(data, np.ndarray):
            raise TypeError("Data must be ndarray")
        # ... CMJ-specific validation

class DropJumpAnalyzer:
    def validate(self, data):
        if data is None:
            raise ValueError("Data cannot be None")
        if len(data) == 0:
            raise ValueError("Data cannot be empty")
        if not isinstance(data, np.ndarray):
            raise TypeError("Data must be ndarray")
        # ... DJ-specific validation

# After - shared validation
def validate_input_array(
    data: Optional[np.ndarray],
    name: str = "data",
    min_length: int = 1
) -> np.ndarray:
    """Validate input array meets requirements."""
    if data is None:
        raise ValueError(f"{name} cannot be None")
    if not isinstance(data, np.ndarray):
        raise TypeError(f"{name} must be ndarray, got {type(data)}")
    if len(data) < min_length:
        raise ValueError(f"{name} must have at least {min_length} elements")
    return data

class CMJAnalyzer:
    def validate(self, data):
        data = validate_input_array(data, "CMJ data", min_length=10)
        # ... CMJ-specific validation

class DropJumpAnalyzer:
    def validate(self, data):
        data = validate_input_array(data, "Drop jump data", min_length=5)
        # ... DJ-specific validation
```

---

## Early Return

**Problem:** Deep nesting makes code hard to read.

**Solution:** Handle edge cases first, then return main logic.

```python
# Before - deeply nested
def get_metrics(video_path: Optional[str], quality: str) -> Optional[dict]:
    if video_path is not None:
        if os.path.exists(video_path):
            if video_path.endswith('.mp4'):
                if quality in ['fast', 'balanced', 'accurate']:
                    # Actual logic here
                    return process(video_path, quality)
                else:
                    raise ValueError("Invalid quality")
            else:
                raise ValueError("Not an MP4")
        else:
            raise FileNotFoundError("Video not found")
    else:
        return None

# After - flat, linear
def get_metrics(video_path: Optional[str], quality: str) -> Optional[dict]:
    if video_path is None:
        return None

    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video not found: {video_path}")

    if not video_path.endswith('.mp4'):
        raise ValueError("Only MP4 videos supported")

    if quality not in ('fast', 'balanced', 'accurate'):
        raise ValueError(f"Invalid quality: {quality}")

    return process(video_path, quality)
```

---

## Guard Clauses

**Problem:** Multiple conditions creating complex logic flow.

**Solution:** Use guard clauses to fail fast.

```python
# Before
def process_payment(user, amount, card):
    if user is not None:
        if user.is_active:
            if amount > 0:
                if card is not None:
                    if card.is_valid:
                        # Process payment
                        pass
                    else:
                        raise ValueError("Invalid card")
                else:
                    raise ValueError("No card provided")
            else:
                raise ValueError("Invalid amount")
        else:
            raise ValueError("User inactive")
    else:
        raise ValueError("No user")

# After
def process_payment(user, amount, card):
    if user is None:
        raise ValueError("No user provided")
    if not user.is_active:
        raise ValueError("User is inactive")
    if amount <= 0:
        raise ValueError("Amount must be positive")
    if card is None:
        raise ValueError("No card provided")
    if not card.is_valid:
        raise ValueError("Card is invalid")

    # Process payment - all checks passed
    return _charge_card(card, amount)
```

---

## Parameter Object

**Problem:** Too many parameters, hard to remember order.

**Solution:** Group related parameters into objects.

```python
# Before
def analyze_video(
    path: str,
    quality: str,
    smoothing_window: int,
    filter_cutoff: float,
    min_confidence: float,
    debug_mode: bool,
    output_path: Optional[str],
    show_progress: bool,
    num_workers: int
) -> dict:
    pass

# Hard to call, easy to mess up
result = analyze_video(
    "video.mp4",
    "balanced",
    5,
    6.0,
    0.5,
    False,
    None,
    True,
    4
)

# After
@dataclass
class AnalysisConfig:
    quality: str = "balanced"
    smoothing_window: int = 5
    filter_cutoff: float = 6.0
    min_confidence: float = 0.5
    num_workers: int = 1

@dataclass
class DebugConfig:
    enabled: bool = False
    output_path: Optional[str] = None
    show_progress: bool = False

def analyze_video(
    path: str,
    config: AnalysisConfig = AnalysisConfig(),
    debug: DebugConfig = DebugConfig()
) -> dict:
    pass

# Clear and extensible
result = analyze_video(
    "video.mp4",
    config=AnalysisConfig(
        quality="balanced",
        smoothing_window=5
    ),
    debug=DebugConfig(show_progress=True)
)
```

---

## Introduce Named Constant

**Problem:** Magic numbers scattered in code.

**Solution:** Extract to named constants.

```python
# Before
def process_landmarks(landmarks):
    if len(landmarks) < 33:
        raise ValueError("Invalid landmarks")

    # MediaPipe pose has 33 landmarks
    nose = landmarks[0]
    left_hip = landmarks[23]
    right_hip = landmarks[24]

    # 6 Hz is typical filter cutoff for human movement
    filtered = butterworth(landmarks, cutoff=6.0)

    # 5 frame window for smoothing
    smoothed = moving_average(filtered, window=5)

    return smoothed

# After
class MediaPipe:
    NUM_LANDMARKS = 33
    NOSE_INDEX = 0
    LEFT_HIP_INDEX = 23
    RIGHT_HIP_INDEX = 24

class Filter:
    HUMAN_MOVEMENT_CUTOFF_HZ = 6.0
    DEFAULT_SMOOTHING_WINDOW = 5

def process_landmarks(landmarks: np.ndarray) -> np.ndarray:
    if len(landmarks) < MediaPipe.NUM_LANDMARKS:
        raise ValueError(f"Expected {MediaPipe.NUM_LANDMARKS} landmarks")

    nose = landmarks[MediaPipe.NOSE_INDEX]
    left_hip = landmarks[MediaPipe.LEFT_HIP_INDEX]
    right_hip = landmarks[MediaPipe.RIGHT_HIP_INDEX]

    filtered = butterworth(landmarks, cutoff=Filter.HUMAN_MOVEMENT_CUTOFF_HZ)
    return moving_average(filtered, window=Filter.DEFAULT_SMOOTHING_WINDOW)
```

---

## Replace Conditional with Polymorphism

**Problem:** Complex switch/conditional based on type.

**Solution:** Use polymorphism with classes.

```python
# Before
def process_jump(jump_type: str, data: np.ndarray) -> dict:
    if jump_type == "cmj":
        # CMJ-specific logic
        peak = find_peak_backward(data)
        depth = calculate_countermovement(data)
        return {"jump_height": height_from_peak(peak), "depth": depth}
    elif jump_type == "drop_jump":
        # DJ-specific logic
        contact = find_ground_contact(data)
        rsi = calculate_rsi(data, contact)
        return {"rsi": rsi, "contact_time": contact}
    elif jump_type == "sprint":
        # Sprint-specific logic
        velocity = calculate_velocity(data)
        return {"max_velocity": velocity.max()}
    else:
        raise ValueError(f"Unknown jump type: {jump_type}")

# After
from abc import ABC, abstractmethod

class JumpAnalyzer(ABC):
    @abstractmethod
    def analyze(self, data: np.ndarray) -> dict:
        pass

class CMJAnalyzer(JumpAnalyzer):
    def analyze(self, data: np.ndarray) -> dict:
        peak = find_peak_backward(data)
        depth = calculate_countermovement(data)
        return {"jump_height": height_from_peak(peak), "depth": depth}

class DropJumpAnalyzer(JumpAnalyzer):
    def analyze(self, data: np.ndarray) -> dict:
        contact = find_ground_contact(data)
        rsi = calculate_rsi(data, contact)
        return {"rsi": rsi, "contact_time": contact}

class SprintAnalyzer(JumpAnalyzer):
    def analyze(self, data: np.ndarray) -> dict:
        velocity = calculate_velocity(data)
        return {"max_velocity": velocity.max()}

# Registry
ANALYZERS = {
    "cmj": CMJAnalyzer(),
    "drop_jump": DropJumpAnalyzer(),
    "sprint": SprintAnalyzer(),
}

def process_jump(jump_type: str, data: np.ndarray) -> dict:
    analyzer = ANALYZERS.get(jump_type)
    if analyzer is None:
        raise ValueError(f"Unknown jump type: {jump_type}")
    return analyzer.analyze(data)
```

---

## Decompose Conditional

**Problem:** Complex conditional that's hard to understand.

**Solution:** Extract conditions to well-named functions.

```python
# Before
def should_use_auto_tuning(video_length, frame_rate, quality, has_validation_data):
    if quality == "fast" and video_length < 300 and frame_rate == 30:
        return True
    if quality == "balanced" and video_length < 600 and has_validation_data:
        return True
    if quality == "accurate" and has_validation_data and video_length > 100:
        return True
    return False

# After
def should_use_auto_tuning(
    video_length: int,
    frame_rate: int,
    quality: str,
    has_validation_data: bool
) -> bool:
    if _is_fast_quality_with_short_video(quality, video_length, frame_rate):
        return True
    if _is_balanced_quality_with_validation(quality, video_length, has_validation_data):
        return True
    if _is_accurate_quality_with_validation(quality, has_validation_data, video_length):
        return True
    return False

def _is_fast_quality_with_short_video(quality: str, length: int, fps: int) -> bool:
    return quality == "fast" and length < 300 and fps == 30

def _is_balanced_quality_with_validation(quality: str, length: int, has_validation: bool) -> bool:
    return quality == "balanced" and length < 600 and has_validation

def _is_accurate_quality_with_validation(quality: str, has_validation: bool, length: int) -> bool:
    return quality == "accurate" and has_validation and length > 100
```

---

## Consolidate Conditional

**Problem:** Multiple conditionals returning same value.

**Solution:** Combine into single condition.

```python
# Before
def can_process(video_path: str) -> bool:
    if not os.path.exists(video_path):
        return False
    if not video_path.endswith('.mp4'):
        return False
    if not video_path.endswith('.MP4'):
        return False
    if os.path.getsize(video_path) == 0:
        return False
    return True

# After
def can_process(video_path: str) -> bool:
    return (
        os.path.exists(video_path) and
        video_path.lower().endswith('.mp4') and
        os.path.getsize(video_path) > 0
    )
```

---

## NumPy Vectorization

**Problem:** Python loops are slow for array operations.

**Solution:** Use NumPy vectorized operations.

```python
# Before - O(n) Python loop
def normalize(data: np.ndarray) -> np.ndarray:
    mean = np.mean(data)
    std = np.std(data)
    result = np.zeros_like(data)
    for i in range(len(data)):
        result[i] = (data[i] - mean) / std
    return result

# After - vectorized, 100x faster
def normalize(data: NDArray[np.float64]) -> NDArray[np.float64]:
    mean = np.mean(data)
    std = np.std(data)
    return (data - mean) / std

# Before - nested loops for 2D array
def distance_matrix(points: np.ndarray) -> np.ndarray:
    n = len(points)
    distances = np.zeros((n, n))
    for i in range(n):
        for j in range(n):
            distances[i, j] = np.linalg.norm(points[i] - points[j])
    return distances

# After - broadcasting
def distance_matrix(points: NDArray[np.float64]) -> NDArray[np.float64]:
    # points: (n, 2) or (n, 3)
    diff = points[:, np.newaxis, :] - points[np.newaxis, :, :]  # (n, n, d)
    return np.sqrt(np.sum(diff ** 2, axis=2))

# Before - conditional in loop
def threshold_and_clip(data: np.ndarray, threshold: float, max_val: float) -> np.ndarray:
    result = np.zeros_like(data)
    for i, val in enumerate(data):
        if val > threshold:
            result[i] = min(val, max_val)
    return result

# After - boolean indexing + clip
def threshold_and_clip(
    data: NDArray[np.float64],
    threshold: float,
    max_val: float
) -> NDArray[np.float64]:
    mask = data > threshold
    result = np.zeros_like(data)
    result[mask] = np.clip(data[mask], None, max_val)
    return result
```

---

## Generator Expressions

**Problem:** Creating intermediate lists wastes memory.

**Solution:** Use generators for lazy evaluation.

```python
# Before - creates intermediate list
def get_valid_frames(frames: list[np.ndarray]) -> list[np.ndarray]:
    valid = []
    for frame in frames:
        if frame is not None and frame.size > 0:
            valid.append(frame)
    return valid

# After - generator expression
def get_valid_frames(frames: list[np.ndarray]) -> list[np.ndarray]:
    return [f for f in frames if f is not None and f.size > 0]

# Or using generator for large sequences
def process_frames(frames: Iterable[np.ndarray]) -> Iterator[np.ndarray]:
    return (f for f in frames if f is not None and f.size > 0)

# Before - multiple passes over data
def analyze(data: list[float]) -> dict:
    positive = [x for x in data if x > 0]
    negative = [x for x in data if x < 0]
    zeros = [x for x in data if x == 0]
    return {"positive": len(positive), "negative": len(negative), "zeros": len(zeros)}

# After - single pass
def analyze(data: list[float]) -> dict:
    counts = {"positive": 0, "negative": 0, "zeros": 0}
    for x in data:
        if x > 0:
            counts["positive"] += 1
        elif x < 0:
            counts["negative"] += 1
        else:
            counts["zeros"] += 1
    return counts
```

---

## When NOT to Refactor

**Don't refactor when:**
- There are no tests to verify behavior
- The code works well enough and isn't touched often
- You don't understand what the code does
- You're about to delete the code
- The "improvement" is purely stylistic and subjective
