import SwiftUI
import CoreLocation

struct PermissionsCheckView: View {
    @Binding var showPermissionsView: Bool
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var locationAuthManager = LocationAuthManager.shared
    
    var body: some View {
        if (notificationManager.authorizationStatus != .authorized || locationAuthManager.authorizationStatus != .authorizedAlways) {
            Button("Required permissions are missing. Tap to configure.") {
                showPermissionsView = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
