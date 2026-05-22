import SwiftUI

struct PermissionsView: View {
    var body: some View {
        ScrollView(.vertical) {
            NotificationAuthView(showTitle: true)
            LocationAuthView(showTitle: true)
        }
        .padding(.horizontal)
    }
}
