import Foundation
import SwiftUI
import Combine
import GlympseKit
import EnRouteApi

class EventListener: NSObject, ObservableObject, GlyListener {
    
    static let shared = EventListener()
    
    @Published var firstStarted: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var isLoginFailure: Bool = false
    @Published var areTasksSynced: Bool = false
    @Published var tasks: [TaskWrapper]? = nil

    
    private func setFirstStarted() {
        DispatchQueue.main.async {
            self.firstStarted = true
        }
    }
    
    private func updateIsLoggedIn() {
        DispatchQueue.main.async {
            self.isLoggedIn = enrouteWrapper.enroute?.isLoginNeeded() == false
        }
    }
    
    private func updateIsLoginFailure(isFailed: Bool) {
        DispatchQueue.main.async {
            self.isLoginFailure = isFailed
        }
    }
    
    private func updateAreTasksSynced(isSynced: Bool) {
        DispatchQueue.main.async {
            self.areTasksSynced = isSynced
        }
    }
    
    private func updateTaskList() {
        DispatchQueue.main.async {
            var newTasks: [TaskWrapper] = []
            let tasks = enrouteWrapper.enroute?.getTaskManager()?.getTasks()
            if let tasks = tasks {
                let taskCount = tasks.count()
                for index in 0..<taskCount {
                    if let task = tasks[index] {
                        newTasks.append(TaskWrapper(task: task, phase: task.getPhase()))
                    }
                }
            }
            self.tasks = newTasks
        }
    }
    
    func eventsOccurred(_ source: GlySource!, listener: Int32, events: Int32, param1: GlyCommon!, param2: GlyCommon!) {
        if (listener == GlyEnRouteEvents.listener_ENROUTE_MANAGER()) {
            if (0 != (events & GlyEnRouteEvents.enroute_MANAGER_LOGIN_COMPLETED())) {
                updateIsLoggedIn()
            }
            if (0 != (events & GlyEnRouteEvents.enroute_MANAGER_LOGGED_OUT())) {
                if let logoutReason = param1 as? GlyLong {
                    if (logoutReason.longValue() == GlyEnRouteConstants.logout_REASON_INVALID_CREDENTIALS()) {
                        updateIsLoginFailure(isFailed: true)
                    }
                }
                updateIsLoggedIn()
            }
            if (0 != (events & GlyEnRouteEvents.enroute_MANAGER_SYNCED())) {
                updateIsLoggedIn()
                enrouteWrapper.enroute?.getTaskManager()?.add(self)
            }
            if (0 != (events & GlyEnRouteEvents.enroute_MANAGER_STARTED())) {
                updateIsLoginFailure(isFailed: false)
                updateIsLoggedIn()
                setFirstStarted()
            }
            if (0 != (events & GlyEnRouteEvents.enroute_MANAGER_STOPPED())) {
                updateAreTasksSynced(isSynced: false)
            }
        }
        if (listener == GlyEnRouteEvents.listener_TASKS()) {
            if (0 != (events & GlyEnRouteEvents.tasks_TASK_LIST_CHANGED())) {
                updateTaskList()
                updateAreTasksSynced(isSynced: true)
            }
            if (0 != (events & GlyEnRouteEvents.tasks_TASK_PHASE_CHANGED())) {
                updateTaskList()
            }
        }
    }
}

