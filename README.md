# glympse-ios-enroute-sdk-release
Repository is used to host the iOS En Route SDK dependency

These releases are accessible using CocoaPods https://cocoapods.org/

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

## Usage

In your project's podfile add the EnRouteApi pod

```
target 'YourApp' do
  pod 'EnRouteApi'
  ...
end
```

See https://guides.cocoapods.org/using/using-cocoapods.html for the latest instructions on how to install and update pods
