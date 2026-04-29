# AGENTS.md
# Guide for agentic coding tools in this repo.

## Project overview
- Language: Swift
- UI: SwiftUI
- Persistence: SwiftData
- Targets: iOS app + watchOS companion app
- Purpose: collect and export Apple Watch sensor data

## Where things live (high level)
- Shared/: cross-target models, managers, utils, views
- tricorder/: iOS app code
- tricorder Watch App/: watchOS app code
- tricorderTests/: Swift Testing tests

## Build commands (Xcode project)
- Open in Xcode: `open tricorder.xcodeproj`
- Build iOS app: `xcodebuild -scheme tricorder -configuration Debug`
- Build watchOS app: `xcodebuild -scheme "tricorder Watch App" -configuration Debug`
- List schemes: `xcodebuild -list`

## Test commands
- Run all tests (iOS scheme):
  `xcodebuild test -scheme tricorder -destination 'platform=iOS Simulator,name=iPhone 16'`
- Run a single test class:
  `xcodebuild test -scheme tricorder -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:tricorderTests/TopAccelerationClassifierTests`
- Run a single test method:
  `xcodebuild test -scheme tricorder -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:tricorderTests/TopAccelerationClassifierTests/handleAccelerationUpdateWithSingleValue`
- Run tests in Xcode: Cmd+U, or click a test diamond in the Test navigator

## Lint/format commands
- Format all Swift files: `swift format -ri .`
- Lint all Swift files: `swift format lint -r .`
- Config source: `.swift-format` (4-space indent, 100-char line length)

## Code style guidelines
### Formatting
- Indentation: 4 spaces
- Line length: 100 characters
- Semicolons: never
- One blank line max between blocks
- Trailing commas in multi-element collections are enabled

### Imports
- Use ordered imports (alphabetical)
- Prefer system frameworks first (Foundation often first)
- No blank lines between imports
- Attributes like `@preconcurrency` stay on the import line

### Naming
- Types (class/struct/enum/actor/protocol): PascalCase
- Methods, variables, enum cases: lowerCamelCase
- Avoid leading underscores unless necessary
- Type aliases: PascalCase
- Database models end with `DatabaseModel`

### Concurrency and isolation
- Prefer `actor` for shared managers and stateful services
- UI and SwiftUI-facing classes are `@MainActor`
- Delegate entry points often `nonisolated` with explicit bridging

### Error handling
- Use domain-specific error enums conforming to `LocalizedError`
- Avoid `fatalError` in production code; surface errors via managers or UI
- Avoid force unwraps and force casts in production code

### File and folder conventions
- Platform-specific extensions use `+iOS.swift` / `+watchOS.swift`
- Tests live under `tricorderTests/` and use `*Tests.swift`
- Shared code goes in `Shared/` (models, managers, utils)

### SwiftUI patterns
- Environment objects and queries declared near the top
- State managed with `@State`, `@Bindable`, or model bindings
- Break large views into nested structs or extensions

### MARK usage
- Extensions are organized with `// MARK: -  <Section>`
- Often followed by a blank `//` line

## Testing conventions
- Tests use Swift Testing (`@Test`, `#expect`) not XCTest
- Prefer clear Given/When/Then structure
- Keep tests aligned with production folder structure

## Known rules for AI assistants
- Cursor rules: none found in `.cursor/rules/` or `.cursorrules`
- Copilot rules: none found in `.github/copilot-instructions.md`
- Claude local permissions: `.claude/settings.local.json`

## Working expectations for agents
- Follow `.swift-format` rules before committing changes
- Keep platform-specific logic in the corresponding `+iOS`/`+watchOS` files
- Avoid introducing new dependencies unless necessary
- Prefer small, focused changes with clear rationale
- Avoid `any` existentials — use generics or associated types instead. `any` hides type information and adds boxing overhead. Prefer `some Protocol` (opaque types) for return values and generic type parameters (`<T: Protocol>`) for stored properties and function arguments.
