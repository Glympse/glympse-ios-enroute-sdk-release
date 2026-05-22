import SwiftUI

struct LoggedInView: View {
    @State private var showOrgInfo = false
    @State private var showAgentInfo = false
    @State private var showPermissionsView = false
    @State private var showLogsView = false
    @State private var selectedTask: TaskWrapper? = nil
    
    private var isTaskSelected: Binding<Bool> {
        Binding<Bool>(
            get: { self.selectedTask != nil },
            set: { _ in }
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                PermissionsCheckView(showPermissionsView: $showPermissionsView)
                TasksView(selectedTask: $selectedTask)
                    .contentBackground()
            }
            .navigationDestination(isPresented: $showPermissionsView) {
                PermissionsView()
                    .onDisappear {
                        showPermissionsView = false
                    }
                    .contentBackground()
                    .navigationTitle("Permissions")
            }
            .navigationDestination(isPresented: $showOrgInfo) {
                OrgInfoView()
                    .contentBackground()
                    .navigationTitle("Organization")
            }
            .navigationDestination(isPresented: $showAgentInfo) {
                AgentInfoView()
                    .contentBackground()
                    .navigationTitle("Agent")
            }
            .navigationDestination(isPresented: isTaskSelected) {
                TaskDetailsView(task: selectedTask)
                    .onDisappear {
                        selectedTask = nil
                    }
                    .contentBackground()
                    .navigationTitle("Task Details")
                
            }
            .navigationDestination(isPresented: $showLogsView) {
                LogsView()
                    .onDisappear {
                        showLogsView = false
                    }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        withAnimation {
                            showOrgInfo = true
                        }
                    }) {
                        Text("Org Info")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        withAnimation {
                            showAgentInfo = true
                        }
                    }) {
                        Text("Agent Info")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showLogsView = true
                        }
                    }) {
                        Image(systemName: "text.page.badge.magnifyingglass")
                    }
                }
            }
        }
    }
}

struct ContentBackgroundView: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func contentBackground() -> some View {
        self.modifier(ContentBackgroundView())
    }
}
