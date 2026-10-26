# Glympse En Route SDK: iOS integration guide for coding agents

Use this when adding the En Route SDK to an iOS app (Swift or Objective-C). The API is in two modules; import both:
`import EnRouteApi` (En Route managers and models, plus `GlyListener` and `GlySource`) and `import GlympseKit`
(primitives, `GlyCommon`, core types). All types carry a `Gly` prefix. Swift sees the ObjC API: `getX()` stays a method, constants are class functions.
Full API outline (managers, events, constants, models): `llms-full.txt`.
Reference app: `example/EnRouteExample` in https://github.com/Glympse/glympse-ios-enroute-sdk-release. See
`EnRouteWrapper.swift` (manager lifecycle), `EventListener.swift` (events), `Permissions/` (location and notification
authorization, APNs token and payload handling), `TasksView.swift` (task actions), Info.plist and the entitlements.

## 1. Install (Swift Package Manager)

Xcode: File > Add Package Dependencies, URL `https://github.com/Glympse/glympse-ios-enroute-sdk-release`, rule
"Up to Next Major" from the latest release, add the `EnRouteApi` product to your app target. That one product also
pulls in `GlympseKit`. The package declares iOS 12 as its minimum; check it against your deployment target.
The release repo's README also lists a CocoaPods pod named `EnRouteApi`.

Without the Xcode GUI (scripts, agents): find the latest release with
`git ls-remote --tags https://github.com/Glympse/glympse-ios-enroute-sdk-release | grep -v '\^{}' | sed 's#.*/##' | sort -V | tail -1`
(for example 2.111.309; do not sort tags by date). In a `Package.swift` use
`.package(url: "https://github.com/Glympse/glympse-ios-enroute-sdk-release", from: "2.111.309")` and the product
`.product(name: "EnRouteApi", package: "glympse-ios-enroute-sdk-release")`. In a hand-written `project.pbxproj` add an
`XCRemoteSwiftPackageReference` (`kind = upToNextMajorVersion`, `minimumVersion = 2.111.309`) plus an
`XCSwiftPackageProductDependency` with `productName = EnRouteApi`, and set the target's build settings
`INFOPLIST_FILE` (for the keys in section 2) and `CODE_SIGN_ENTITLEMENTS`.
Building prints many `warning: ... unable to open object file` linker warnings from the SDK's debug info. They are
harmless.

## 2. Requirements and capabilities

- Info.plist: `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` (user-facing
  reason, for example "Used to share location when a Task is active").
- Background Modes: `location` and `remote-notification`.
- Capability Push Notifications (entitlement `aps-environment`: `development` for debug, `production` for release).
- Location: ask for When In Use, then Always (iOS shows the Always prompt only once, so track that you asked).
  Request this BEFORE login. If status is still undetermined when the SDK starts its platform (after login), the SDK
  prompts itself: Always only if `NSLocationAlwaysUsageDescription` exists, else When In Use if that key exists.
- Notifications: `UNUserNotificationCenter.requestAuthorization`, and when granted call
  `UIApplication.shared.registerForRemoteNotifications()`. Call it on every launch while authorized so the APNs token stays fresh.

## 3. Init and auth: exact call order

Create ONE manager per process (a global or app-scoped object) on the main thread.
```swift
let m = GlyEnRouteFactory.createEnRouteManager()                     // 1. create
m.setAuthenticationMode(GlyEnRouteConstants.auth_MODE_CREDENTIALS()) // 2. MUST precede start(); or auth_MODE_TOKEN
//   Also before start(): setBaseUrl (only if you are testing in Sandbox), getTaskManager().setFetchCompletedTasks,
//   setSessionsGeofencesEnabled, setIncludeRootFields
m.add(listener)                                                      // 3. GlyListener (EnRouteApi)
m.start()                                                            // 4. false if mode unset and login is needed
// 5. wait for STARTED. No stored login: AUTHENTICATION_NEEDED fires (either mode), show login UI. Else it resumes
//    (STARTED then SYNCED, no auth event)
m.login(withCredentials: user, password: pass)                       // 6a. credentials mode, only after start()
m.login(withToken: token, expireTime: expiryEpochMs)                 // 6b. token mode: ABSOLUTE epoch ms, >= 1 hour ahead
m.setActive(true)                                                    // 7. once per foreground transition (see §4)
```
- Mismatched mode/login method, login before `start()`, or a second login without logout returns `false` and only
  logs a warning. Check the return value.
- `LOGIN_COMPLETED` is emitted only for successful logins. Credentials mode: fires at login success, before the
  profile loads. Token mode: fires after org and agent load. Failures come through `LOGGED_OUT`.
- Readiness: `ENROUTE_MANAGER_SYNCED` means the organization and agent profiles have synced: `getOrganization()` and
  `getSelfAgent()` are populated from then on. It does NOT mean tasks are loaded: `getTasks()` is empty at `SYNCED`.
  The initial task list arrives with `TASKS_TASK_LIST_CHANGED`. Add the task-manager listener when `SYNCED` fires and
  re-read `getTasks()` on every `TASKS_TASK_LIST_CHANGED`, including the first. Show a loading state until then, not "no tasks".
- Login failure: `LOGGED_OUT` with `param1` (`GlyLong`, read `longValue()`) == `logout_REASON_INVALID_CREDENTIALS()`.
- Logout reasons actually emitted: `USER_ACTION`, `INVALID_CREDENTIALS`, `INVALID_TOKEN`, `OLD_VERSION`,
  `SERVER_ERROR`. `OLD_VERSION` means the SDK build is older than the org's minimum: upgrade the SDK.
- `INVALID_TOKEN` fires when: credentials mode finds the stored token expired or invalid; token mode fails before its
  first sync; or the agent profile fails to load or belongs to a different agent.
- Token mode, after sync: an expired or invalid token pauses the SDK (including location sharing) and fires
  `AUTHENTICATION_NEEDED`. Fetch a fresh token and call `login(withToken:expireTime:)`; queued calls are retried.
- `stop()` keeps the stored login, so the next launch resumes. `logout(reason)` clears it. Both end in `STOPPED`;
  `LOGGED_OUT` also precedes it for `logout`. After `STOPPED` the instance is dead, its sub-managers are released
  and all listeners are dropped. Create a new manager and repeat steps 1-6 to log in again.

## 4. Lifecycle, threading, state

- `setActive(true/false)` is reference counted and must be reciprocal: one `true` when the app becomes active, one
  `false` when it goes to the background (`scenePhase` `.active` / `.background`, or the UIKit equivalents). An extra
  `true` (for example right after `start()`) keeps the platform active forever.
- Never recreate the manager when a view appears (`onAppear` can run repeatedly). Guard creation with
  `if manager?.isStarted() == true { return }`. A stopped manager (after logout) must be replaced, and the new one
  starts with an active count of 0: call `setActive(true)` on it if the app is currently in the foreground.
- Track foreground state in your wrapper and call `setActive` only on real transitions, so calls stay paired.
  SwiftUI's `onChange(of: scenePhase)` does not fire for the starting value, so pass `initial: true` or the first
  foreground is never reported. That `onChange(of:initial:)` form needs iOS 17; for a lower deployment target observe
  `UIApplication.didBecomeActiveNotification` / `didEnterBackgroundNotification` instead.
- The SDK posts its work to the thread that created the manager, so create it on the main thread (it needs a run
  loop). Keep callbacks short and hop to `DispatchQueue.main` before touching `@Published` or UI state.
- `eventsOccurred(_:listener:events:param1:param2:)`: `events` is a bitmask and several bits can arrive in one call.
  Test each with `events & GlyEnRouteEvents.x() != 0`, dispatch on `listener` first (`listener_ENROUTE_MANAGER`,
  `listener_TASKS`, `listener_AGENTS`, `listener_SESSIONS`, `listener_PICKUPS`). Params are `GlyCommon` (cast per
  `llms-full.txt`). All constants are `Int32`, so no casts are needed for the tests. Exact Swift signature:
  ```swift
  final class EventListener: NSObject, GlyListener {
      func eventsOccurred(_ source: GlySource, listener: Int32, events: Int32, param1: GlyCommon?, param2: GlyCommon?) {
          DispatchQueue.main.async { /* switch listener { case GlyEnRouteEvents.listener_TASKS(): ... } */ }
      }
  }
  ```
  Register the same listener object on the manager and on each sub-manager you use; it receives all of them.
- Getter types you will hit: `getId()` is `Int64` on `GlyTask`, `GlyOrganization` and `GlyAgent` (convert with
  `String(...)` for display); `GlyAgent.getRoles()` is `GlyArray<NSString>` (cast elements with `as String`);
  `GlyOperation.getTaskId()` is `Int64`. A plain `for i in 0..<arr.count()` with `arr.object(at: i)` works.
- Model objects (`GlyTask`, `GlyOperation`, ...) are mutable and keep identity when they change. Copy the fields you
  display into a value type on every update (`TASKS_TASK_LIST_CHANGED`, `TASKS_TASK_PHASE_CHANGED`), or SwiftUI will
  not see phase changes.
- Each sub-manager (`getTaskManager()`, `getSessionManager()`, `getPickupManager()`, `getAgentManager()`) has its own
  `add(listener)`. `GlyArray` is read with `count()` and `object(at:)` / subscript.

## 5. Main flows

Tasks (constants are functions: `GlyEnRouteConstants.phase_PROPERTY_LIVE()`):
1. After `SYNCED`: `getTaskManager().add(l)`; the list is read with `getTasks()` (also `getPendingTasks()`,
   `getActiveOperations()`, `findTask(byId:)`) and is empty until the first `TASKS_TASK_LIST_CHANGED`. Re-read on every
   `TASKS_TASK_LIST_CHANGED`. `getTasks()` holds the logged-in agent's tasks. By default completed tasks
   are not fetched (`setFetchCompletedTasks(false)`), so a completed task is gone from the list after the next launch;
   call `setFetchCompletedTasks(true)` before `start()` to keep them (state `task_STATE_COMPLETED()`).
2. Start: `startTask(with: task)`. It returns `false` unless `task.getState() == task_STATE_CREATED()`, the task has
   no operation yet, and the org profile is loaded. Then wait for `TASKS_TASK_STARTED` or `TASKS_TASK_START_FAILED`.
   After `TASK_STARTED` the state is `task_STATE_STARTED()`. The task's phase is populated by the update that
   follows the start, delivered by push (or by `refresh()` when push is not available). Until it arrives `getPhase()`
   reads `phase_PROPERTY_UNKNOWN()` (`"unknown"`). Started is not live: offer Go Live whenever
   `getPhase() != phase_PROPERTY_LIVE()`.
3. Move phase: `setTaskPhase(task, phase: GlyEnRouteConstants.phase_PROPERTY_LIVE())`, then `phase_PROPERTY_ARRIVED()`.
   The change is confirmed by `TASKS_TASK_PHASE_CHANGED`. Start the task first: `setTaskPhase` does not reject a task
   that was never started (it changes the local phase only, and the server still has the task as not started).
4. Finish: `completeOperation(with: task.getOperation())` (or the overload with a `TASK_COMPLETE_REASON_*` code).
   `getOperation()` is nil until a task has started, so unwrap it. Result events: `TASKS_OPERATION_COMPLETED` /
   `TASKS_OPERATION_COMPLETION_FAILED`. ARRIVED is a separate step; `completeOperation` can be called from LIVE. See "Data freshness"
   below: the local task can still read STARTED / `live` after `OPERATION_COMPLETED`.
5. Other: `createTask(_:startAfterCreate:)` (returns `false` unless the self agent has the `manager` or `admin` role),
   `addOrUpdateMetadataItem`, `sendMessage`, `setTravelModeForTask`.
6. Metadata: `task.getMetadata()` is a `GlyArray` of `GlyPrimitive` entries. In each, `getStringWith("n")` is the field
   name and `getWith("v")` is its value (a `GlyPrimitive`; check `type()` against `GlyCoreConstants.primitive_TYPE_*()`).

Phase names and which transitions are valid come from the org: read `getOrganization().getConfig()`
(`getInitialPhase`, `getInitialTrackingPhase`, `getArrivalPhase`, `getFinalPhase`, `getCompletionPhases`,
`getPickerDisabledTaskPhases`) rather than hard-coding a state machine.

Profile: `getOrganization()` (`getName`, `getConfig`), `getSelfAgent()` (`getDisplayName`, `getRoles`).
Sessions and pickups use the same pattern; see `llms-full.txt`. Sessions only start when `getConfig().isSessionModeEnabled()`,
so check it before showing session UI.

Data freshness: the server changes phases and completes operations too (push, geofence, arrival), so do not assume
only your own calls move a task. In normal use the server sends a push that tells the SDK to refresh, which is what
brings the local task list up to date after a completion. Without push (simulator, no APNs credentials, push not yet
set up) data refreshes through the org's auto-refresh setting (only while active), otherwise call `refresh()` on the
managers. `refresh()` does nothing before the profile has loaded. Without push the local task model is not updated
after a completion or phase change on its own: after `TASKS_OPERATION_COMPLETED` the task still reads state STARTED
and phase `live`, and no `TASKS_TASK_LIST_CHANGED` follows, until the next refresh or launch. Without push, call
`refresh()` after completing and after phase changes, and/or update your row from the event itself: on
`TASKS_OPERATION_COMPLETED`, `param1` is a `GlyOperation` and `getTaskId()` identifies the task to show as completed.

Push (needed for timely updates when backgrounded). Glympse must be given your app's APNs credentials first: contact
your Glympse representative. Then, after the APNs callback, convert the token `Data` to a lowercase hex string and
call `m.registerDeviceToken("apple_background", deviceToken: hex)`. The SDK stores tokens and registers
them once logged in, so you may call it as soon as the manager exists; hold the token yourself if it can arrive before
the manager is created. In `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` pass
`userInfo["payload"] as? String` to `m.handleRemoteNotification(_:)`, then call the completion handler.
`handleRemoteNotification` is ignored until the manager has started and logged in.

## 6. Pitfalls

- `login(withToken:expireTime:)` takes epoch milliseconds, at least one hour in the future. Seconds or a short expiry
  makes it return `false`.
- Permission timing: the system prompts are separate. Ask When In Use first, Always on a later action; once denied or
  already asked, send the user to `UIApplication.openSettingsURLString`. Re-read the status when the app returns active.
- `STARTED` fires even when no login exists; pick the login-vs-main screen from `AUTHENTICATION_NEEDED` or
  `isLoginNeeded()`, not from `STARTED` alone.
- Debug logging (`overrideLoggingLevels(_:debugLogLevel:)`) is for development; wrap it in `#if DEBUG`.
- `ENROUTE_MANAGER_SHOW_NOTIFICATION` carries a notification (`param1`: `GlyPrimitive`) for the host to display.
- A UI that shows "no tasks" before the first `TASKS_TASK_LIST_CHANGED`, or settings blanks before `SYNCED`, is a
  loading state, not an empty state.
- `createTask` takes a `GlyPrimitive` payload whose schema is not covered here; ask your Glympse representative for
  it, or have whoever administers your test organization assign tasks to your test agent.

## 7. Testing against Sandbox

- Point the SDK at Sandbox with `m.setBaseUrl("s-api.enterprise.glympse.com")` before `start()`. Pass a bare host
  (no `https://`). Wrap it in `#if DEBUG` or a launch-environment switch.
- You need a Sandbox organization and agent (username and password): ask your Glympse representative. A manager agent
  has roles `agent, manager`.
- Each task can be started and completed once, so assign several test tasks to the agent before a run.
- Event order on a stored login: relaunch gives `STARTED`, then `SYNCED`, then `TASKS_TASK_LIST_CHANGED`, with no
  `AUTHENTICATION_NEEDED`. `logout(USER_ACTION)` gives `LOGGED_OUT` then `STOPPED`; a new manager then gives `STARTED`,
  `AUTHENTICATION_NEEDED`, and a credentials login works again.
