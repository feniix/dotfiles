# TypeScript/JavaScript Performance Patterns

Detailed optimization patterns for TypeScript and JavaScript code.

## Profiling Tools

### Chrome DevTools Performance

1. Open DevTools (F12)
2. Go to Performance tab
3. Click Record, perform actions, click Stop
4. Analyze flame chart for bottlenecks

Key metrics:
- **Scripting**: JavaScript execution time
- **Rendering**: Layout and paint operations
- **Idle**: Available optimization opportunity

### Node.js Profiling

```bash
# CPU profiling with V8 profiler
node --prof app.js
node --prof-process isolate-*.log > profile.txt

# Inspect mode for Chrome DevTools
node --inspect app.js
# Open chrome://inspect in Chrome

# With specific options
node --inspect-brk app.js  # Break on first line
```

### Memory Profiling

```bash
# Heap snapshots
node --inspect --expose-gc app.js

# Memory limit testing
node --expose-gc --max-old-space-size=256 app.js

# Heap dump on signal
node --heapsnapshot-signal=SIGUSR2 app.js
kill -USR2 <pid>  # Generates heap snapshot
```

## Async Optimization

### Parallel vs Sequential Execution

```typescript
// SLOW: Sequential - each waits for previous
async function fetchSequential(urls: string[]) {
    const results = [];
    for (const url of urls) {
        results.push(await fetch(url));  // Waits each time
    }
    return results;
}
// Time: n * avgLatency

// FAST: Parallel - all start immediately
async function fetchParallel(urls: string[]) {
    return Promise.all(urls.map(url => fetch(url)));
}
// Time: max(latencies)
```

### Controlled Concurrency

```typescript
// Limit concurrent operations to avoid overwhelming resources
async function fetchWithLimit(urls: string[], limit: number) {
    const results: Response[] = [];
    const executing: Promise<void>[] = [];

    for (const url of urls) {
        const promise = fetch(url).then(r => { results.push(r); });
        executing.push(promise);

        if (executing.length >= limit) {
            await Promise.race(executing);
            executing.splice(executing.findIndex(p => p === promise), 1);
        }
    }

    await Promise.all(executing);
    return results;
}
```

### Avoid Await in Loops

```typescript
// SLOW: ESLint no-await-in-loop violation
async function processItems(items: Item[]) {
    for (const item of items) {
        await processItem(item);  // Sequential!
    }
}

// FAST: Collect promises, await all
async function processItems(items: Item[]) {
    const promises = items.map(item => processItem(item));
    await Promise.all(promises);
}
```

### Promise.allSettled for Error Tolerance

```typescript
// When some failures are acceptable
async function fetchAll(urls: string[]) {
    const results = await Promise.allSettled(
        urls.map(url => fetch(url))
    );

    return results
        .filter((r): r is PromiseFulfilledResult<Response> =>
            r.status === 'fulfilled')
        .map(r => r.value);
}
```

## Memory Leak Prevention

### Event Listener Cleanup

```typescript
// LEAK: Listener never removed
class Component {
    constructor() {
        window.addEventListener('resize', this.handleResize);
    }

    handleResize = () => { /* ... */ };
}

// FIXED: Clean up on destroy
class Component {
    constructor() {
        window.addEventListener('resize', this.handleResize);
    }

    handleResize = () => { /* ... */ };

    destroy() {
        window.removeEventListener('resize', this.handleResize);
    }
}
```

### AbortController for Fetch Cleanup

```typescript
class DataFetcher {
    private controller?: AbortController;

    async fetch(url: string) {
        // Cancel previous request
        this.controller?.abort();
        this.controller = new AbortController();

        try {
            return await fetch(url, { signal: this.controller.signal });
        } catch (e) {
            if (e instanceof DOMException && e.name === 'AbortError') {
                return null;  // Intentionally cancelled
            }
            throw e;
        }
    }

    cancel() {
        this.controller?.abort();
    }
}
```

### Interval/Timeout Cleanup

```typescript
// LEAK: Interval never cleared
class Poller {
    start() {
        setInterval(() => this.poll(), 1000);
    }
}

// FIXED: Track and clear
class Poller {
    private intervalId?: NodeJS.Timeout;

    start() {
        this.intervalId = setInterval(() => this.poll(), 1000);
    }

    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = undefined;
        }
    }
}
```

### WeakMap/WeakSet for Object Metadata

```typescript
// LEAK: Map holds strong references
const metadata = new Map<object, Data>();
// Objects can't be garbage collected while in map

// FIXED: WeakMap allows GC
const metadata = new WeakMap<object, Data>();
// When object has no other references, entry is auto-removed
```

### Closure Memory Leaks

```typescript
// LEAK: Closure captures large object unnecessarily
function createHandler() {
    const largeData = loadHugeDataset();  // Captured!

    return () => {
        console.log('Handler called');
        // Doesn't use largeData, but it's still captured
    };
}

// FIXED: Don't capture what you don't need
function createHandler() {
    const largeData = loadHugeDataset();
    const summary = computeSummary(largeData);  // Extract needed data

    return () => {
        console.log('Summary:', summary);
        // largeData can be garbage collected
    };
}
```

## Long Task Optimization

### Break Up Long Tasks

```typescript
// BLOCKING: Freezes UI
function processLargeArray(data: number[]) {
    return data.map(x => expensiveOperation(x));
}

// NON-BLOCKING: Yields to browser
async function processLargeArray(data: number[]) {
    const results: number[] = [];
    const CHUNK_SIZE = 100;

    for (let i = 0; i < data.length; i += CHUNK_SIZE) {
        const chunk = data.slice(i, i + CHUNK_SIZE);
        results.push(...chunk.map(x => expensiveOperation(x)));

        // Yield to browser
        await new Promise(resolve => setTimeout(resolve, 0));
    }

    return results;
}
```

### Web Workers for CPU-Intensive Tasks

```typescript
// main.ts
const worker = new Worker('worker.js');

worker.postMessage({ data: largeDataset });

worker.onmessage = (event) => {
    console.log('Result:', event.data);
};

// worker.ts
self.onmessage = (event) => {
    const result = expensiveComputation(event.data);
    self.postMessage(result);
};
```

### requestIdleCallback for Non-Urgent Work

```typescript
function processWhenIdle(tasks: (() => void)[]) {
    let index = 0;

    function processTasks(deadline: IdleDeadline) {
        while (index < tasks.length && deadline.timeRemaining() > 0) {
            tasks[index]();
            index++;
        }

        if (index < tasks.length) {
            requestIdleCallback(processTasks);
        }
    }

    requestIdleCallback(processTasks);
}
```

## Data Structure Optimization

### Object vs Map for Dynamic Keys

```typescript
// Object: Good for static, known keys
const config = { host: 'localhost', port: 3000 };

// Map: Better for dynamic keys, frequent add/delete
const cache = new Map<string, Data>();
cache.set(key, value);
cache.delete(key);
// Map maintains insertion order, has .size property
```

### Set for Unique Values

```typescript
// SLOW: Array includes is O(n)
const seen: string[] = [];
if (!seen.includes(item)) {
    seen.push(item);
}

// FAST: Set has is O(1)
const seen = new Set<string>();
seen.add(item);  // Automatically handles duplicates
```

### TypedArrays for Numeric Data

```typescript
// Regular array: ~8 bytes per number + object overhead
const numbers = [1.0, 2.0, 3.0];

// Float64Array: Exactly 8 bytes per number, contiguous memory
const numbers = new Float64Array([1.0, 2.0, 3.0]);

// Good for: Image processing, audio, scientific computing
```

## React-Specific Optimizations

### useMemo for Expensive Computations

```typescript
// SLOW: Recomputes on every render
function Component({ data }: Props) {
    const processed = expensiveProcess(data);  // Every render!
    return <Display data={processed} />;
}

// FAST: Only recomputes when data changes
function Component({ data }: Props) {
    const processed = useMemo(
        () => expensiveProcess(data),
        [data]
    );
    return <Display data={processed} />;
}
```

### useCallback for Stable References

```typescript
// SLOW: New function every render, breaks memo
function Parent() {
    const handleClick = () => { /* ... */ };
    return <MemoizedChild onClick={handleClick} />;
}

// FAST: Stable reference
function Parent() {
    const handleClick = useCallback(() => { /* ... */ }, []);
    return <MemoizedChild onClick={handleClick} />;
}
```

### Virtualization for Long Lists

```typescript
// SLOW: Renders all 10,000 items
function List({ items }: { items: Item[] }) {
    return (
        <ul>
            {items.map(item => <ListItem key={item.id} {...item} />)}
        </ul>
    );
}

// FAST: Only renders visible items
import { FixedSizeList } from 'react-window';

function List({ items }: { items: Item[] }) {
    return (
        <FixedSizeList
            height={400}
            itemCount={items.length}
            itemSize={35}
        >
            {({ index, style }) => (
                <ListItem style={style} {...items[index]} />
            )}
        </FixedSizeList>
    );
}
```

## Bundle Optimization

### Code Splitting

```typescript
// SLOW: All code in one bundle
import { HeavyComponent } from './HeavyComponent';

// FAST: Lazy load on demand
const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
    return (
        <Suspense fallback={<Loading />}>
            <HeavyComponent />
        </Suspense>
    );
}
```

### Tree Shaking

```typescript
// BAD: Imports entire library
import _ from 'lodash';
_.debounce(fn, 100);

// GOOD: Imports only what's needed
import debounce from 'lodash/debounce';
debounce(fn, 100);
```
