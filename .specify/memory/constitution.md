<!--
Sync Impact Report
- Version change: (template) → 1.0.0
- Modified principles: none (initial adoption)
- Added principles:
  I. Never Crash the Host App
  II. Thread Safety
  III. Protocol-Oriented Extensibility
  IV. Test Coverage (NON-NEGOTIABLE)
  V. Backwards-Compatible Public API
- Added sections: Platform & Code Standards, Development Workflow, Governance
- Removed sections: none
- Templates:
  ✅ .specify/templates/plan-template.md (Constitution Check gates are derived per plan; no edit needed)
  ✅ .specify/templates/spec-template.md (no constitution-driven mandatory sections; no edit needed)
  ✅ .specify/templates/tasks-template.md (test/lint tasks already expressible; no edit needed)
  ✅ CLAUDE.md (source of these rules; consistent)
- Deferred TODOs: none
-->

# Optimizely Swift SDK Constitution

## Core Principles

### I. Never Crash the Host App

The SDK runs inside customers' apps; a failure in the SDK MUST NOT take the app down.

- SDK-specific failures MUST be expressed with `OptimizelyError` and surfaced via
  `throws` or `OptimizelyResult<T>`, never via `fatalError`, force-unwraps on external
  input, or unchecked casts of datafile/network data.
- Invalid datafiles, network failures, and bad user input MUST degrade gracefully
  (e.g., return a default/off decision) and be logged with a meaningful message at the
  appropriate level (debug, info, warning, error) through `OPTLogger`.

### II. Thread Safety

Public APIs can be called from any thread, concurrently.

- Shared mutable state MUST use `AtomicProperty`, `AtomicArray`, `AtomicDictionary`
  (from `Sources/Utils/`) or an equivalent serial-queue guard.
- Event dispatchers, managers, and caches MUST be safe under concurrent access.
- Tests for concurrent behavior MUST use deterministic synchronization
  (e.g., `DispatchGroup`, expectations), not `asyncAfter` delays.

### III. Protocol-Oriented Extensibility

Customer-replaceable behavior is defined by protocols with default implementations.

- Extension points (`OPTLogger`, `OPTEventDispatcher`, `OPTDatafileHandler`,
  `OPTUserProfileService`, and similar) MUST remain protocols; default implementations
  live in `Sources/Customization/`.
- New pluggable behavior MUST follow the same pattern: protocol first, default
  implementation second, injected through `OptimizelyClient` initialization.

### IV. Test Coverage (NON-NEGOTIABLE)

All code changes MUST ship with XCTest coverage.

- Tests MUST use JSON fixtures from `Tests/TestData/` for datafile-driven scenarios.
- `JSONEncoder` in tests MUST use `.sortedKeys` for deterministic output.
- Network calls MUST be mocked/overridden; tests MUST NOT depend on live endpoints.
- Tests using persistent storage MUST use unique file names.
- New test files MUST be registered in `OptimizelySwiftSDK.xcodeproj/project.pbxproj`
  for both iOS and tvOS targets (4 targets for shared base classes); creating the file
  alone is insufficient.

Rationale: the SDK is built and tested through both SPM and the Xcode project; tests not
registered in the project silently do not run in CI.

### V. Backwards-Compatible Public API

Customers upgrade by version constraint (`~> 5.x`); upgrades MUST be safe.

- Public API changes MUST be additive within a major version. Removals, renames, or
  behavior changes to existing public API require a MAJOR version.
- Deprecate before removing; deprecated API MUST keep working until the next MAJOR.
- The SDK follows semantic versioning: MAJOR for breaking changes, MINOR for
  backwards-compatible features, PATCH for bug fixes only.

## Platform & Code Standards

- Supported platforms: iOS 10.0+, tvOS 10.0+, macOS 10.14+, watchOS 3.0+; Swift 5
  (`swift-tools-version:5.3`). Changes MUST NOT raise these minimums without a MAJOR
  release decision.
- Distribution: Swift Package Manager (preferred) and CocoaPods. Both MUST build.
- Code MUST follow the Ray Wenderlich Swift Style Guide and pass `swiftlint`
  (config in `.swiftlint.yml`) with no warnings or errors.

## Development Workflow

- Never commit directly to `master`; work on `YOUR_NAME/branch_name` feature branches.
- Before opening a PR: all tests pass, SwiftLint is clean, and the branch merges cleanly
  with `origin/master`.
- PR descriptions MUST follow `pull_request_template.md`: Summary (what and why),
  Test plan, and Issues (ticket reference, e.g., FSSDK-XXXXX, or justification).
- Contributors MUST NOT bump the SDK version; version files (`.github/workflows/swift.yml`,
  `CHANGELOG.md`, `README.md`) are updated by maintainers in release PRs only.
- Changes require review from a code owner.

## Governance

This constitution supersedes conflicting practices for work in this repository.
`CLAUDE.md` holds detailed runtime guidance (commands, file locations, release steps) and
MUST stay consistent with these principles.

- Amendments are made by PR that updates this file, includes a Sync Impact Report, and
  propagates changes to `.specify/templates/` and `CLAUDE.md` as needed.
- Constitution versioning: MAJOR for removing or redefining a principle, MINOR for adding
  a principle/section or materially expanding guidance, PATCH for clarifications.
- Every plan's Constitution Check and every PR review MUST verify compliance; any
  violation MUST be justified in the plan's Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-09-23 | **Last Amended**: 2026-09-23
