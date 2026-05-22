import SwiftUI

struct ContentView: View {
    @ObservedObject private var eventListener: EventListener = EventListener.shared
    var body: some View {
        if (!eventListener.isLoggedIn) {
            LoginView()
        } else {
            LoggedInView()
        }
    }
}
