import Foundation
import CoreLocation
import SwiftUI
import Combine
import EnRouteApi
import GlympseKit

let enrouteWrapper = EnRouteWrapper()

class EnRouteWrapper: ObservableObject {
    private(set) var enroute: GlyEnRouteManager?
    private var isForeground = false

    func initAndStart() {
        // A started manager is reused. A stopped one (after logout) cannot be restarted, so it is replaced.
        if enroute?.isStarted() == true {
            return
        }
        enroute = GlyEnRouteFactory.createEnRouteManager()
        #if DEBUG
        enroute?.overrideLoggingLevels(1, debugLogLevel: 1)
        #endif
        enroute?.setAuthenticationMode(GlyEnRouteConstants.auth_MODE_CREDENTIALS())
        enroute?.add(EventListener.shared)
        enroute?.start()
        // setActive is reference counted and a new manager starts at zero, so mirror the current app state.
        if isForeground {
            enroute?.setActive(true)
        }
    }

    // Call on foreground/background transitions only. Each true must be paired with one false.
    func setForeground(_ foreground: Bool) {
        if foreground == isForeground {
            return
        }
        isForeground = foreground
        enroute?.setActive(foreground)
    }
    
    func loginWithCredentials(username: String, password: String) {
        if (enroute?.isStarted() != true) {
            initAndStart()
        }
        enroute?.login(withCredentials: username, password: password)
    }
    
    func loginWithToken(token: String, expiresIn: Int) {
        if (enroute?.isStarted() != true) {
            initAndStart()
        }
        // expiresIn is seconds from now. The SDK expects an absolute epoch time in milliseconds.
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let expireTimeMs = nowMs + Int64(expiresIn) * 1000
        enroute?.login(withToken: token, expireTime: expireTimeMs)
    }
}

