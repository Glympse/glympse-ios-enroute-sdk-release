import Foundation
import CoreLocation
import SwiftUI
import Combine
import EnRouteApi
import GlympseKit

let enrouteWrapper = EnRouteWrapper()

class EnRouteWrapper: ObservableObject {
    private(set) var enroute: GlyEnRouteManager?
    
    func initAndStart() {
        enroute = GlyEnRouteFactory.createEnRouteManager()
        #if DEBUG
        enroute?.overrideLoggingLevels(1, debugLogLevel: 1)
        #endif
        enroute?.setAuthenticationMode(GlyEnRouteConstants.auth_MODE_CREDENTIALS())
        enroute?.add(EventListener.shared)
        enroute?.start()
        enroute?.setActive(true)
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
        let now = Int(Date().timeIntervalSince1970)
        let expireTime = now + expiresIn
        enroute?.login(withToken: token, expireTime: Int64(expireTime))
    }
}

