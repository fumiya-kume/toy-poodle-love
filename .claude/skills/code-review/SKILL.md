---
name: code-review
description: |
  This skill should be used when the user asks to "review code",
  "check code quality", "find improvements", "refactor code",
  "fix code issues", "perform code review", "check for bugs",
  "improve code", "analyze code", "review PR", "review pull request",
  "コードレビュー", "コードをチェック", "改善点を探す",
  "リファクタリング", "コード品質を確認", "バグを探す",
  "コードを改善", "PR をレビュー", "プルリクエストをレビュー",
  or needs guidance on code review best practices for Swift and TypeScript.
version: 1.0.0
---

# Code Review

Comprehensive code review skill for Swift (iOS) and TypeScript (Web) codebases with automatic fix capability.

## Overview

**Supported Languages**:
- Swift 5.9+ (iOS 17+, SwiftUI, SwiftData)
- TypeScript 5.x+ (Next.js 14+, React 18+)

**Core Capabilities**:
- Identify code quality issues
- Suggest improvements and refactoring
- Check for common anti-patterns
- Verify best practices compliance
- **Automatically fix identified issues**

## Default Behavior (No Arguments)

When `/code-review` is invoked without specifying a file or directory:

1. **Get changed files** from `git diff master...HEAD --name-only`
2. **Filter** to only `.swift`, `.ts`, `.tsx` files
3. **Read and review** each changed file
4. **Report issues** found in the diff

This is useful for reviewing changes before creating a PR.

```bash
# What gets executed internally:
git diff master...HEAD --name-only | grep -E '\.(swift|ts|tsx)$'
```

### Usage Examples

```
/code-review                    # Review all changes vs master
/code-review path/to/file.swift # Review specific file
/code-review handheld/Sources/  # Review directory
```

## Quick Start Checklist

When reviewing code, check the following:

1. [ ] Identify the language and framework
2. [ ] Check for linting errors (SwiftLint / ESLint)
3. [ ] Verify type safety
4. [ ] Review error handling
5. [ ] Check for memory leaks / performance issues
6. [ ] Verify accessibility compliance (if UI code)
7. [ ] Ensure test coverage for changes

## Auto-Fix Workflow

When performing code review with automatic fixes:

### Step 1: Analyze
Read the target file(s) and identify all issues.

### Step 2: Report Issues
Present issues in a structured format:

```
## Issue #1: [Issue Title]
- **File**: path/to/file.swift:42
- **Severity**: Critical | High | Medium | Low
- **Category**: Memory | Type Safety | Performance | Style
- **Description**: What the problem is
- **Current Code**: (show problematic code)
- **Suggested Fix**: (show corrected code)
```

### Step 3: Apply Fixes
After user confirmation, use the Edit tool to apply fixes:
1. Apply each fix sequentially
2. Verify the fix doesn't break other code
3. Run linter/tests to confirm

### Step 4: Verify
Run appropriate verification commands:
- Swift: `cd handheld && make test`
- TypeScript: `cd web && npm run lint && npm run type-check`

## Swift Code Review

### Critical Checks

| Category | Check | Severity |
|----------|-------|----------|
| Memory | No retain cycles in closures | Critical |
| Concurrency | `@MainActor` for UI updates | Critical |
| Safety | No force unwrapping without safety | High |
| Performance | Avoid unnecessary @State changes | Medium |
| Style | Consistent naming conventions | Low |

### Common Issues and Fixes

#### 1. Force Unwrap Without Safety

```swift
// BAD: Force unwrap can crash
let user = users.first!

// GOOD: Safe unwrapping with guard
guard let user = users.first else {
    return
}
```

#### 2. Missing @MainActor for UI Updates

```swift
// BAD: UI update from background thread
@Observable
class ViewModel {
    var items: [Item] = []  // Can be updated from any thread

    func loadItems() async {
        items = try await api.fetchItems()  // May not be on main thread
    }
}

// GOOD: MainActor ensures UI safety
@Observable
@MainActor
class ViewModel {
    var items: [Item] = []

    func loadItems() async {
        items = try await api.fetchItems()
    }
}
```

#### 3. Retain Cycle in Closure

```swift
// BAD: Strong reference cycle
class ViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = {
            self.doSomething()  // Strong capture of self
        }
    }
}

// GOOD: Weak capture
class ViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = { [weak self] in
            self?.doSomething()
        }
    }
}
```

For more Swift patterns, see [references/swift-checklist.md](references/swift-checklist.md).

## TypeScript Code Review

### Critical Checks

| Category | Check | Severity |
|----------|-------|----------|
| Type Safety | No `any` types without justification | High |
| Null Safety | Proper optional chaining | High |
| React | No missing dependencies in useEffect | Critical |
| Performance | Memoization where needed | Medium |
| Next.js | Correct use of 'use client' | High |

### Common Issues and Fixes

#### 1. Using `any` Type

```typescript
// BAD: Using any loses type safety
const data: any = await fetchData();
console.log(data.user.name);

// GOOD: Proper typing
interface User {
  id: string;
  name: string;
}

interface ApiResponse {
  user: User;
}

const data: ApiResponse = await fetchData();
console.log(data.user.name);
```

#### 2. Missing useEffect Dependencies

```tsx
// BAD: Missing dependency can cause stale closure
function Component({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, []);  // Missing userId dependency

  return <div>{user?.name}</div>;
}

// GOOD: All dependencies included
function Component({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);  // Correct dependencies

  return <div>{user?.name}</div>;
}
```

#### 3. Unnecessary Re-renders

```tsx
// BAD: Object created on every render
function Component() {
  const options = { size: 'large', color: 'blue' };  // New object every render

  return <Child options={options} />;
}

// GOOD: Memoized or constant
const OPTIONS = { size: 'large', color: 'blue' } as const;

function Component() {
  return <Child options={OPTIONS} />;
}

// OR with useMemo for dynamic values
function Component({ color }: { color: string }) {
  const options = useMemo(() => ({ size: 'large', color }), [color]);

  return <Child options={options} />;
}
```

For more TypeScript patterns, see [references/typescript-checklist.md](references/typescript-checklist.md).

## Running Linters

### Swift

```bash
# Run SwiftLint (if configured)
cd handheld && swiftlint

# With autocorrect
swiftlint --fix

# Run tests
make test
```

### TypeScript

```bash
cd web

# Run ESLint
npm run lint

# Run TypeScript type check
npm run type-check

# Fix auto-fixable issues
npm run lint -- --fix

# Run all checks
npm run lint && npm run type-check && npm run build
```

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Crashes, data loss, security issues | Must fix immediately |
| **High** | Bugs, type errors, memory leaks | Should fix before merge |
| **Medium** | Performance, maintainability | Consider fixing |
| **Low** | Style, minor improvements | Optional |

## CI/CD Integration

### iOS (GitHub Actions)

The project runs `make test` which includes:
- Build verification
- Unit tests execution

### Web (GitHub Actions)

The project runs:
- `npm run lint` (ESLint)
- `npm run type-check` (TypeScript)
- `npm run build` (Production build)

## Additional Resources

### References

- **[references/swift-checklist.md](references/swift-checklist.md)** - Complete Swift review checklist
- **[references/swift-anti-patterns.md](references/swift-anti-patterns.md)** - Swift anti-patterns to avoid
- **[references/swift-performance.md](references/swift-performance.md)** - Swift performance optimization
- **[references/swift-concurrency.md](references/swift-concurrency.md)** - Swift concurrency review
- **[references/swift-swiftui.md](references/swift-swiftui.md)** - SwiftUI specific checks
- **[references/typescript-checklist.md](references/typescript-checklist.md)** - Complete TypeScript checklist
- **[references/typescript-anti-patterns.md](references/typescript-anti-patterns.md)** - TypeScript anti-patterns
- **[references/typescript-type-patterns.md](references/typescript-type-patterns.md)** - Type design patterns
- **[references/typescript-nextjs.md](references/typescript-nextjs.md)** - Next.js specific checks
- **[references/typescript-react.md](references/typescript-react.md)** - React specific checks
- **[references/review-process.md](references/review-process.md)** - Review process guide
- **[references/auto-fix-workflow.md](references/auto-fix-workflow.md)** - Auto-fix workflow details

### Examples

- **[examples/swift-before-after.swift](examples/swift-before-after.swift)** - Swift refactoring examples
- **[examples/swift-common-issues.swift](examples/swift-common-issues.swift)** - Common Swift issues
- **[examples/swift-async-patterns.swift](examples/swift-async-patterns.swift)** - async/await patterns
- **[examples/swift-memory-management.swift](examples/swift-memory-management.swift)** - Memory management
- **[examples/typescript-before-after.tsx](examples/typescript-before-after.tsx)** - TypeScript refactoring
- **[examples/typescript-common-issues.ts](examples/typescript-common-issues.ts)** - Common TypeScript issues
- **[examples/typescript-type-safety.ts](examples/typescript-type-safety.ts)** - Type safety patterns
- **[examples/typescript-react-patterns.tsx](examples/typescript-react-patterns.tsx)** - React best practices
