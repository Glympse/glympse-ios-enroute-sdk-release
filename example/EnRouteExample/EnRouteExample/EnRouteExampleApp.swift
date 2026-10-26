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
                // initial: true so the first foreground is reported, onChange does not fire for the starting value
                .onChange(of: scenePhase, initial: true) { oldPhase, newPhase in
                    handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        if newPhase == .active {
            enrouteWrapper.setForeground(true)
            NotificationManager.shared.updateAuthorizationStatus()
        } else if (newPhase == .background) {
            enrouteWrapper.setForeground(false)
        }
    }
}
