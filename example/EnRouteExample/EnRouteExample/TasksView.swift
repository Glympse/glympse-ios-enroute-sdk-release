import SwiftUI
import EnRouteApi

struct TasksView: View {
    @Binding var selectedTask: TaskWrapper?
    @ObservedObject var eventListener: EventListener = EventListener.shared
    var body: some View {
        if let tasks = eventListener.tasks, !tasks.isEmpty {
            List {
                Section(header: Text("Tasks")) {
                    ForEach(tasks.indices, id: \.self) { index in
                        TaskItem(
                            task: tasks[index])
                        .onTapGesture {
                            selectedTask = tasks[index]
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else if (eventListener.areTasksSynced) {
            Text("No Tasks to Display")
                .font(.title2)
        } else {
            ProgressView()
                .tint(.primary)

        }
    }
}

struct TaskItem: View {
    let task: TaskWrapper
    @State private var showingTaskActions = false
    @State private var taskActions: [ActionItem] = []
    @State private var confirmCompletedTask: TaskWrapper? = nil
    
    private var showCompleteTaskDialog: Binding<Bool> {
        Binding<Bool>(
            get: { self.confirmCompletedTask != nil },
            set: { _ in }
        )
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Text(task.task.getDescription() ?? "No Description")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(task.task.getPhase() ?? "")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )

                    if !self.taskActions.isEmpty {
                        Button(action: { showingTaskActions = true }) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Select an Action", isPresented: $showingTaskActions, titleVisibility: .visible) {
                            ForEach(taskActions) { action in
                                Button(action.title) {
                                    if (action.action == TaskAction.complete) {
                                        confirmCompletedTask = task
                                    } else {
                                        action.handler()
                                    }
                                }
                                .foregroundStyle(action.isDestructive ? .red : .primary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        .onAppear() {
            self.taskActions = getTaskActions(task)
        }
        .onChange(of: task.phase) {
            self.taskActions = getTaskActions(task)
        }
        .confirmationDialog("Are you sure you want to complete this Task?", isPresented: showCompleteTaskDialog, titleVisibility: .visible) {
            Button("Complete Task") {
                if let operation = confirmCompletedTask?.task.getOperation() {
                    enrouteWrapper.enroute?.getTaskManager()?.completeOperation(with: operation)
                }
                confirmCompletedTask = nil
            }
            Button("Cancel") {
                confirmCompletedTask = nil
            }
        }
    }
}

private enum TaskAction {
    case start
    case live
    case arrive
    case pause
    case complete
}

private struct ActionItem: Identifiable {
    let id = UUID()
    let action: TaskAction
    let title: String
    let isDestructive: Bool
    let handler: () -> Void
}

private func getTaskActions(_ task: TaskWrapper) -> [ActionItem] {
    var actions: [ActionItem] = []
        
    switch task.task.getPhase() {
        case GlyEnRouteConstants.phase_PROPERTY_NEW(),
             GlyEnRouteConstants.phase_PROPERTY_UNKNOWN():
            actions.append(ActionItem(
                action: .start,
                title: "Start Task",
                isDestructive: false
            ) {
                enrouteWrapper.enroute?.getTaskManager()?.startTask(with: task.task)
            })
            
        case GlyEnRouteConstants.phase_PROPERTY_PRE(),
             GlyEnRouteConstants.phase_PROPERTY_ETA(),
             GlyEnRouteConstants.phase_PROPERTY_SCHEDULED(),
             GlyEnRouteConstants.phase_PROPERTY_QUASI(),
             GlyEnRouteConstants.phase_PROPERTY_READY(),
             GlyEnRouteConstants.phase_PROPERTY_NOT_COMPLETED():
            actions.append(ActionItem(
                action: .live,
                title: "Start Tracking",
                isDestructive: false
            ) {
                enrouteWrapper.enroute?.getTaskManager()?.setTaskPhase(task.task, phase: GlyEnRouteConstants.phase_PROPERTY_LIVE())
            })
            
        case GlyEnRouteConstants.phase_PROPERTY_LIVE():
            actions.append(ActionItem(
                action: .arrive,
                title: "Mark Arrived",
                isDestructive: false
            ) {
                enrouteWrapper.enroute?.getTaskManager()?.setTaskPhase(task.task, phase: GlyEnRouteConstants.phase_PROPERTY_ARRIVED())
            })
            actions.append(ActionItem(
                action: .pause,
                title: "Pause Task",
                isDestructive: false
            ) {
                enrouteWrapper.enroute?.getTaskManager()?.setTaskPhase(task.task, phase: GlyEnRouteConstants.phase_PROPERTY_NOT_COMPLETED())
            })
            actions.append(ActionItem(
                action: .complete,
                title: "Complete Task",
                isDestructive: true
            ) {
                // Dialog is shown instead of immediate action
            })
            
        case GlyEnRouteConstants.phase_PROPERTY_ARRIVED():
            actions.append(ActionItem(
                action: .complete,
                title: "Complete Task",
                isDestructive: true
            ) {
                // Dialog is shown instead of immediate action
            })
            
        default:
            break
        }
        
        return actions
}
