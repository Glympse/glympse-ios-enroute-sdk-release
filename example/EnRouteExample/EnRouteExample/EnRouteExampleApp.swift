import SwiftUI
import EnRouteApi

@main
struct EnRouteExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    enrouteWrapper.initAndStart()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        if newPhase == .active {
            enrouteWrapper.enroute?.setActive(true)
            NotificationManager.shared.updateAuthorizationStatus()
        } else if (newPhase == .background) {
            enrouteWrapper.enroute?.setActive(false)
        }
    }
}
