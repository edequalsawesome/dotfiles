---
name: ios-share-extension-javascriptcore
description: |
  Build iOS Share Extensions that run JavaScript code via JavaScriptCore. Use when:
  (1) Porting a browser extension to iOS, (2) Need to reuse existing JS code in Swift,
  (3) Building a share sheet action that processes web content. Covers JSExport protocol,
  App Groups for data sharing, Share Extension constraints (120MB memory, can't open URLs,
  30s timeout), and XcodeGen for multi-target projects.
author: Claude Code
version: 1.1.0
date: 2026-02-14
---

# iOS Share Extension with JavaScriptCore

## Problem

You need to port a browser extension (or any JS-based web tool) to iOS as a Share Extension,
reusing existing JavaScript code rather than rewriting everything in Swift.

## Context / Trigger Conditions

- Porting a Chrome/Firefox/Safari extension to iOS
- Want to reuse complex JS logic (template engines, parsers, converters)
- Building a "Share to X" feature that processes URLs or web content
- Need to run JavaScript in a native iOS context

## Solution

### Architecture Overview

```
┌─────────────────────────────────────────┐
│           Main App (Host)               │
│  - Settings UI                          │
│  - Opens URLs (extensions can't)        │
│  - Receives queued actions from ext     │
└─────────────────────────────────────────┘
                    │
          App Group Storage
    (group.com.yourcompany.appname)
                    │
┌─────────────────────────────────────────┐
│         Share Extension                 │
│  - Receives shared content              │
│  - Runs JS via JavaScriptCore           │
│  - Queues results for main app          │
└─────────────────────────────────────────┘
```

### Critical Constraints

| Constraint | Limit | Workaround |
|------------|-------|------------|
| Memory | 120MB max | Process in chunks, avoid large strings |
| URL opening | Can't call `UIApplication.shared.open()` | Queue to main app via App Group |
| Execution time | ~30 seconds | Defer long operations to background URLSession |
| Direct app communication | Not possible | Use App Groups (UserDefaults or file container) |

### JavaScriptCore Bridge Pattern

```swift
import JavaScriptCore

// 1. Create context and load JS
let context = JSContext()!

context.exceptionHandler = { _, exception in
    print("JS Error: \(exception?.toString() ?? "unknown")")
}

// Load bundled JS
if let url = Bundle.main.url(forResource: "bundle", withExtension: "js"),
   let script = try? String(contentsOf: url) {
    context.evaluateScript(script)
}

// 2. Pass data safely (avoid injection)
// BAD: context.evaluateScript("process('\(userInput)')")
// GOOD:
context.setObject(userInput, forKeyedSubscript: "inputData" as NSString)
let result = context.evaluateScript("process(inputData)")

// 3. Get results back
if let dict = result?.toDictionary() as? [String: Any] {
    // Use the data
}
```

### JSExport for Swift ↔ JS Bridging

```swift
// Protocol must use @objc and inherit JSExport
@objc protocol BridgeExport: JSExport {
    func log(_ message: String)
    func fetchURL(_ url: String) -> String?
}

// Implementation must inherit NSObject
@objc class Bridge: NSObject, BridgeExport {
    func log(_ message: String) {
        print("[JS] \(message)")
    }

    func fetchURL(_ url: String) -> String? {
        // Synchronous fetch (not ideal but sometimes necessary)
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?

        URLSession.shared.dataTask(with: URL(string: url)!) { data, _, _ in
            result = data.flatMap { String(data: $0, encoding: .utf8) }
            semaphore.signal()
        }.resume()

        semaphore.wait(timeout: .now() + 10)
        return result
    }
}

// Register with context
context.setObject(Bridge(), forKeyedSubscript: "bridge" as NSString)
```

### App Groups for Data Sharing

```swift
// 1. Add App Groups capability to BOTH targets in Xcode
// 2. Use same identifier: "group.com.yourcompany.appname"

// Shared UserDefaults
let defaults = UserDefaults(suiteName: "group.com.yourcompany.appname")!
defaults.set(data, forKey: "pendingAction")
defaults.synchronize() // Force write in extension

// Shared file container
let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.yourcompany.appname"
)
```

### Share Extension Info.plist

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
        </dict>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
</dict>
```

### XcodeGen for Multi-Target Projects

```yaml
# project.yml
name: MyApp
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    iOS: "16.0"

targets:
  MyApp:
    type: application
    platform: iOS
    sources: [MyApp, Shared]
    dependencies:
      - target: ShareExtension
    entitlements:
      path: MyApp/MyApp.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.yourcompany.myapp

  ShareExtension:
    type: app-extension
    platform: iOS
    sources: [ShareExtension, Shared]
    settings:
      SKIP_INSTALL: YES
    entitlements:
      path: ShareExtension/ShareExtension.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.yourcompany.myapp
```

Generate with: `xcodegen generate`

### Receiving Shared URLs

```swift
// In ShareViewController
static func extractURL(from extensionContext: NSExtensionContext?) async -> URL? {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
        return nil
    }

    for item in items {
        for attachment in item.attachments ?? [] {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let item = try? await attachment.loadItem(
                    forTypeIdentifier: UTType.url.identifier
                )
                if let url = item as? URL {
                    return url
                }
            }
        }
    }
    return nil
}
```

## Verification

1. Extension appears in iOS share sheet
2. JS code executes and returns expected results
3. Data passes correctly between extension and main app via App Group
4. Main app successfully opens external URLs queued by extension

## Example

See complete implementation: `~/Development/JiggyClipper/`

This project ports the Obsidian Web Clipper browser extension to iOS:
- Share Extension receives URLs from Safari
- JavaScriptCore runs the clipper's template engine and HTML→Markdown converter
- Results queue to main app which opens Obsidian via URL scheme

## Notes

- **DOM APIs unavailable**: JavaScriptCore has no `document`, `window`, or DOM. You'll need
  to stub or replace code that uses these (e.g., DOMParser, document.querySelector).

- **Synchronous JS calls**: JSC runs synchronously. For async operations, use Swift's
  URLSession and pass results back through the bridge.

- **Bundle size**: Large JS bundles increase app size. Consider tree-shaking or lazy loading
  if bundle exceeds ~500KB.

- **Testing**: Can't use xcodebuild without full Xcode installed. Use `xcode-select -s` to
  point to Xcode.app if you have both Command Line Tools and Xcode.

- **Memory pressure**: Test on real devices. Simulator doesn't enforce the 120MB limit.

- **Can't open other apps**: Share Extensions cannot call `UIApplication.shared.open()` or
  use `extensionContext?.open()` to open other apps like Obsidian. The URL opening constraint
  means queuing to main app via App Group, then main app opens the URL. Workarounds using
  responder chain don't work because SwiftUI Views aren't UIResponders.

- **Safari JS preprocessing**: Add `NSExtensionJavaScriptPreprocessingFile` to Info.plist
  to run JavaScript in Safari's actual page context. This gives access to authenticated/
  paywalled content and the real DOM (unlike URLSession which fetches unauthenticated HTML).
  The JS must define `ExtensionPreprocessingJS` with `run(arguments)` and `finalize()` methods.

- **Security-scoped bookmarks**: To write directly to user-selected folders (like an Obsidian
  vault), use `URL.bookmarkData(options: .minimalBookmark)` when user picks folder, store
  the bookmark in App Group, then call `url.startAccessingSecurityScopedResource()` before
  file operations. This persists folder access across app launches.

- **ISO8601DateFormatter returns UTC**: When generating dates for templates, use local
  `DateFormatter` with timezone set to `.current` instead of `ISO8601DateFormatter()`.

See also: health-md app for security-scoped bookmark example.

## References

- [Apple: App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
- [JavaScriptCore Framework](https://developer.apple.com/documentation/javascriptcore)
- [JSExport Protocol](https://developer.apple.com/documentation/javascriptcore/jsexport)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
