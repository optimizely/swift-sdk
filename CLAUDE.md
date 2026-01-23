# Optimizely Swift SDK - Claude Code Context

## Project Overview
This is the Optimizely Swift SDK for Feature Experimentation and Full Stack. It provides A/B testing and feature management capabilities for iOS, tvOS, and watchOS platforms.

## Getting Started

### Platform Support
- iOS 10.0+
- tvOS 10.0+
- watchOS 3.0+
- Swift 5+

### Installation Methods
- Swift Package Manager (preferred)
- CocoaPods

### Dependencies
- SwiftLint (development)

### Initial Setup
```bash
# Install dependencies
pod install

# Build the SDK
swift build

# Verify setup (see "Testing" section for detailed commands)
swift test
```

## Project Structure

### Source Code Organization

#### Core Modules
- **Sources/Optimizely/**: Main SDK entry point and client implementation
  - `OptimizelyClient.swift`: Primary SDK interface
  - `OptimizelyConfig.swift`: Configuration management
  - `VuidManager.swift`: Visitor unique ID management

- **Sources/Optimizely+Decide/**: Decision-making and user context
  - `OptimizelyUserContext.swift`: User context for decision-making
  - `OptimizelyDecision.swift`: Decision results
  - `OptimizelyDecideOption.swift`: Decision options and flags

- **Sources/Data Model/**: Data structures for experiments, features, and events
  - Core entities: Experiment, FeatureFlag, Variation, Event, Audience
  - CMAB (Contextual Multi-Armed Bandit) models
  - Holdout configurations

- **Sources/Implementation/**: Core business logic
  - `DefaultDecisionService.swift`: Decision-making engine
  - `DefaultBucketer.swift`: User bucketing logic
  - Event handling and batch processing

- **Sources/CMAB/**: Contextual Multi-Armed Bandit implementation
  - `CmabClient.swift`: Client for CMAB predictions
  - `CmabConfig.swift`: Configuration for CMAB
  - `CmabService.swift`: Service layer for CMAB operations

- **Sources/ODP/**: Optimizely Data Platform integration
  - Event and segment management
  - API managers for ODP communication

- **Sources/Customization/**: Extensibility points
  - Protocol definitions for custom handlers
  - Default implementations (logger, event dispatcher, datafile handler)

- **Sources/Utils/**: Shared utilities
  - Atomic properties and thread-safe collections
  - Hashing (MurmurHash3)
  - Network reachability

#### Test Organization
- **Tests/OptimizelyTests-Common/**: Common utility and core functionality tests
- **Tests/OptimizelyTests-APIs/**: Public API tests
- **Tests/OptimizelyTests-Batch/**: Event batching and dispatching tests
- **Tests/OptimizelyTests-DataModel/**: Data model tests
- **Tests/TestData/**: JSON fixture files for test data
- Test naming convention: `{FeatureName}Tests.swift`
- Test data fixtures: Predefined JSON files with sample configurations

## Coding Standards

### Style Guide
We follow the [Ray Wenderlich Swift Style Guide](https://github.com/raywenderlich/swift-style-guide) for readability and consistency.

### Linting
SwiftLint is enforced. Before committing:
```bash
swiftlint
```
Fix all warnings and errors. Configuration in `.swiftlint.yml`.

### Common Patterns

#### Protocol-Oriented Design
The SDK uses protocols for extensibility:
- `OPTLogger`: Custom logging
- `OPTEventDispatcher`: Custom event dispatching
- `OPTDatafileHandler`: Custom datafile management
- `OPTUserProfileService`: Custom user profile persistence

#### Thread Safety
- Use `AtomicProperty`, `AtomicArray`, `AtomicDictionary` for thread-safe state
- All atomic utilities are located in `Sources/Utils/`
- Ensure event dispatchers and managers are thread-safe

#### Error Handling
- Use `OptimizelyError` enum for SDK-specific errors
- Use `OptimizelyResult<T>` for result types
- Handle errors gracefully with meaningful messages

#### Logging
- Use `ThreadSafeLogger` or custom logger implementing `OPTLogger`
- Log levels: debug, info, warning, error
- Use appropriate log levels for different message types

## Testing

### Running Tests

#### Using Swift Package Manager
```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose
```

#### Using Xcode
```bash
# Run all tests for iOS
xcodebuild test \
  -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a specific test target
xcodebuild test \
  -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TestTarget/TestClass

# Run a specific test method
xcodebuild test \
  -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TestTarget/TestClass/testMethodName
```

### Test Targets
- `OptimizelyTests-Common-iOS`: Common utilities and core functionality
- `OptimizelyTests-APIs-iOS`: Public API tests
- `OptimizelyTests-Batch-iOS`: Event batching and dispatching
- `OptimizelyTests-DataModel-iOS`: Data models
- `OptimizelyTests-Legacy-iOS`: Legacy compatibility
- `OptimizelyTests-MultiClients-iOS`: Multi-client scenarios
- `OptimizelyTests-Others-iOS`: Miscellaneous tests
- `OptimizelyTests-iOS`: Main test suite

Similar test targets exist for tvOS and other platforms.

### Testing Best Practices
- All code must have test coverage
- Use XCTest framework
- Use `.sortedKeys` for JSONEncoder in tests to ensure deterministic JSON output
- Override network calls in test mocks to avoid timeouts
- Use JSON fixtures from `Tests/TestData/` for consistent test data
- Each test should use unique file names for persistent storage

## Development Workflow

### Branch Strategy
- Main branch: `master`
- Create feature branches: `YOUR_NAME/branch_name`
- Don't commit on master branch, create new branch before committing any changes

### Making Changes

1. **Create a branch** (see "Helpful Commands > Git Commands")
2. **Make your changes** following coding standards
3. **Write or update tests** (see "Testing" section)
4. **Run linting** (see "Coding Standards > Linting")
5. **Run tests** to verify changes (see "Testing" section)

### Pull Request Process

When creating a pull request, follow this checklist:

1. **Ensure all tests pass** (see "Testing" section)
2. **Run SwiftLint and fix all issues** (see "Coding Standards > Linting")
3. **Verify no merge conflicts with `master`**
   ```bash
   git fetch origin
   git merge origin/master
   ```

4. **Follow the PR template** (located at `pull_request_template.md`)

   Your PR description MUST include:

   **## Summary**
   - Bullet points describing "what" changed (each logical change)
   - Context explaining "why" the changes were made

   **## Test plan**
   - Describe how the changes were tested
   - List specific test cases added or modified
   - Include manual testing steps if applicable

   **## Issues**
   - Reference related issues: "THING-1234" or "Fixes #123"
   - If no issue exists, explain why the change is needed

   Example:
   ```markdown
   ## Summary
   - Fixed flaky tests by replacing asyncAfter with DispatchGroup.wait()
   - Updated MockCmabService to override both sync and async methods

   Recent async retry refactoring introduced timing issues in tests. Tests
   were using unreliable asyncAfter delays instead of proper synchronization.

   ## Test plan
   - Ran EventDispatcherRetryTests suite 20 times, all passed
   - Verified on GitHub CI across multiple Xcode versions
   - Added capturedOptions array to MockCmabService for thread-safe tracking

   ## Issues
   - Fixes #456
   ```

5. **Get review from maintainer**
   - Request review from code owners
   - Address all feedback and comments

6. **Don't update SDK version**
   - Version updates are handled by maintainers during release process

## Key APIs & Usage

### Initialization
Initialize the SDK with an SDK key and start fetching the datafile:
```swift
let optimizely = OptimizelyClient(sdkKey: "YOUR_SDK_KEY")
optimizely.start { result in
    switch result {
    case .success:
        // SDK ready
    case .failure(let error):
        // Handle error
    }
}
```

### Decision Making
Create a user context and make feature flag decisions:
```swift
let user = optimizely.createUserContext(userId: "user123")
let decision = user.decide(key: "feature_key")
if decision.enabled {
    // Feature is enabled
}
```

### Event Tracking
Track custom events for analytics:
```swift
try optimizely.track(eventKey: "purchase", userId: "user123")
```

## Helpful Commands

### Finding Files
```bash
# Find implementation files by pattern
find Sources -name "*ClassName*.swift"

# Find test files by pattern
find Tests -name "*TestName*.swift"

# List all files in a specific module
find Sources/ModuleName -name "*.swift"
```

### Searching Code
```bash
# Find protocol definitions
grep -r "^protocol" Sources/ --include="*.swift"

# Search for specific functions or classes
grep -r "class ClassName" Sources/ --include="*.swift"
grep -r "func functionName" Sources/ --include="*.swift"

# Find TODO or FIXME comments
grep -r "TODO\|FIXME" Sources/ --include="*.swift"
```

### Git Commands
```bash
# Create a new branch
git checkout -b YOUR_NAME/feature-name

# View recent commits
git log --oneline -10

# Check what changed in a specific commit
git show <commit-hash>

# View file changes
git diff <file-path>

# Fetch and merge latest from master
git fetch origin
git merge origin/master
```

### Xcode
```bash
# List available simulators
xcrun simctl list devices available

# List schemes and build targets
xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -list

# Show build settings for a scheme
xcodebuild -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS -showBuildSettings
```
