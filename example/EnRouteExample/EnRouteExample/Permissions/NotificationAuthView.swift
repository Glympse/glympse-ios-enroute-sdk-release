import Foundation
import CoreLocation
import SwiftUI

struct NotificationAuthView: View {
    let showTitle: Bool
    @ObservedObject private var notificationManager = NotificationManager.shared
    var body: some View {
        
        if (showTitle) {
            Text("Notification Permission")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        
        NotificationPermissionStatusItem(title: "Notification Permission", status: notificationManager.authorizationStatus) {
            if (notificationManager.authorizationStatus == .notDetermined) {
                notificationManager.requestAuthorization { success, error in
                    logger.debug("Notification auth request result: \(success)")
                    if let error = error {
                        logger.error("Notification auth request error: \(error)")
                    }
                }
            } else {
                notificationManager.openAppSettings()
            }
        }
    }
}

struct NotificationPermissionStatusItem: View {
    let title: String
    let status: UNAuthorizationStatus
    let onRequestPermission: () -> Void
    private var statusIconName: String {
        if (status == .authorized) {
            return "checkmark.circle.fill"
        } else if (status == .notDetermined) {
            return "questionmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    private var statusText: String {
        if (status == .authorized) {
            return "Granted"
        } else if (status == .notDetermined) {
            return "Not determined"
        } else {
            return "Denied"
        }
    }
    private var statusColor: Color {
        if (status == .authorized) {
            return Color.accentColor
        } else if (status == .notDetermined) {
            return .secondary
        } else {
            return Color.red
        }
    }
    private var requestButtonTitle: String {
        if (status == .notDetermined) {
            return "Request \(title)"
        } else {
            return "Open App Settings"
        }
    }
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Image(systemName: statusIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(statusText)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if (status != .authorized) {
                Button(requestButtonTitle) {
                    onRequestPermission()
                }
                .padding(8)
                .padding([.leading, .trailing], 12)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )

    }
}
