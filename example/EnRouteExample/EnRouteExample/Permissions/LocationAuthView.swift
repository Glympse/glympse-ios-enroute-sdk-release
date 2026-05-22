import Foundation
import SwiftUI
import CoreLocation

struct LocationAuthView: View {
    let showTitle: Bool
    @ObservedObject private var observedLocationAuthManager = LocationAuthManager.shared
    var body: some View {
        if (showTitle) {
            Text("Location Permission")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        
        LocationPermissionStatusItem(title: "Location Permission", status: observedLocationAuthManager.authorizationStatus) {
            if (observedLocationAuthManager.authorizationStatus == .notDetermined || observedLocationAuthManager.authorizationStatus == .authorizedWhenInUse) {
                observedLocationAuthManager.requestBackgroundLocationAuthorization()
            } else if (observedLocationAuthManager.authorizationStatus == .denied || observedLocationAuthManager.authorizationStatus == .restricted) {
                observedLocationAuthManager.openAppSettings()
            }
        }
    }
}

struct LocationPermissionStatusItem: View {
    let title: String
    let status: CLAuthorizationStatus
    let onRequestPermission: () -> Void
    private var statusIconName: String {
        if (status == .authorizedAlways) {
            return "checkmark.circle.fill"
        } else if (status == .notDetermined) {
            return "questionmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    private var statusText: String {
        if (status == .authorizedAlways) {
            return "Background location granted"
        } else if (status == .authorizedWhenInUse ) {
            return "Foreground location granted"
        } else if (status == .notDetermined) {
            return "Not determined"
        } else {
            return "Denied"
        }
    }
    private var statusColor: Color {
        if (status == .authorizedAlways) {
            return Color.accentColor
        } else if (status == .authorizedWhenInUse || status == .notDetermined) {
            return .secondary
        } else {
            return Color.red
        }
    }
    private var requestButtonTitle: String {
        if (status == .notDetermined ) {
            return "Request Foreground location"
        } else if (status == .authorizedWhenInUse) {
            return "Request Background location"
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
            
            if (status != .authorizedAlways) {
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
