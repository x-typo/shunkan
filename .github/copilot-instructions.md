# Copilot Code Review Instructions

This is an iOS RSVP speed reader app built with SwiftUI and SwiftData.
Flag violations of these conventions during review.

## Architecture

- **MVVM-inspired**: Views bind to `@Observable` services, models are SwiftData `@Model` classes.
- Services (`RSVPEngine`, `ImportService`, `PDFParserService`) handle business logic. Views are thin.
- Utilities (`Tokenizer`, `ORPCalculator`) are pure functions with no state.
- Share extension (`ShunkanShare`) imports PDFs via app group. Changes to file paths must account for both targets.

## SwiftData

- All persistent models use `@Model` macro.
- Relationships use `@Relationship(inverse:)` with explicit inverse declarations.
- Identity via `persistentModelID`. Custom `Hashable` must use this, not value equality.
- Computed properties for derived values (`progress`, `isComplete`). No stored duplicates.
- Model container configured once at app entry (`ShunkanApp.swift`).

## Concurrency

- `@MainActor` on services that update UI state (`RSVPEngine`, `ImportService`).
- `@Observable` stores are MainActor-assumed. Flag missing `@MainActor` annotations.
- Task lifecycle: `playbackTask?.cancel()` before starting new playback. Flag leaked tasks.
- `CancellationError` caught separately from other errors in async contexts.
- Notification Center observers for app lifecycle (foreground detection). Clean up on deinit.

## Error Handling

- Custom error enums conforming to `LocalizedError` (e.g., `PDFParseError`).
- Error messages must be user-facing and descriptive (what failed, not stack traces).
- Critical file operations use `try`. Non-critical cleanup uses `try?`.
- Import errors surface via `importError` state shown in alert dialogs.

## File I/O

- Security-scoped URLs: wrap with `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`. Flag missing pairs.
- Use `FileManager` extensions for consistent path management (`FileManager+Books.swift`).
- App group container paths for share extension compatibility. Flag hardcoded paths.
- Atomic file writes (`atomically: true`). Flag non-atomic writes to user data.

## PDF Processing

- `PDFKit` for extraction (text, chapters, thumbnails). No external PDF libraries.
- `PDFParserService` handles all parsing. Flag PDF logic in views or models.
- Chapter detection from PDF outline/bookmarks. Fallback to page-based navigation.
- Thumbnail generation for library display. Cache thumbnails, don't regenerate on every render.

## RSVP Engine

- `RSVPEngine` is the playback state machine. All playback state changes go through it.
- WPM range: 100-900. Flag values outside this range.
- Paragraph sentinel (Unicode U+2029) used for pause detection. Document any new sentinel values.
- Word index tracking must be consistent with `Tokenizer` output. Flag index arithmetic that doesn't account for sentinels.
- WPM preference persisted in UserDefaults (`shunkan_wpm` key).

## SwiftUI Patterns

- `NavigationStack` with `navigationDestination` for player navigation.
- State-driven rendering: loading, error, empty, content states all handled.
- `Binding(get:set:)` for two-way bindings to observable properties (e.g., WPM slider).
- Sorting and collection filtering state managed in parent views, not child components.
- Reusable components (`PillButton`, `WordDisplayView`) as private/internal types.

## Tokenizer & ORP

- `Tokenizer` is a pure utility. No state, no side effects.
- `ORPCalculator` computes optimal reading point per word. Algorithm changes need test coverage.
- Flag any word processing logic outside these two utilities.

## Testing

- Swift Testing framework (`@Suite`, `@Test`, `#expect`) for new unit tests.
- XCTest for UI tests (`XCUIApplication`).
- Priority test targets: `Tokenizer`, `ORPCalculator`, `RSVPEngine` state transitions.
- Include sample PDF fixtures for import/parsing tests.
- New parsing or formatting logic must include tests.

## Naming

- Types: PascalCase with purpose suffix (`Engine`, `Service`, `Store`, `View`).
- Functions/properties: camelCase.
- File names match the primary type.
- `// MARK: -` for section organization.
- Sentinel values and magic numbers must be named constants with documentation.
