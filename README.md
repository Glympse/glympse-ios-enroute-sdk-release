# glympse-ios-enroute-sdk-release
Repository is used to host the iOS En Route SDK dependency

These releases are distributed with Swift Package Manager. Release binaries are attached to this repository's
[GitHub releases](https://github.com/Glympse/glympse-ios-enroute-sdk-release/releases).

## Integration guide

A step-by-step integration guide for the En Route SDK on iOS is in [`integration/`](integration/). It is written to be
read by developers and by AI coding agents.

- [`integration/AGENTS.md`](integration/AGENTS.md): installation (Swift Package Manager product `EnRouteApi`),
  capabilities and Info.plist requirements, the exact start-up call order, authentication, lifecycle and threading rules,
  the main task flows, push notifications and common pitfalls.
- [`integration/llms-full.txt`](integration/llms-full.txt): a reference outline of the API (managers, events, constants
  and models).

To have your coding agent use the guide, copy both files into the root of your app's repository (keep them together, as
`AGENTS.md` refers to `llms-full.txt`). A working reference app is in [`example/EnRouteExample`](example/EnRouteExample).

## Usage (Swift Package Manager)

### Xcode

1. In your project choose File > Add Package Dependencies.
2. Enter the package URL `https://github.com/Glympse/glympse-ios-enroute-sdk-release`.
3. Choose the dependency rule "Up to Next Major Version" starting from the latest release (see the
   [releases page](https://github.com/Glympse/glympse-ios-enroute-sdk-release/releases)).
4. Add the `EnRouteApi` product to your app target.
5. In your Swift files `import GlympseKit` and `import EnRouteApi`.

### Package.swift

If your app or library is itself a Swift package, add the dependency and the product to your target:

```swift
dependencies: [
    .package(url: "https://github.com/Glympse/glympse-ios-enroute-sdk-release", from: "<latest release>")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "EnRouteApi", package: "glympse-ios-enroute-sdk-release")
        ]
    )
]
```

The package declares iOS 12 as its minimum deployment target. The `EnRouteApi` product also brings in the GlympseKit framework.

See https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app for Apple's instructions on
adding, updating and removing package dependencies.
