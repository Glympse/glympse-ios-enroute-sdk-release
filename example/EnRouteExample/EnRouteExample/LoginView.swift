import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @ObservedObject var eventListener = EventListener.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 50)

                Text("En Route Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.top, 10)

                Spacer()

                if showError {
                    Text("Invalid credentials")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 10)
                }
            }
            .padding()
            .navigationTitle("Login")
            .onChange(of: eventListener.isLoginFailure) { wasFailed, isFailed in
                if (!wasFailed && isFailed) {
                    self.showError = isFailed
                    isLoading = false
                }
            }
        }
    }

    private func handleLogin() {
        isLoading = true
        showError = false

        enrouteWrapper.loginWithCredentials(username: username, password: password)
    }
}
