import UserNotifications
import UIKit
import Combine
import EnRouteApi

protocol NotificationManagerDelegate: AnyObject {
    func notificationManager(didChangeAuthorizationStatus status: UNAuthorizationStatus)
    func notificationManager(didFailToRegisterForRemoteNotificationsWithError error: Error)
    func notificationManager(didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
}

extension NotificationManagerDelegate {
    func notificationManager(didChangeAuthorizationStatus status: UNAuthorizationStatus) {}
    func notificationManager(didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    func notificationManager(didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
}

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            "Not Determined"
        case .denied:
            "Denied"
        case .authorized:
            "Authorized"
        case .provisional:
            "Provisional"
        case .ephemeral:
            "Ephemeral"
        default:
            "Unknown"
        }
    }
}

class NotificationManager: NSObject, ObservableObject, NotificationManagerDelegate {

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    weak var delegate: NotificationManagerDelegate?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var pushToken: String? = nil
    
    func configure() {
        notificationCenter.delegate = self
        logger.debug("UNUserNotificationCenter delegate configured to NotificationManager.shared")
        
        // Could use a different class as a delegate, but we'll use this class for now
        delegate = self
        logger.debug("NotificationManagerDelegate delegate configured to NotificationManager.shared")
        
        updateAuthorizationStatus()
    }
    
    func updateAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge],
                              completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    logger.error("Error requesting notification authorization: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                logger.debug("Notification authorization granted: \(granted)")
                if granted {
                    self?.registerForRemoteNotifications()
                }
                self?.getAuthorizationStatus { status in
                    self?.delegate?.notificationManager(didChangeAuthorizationStatus: status)
                }
                completion(granted, nil)
            }
        }
    }

    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            logger.warning("NotificationManager: Failed to open app settings.")
            return
        }
        
        UIApplication.shared.open(settingsUrl, options: [:]) { success in
            if success {
                logger.debug("NotificationManager: App settings opened successfully.")
            } else {
                logger.warning("NotificationManager: Failed to open app settings with valid url")
            }
        }
    }

    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            logger.debug("Attempting to register for remote notifications.")
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        logger.debug("Device Token: \(token)")
        pushToken = token
        
        guard let enroute = enrouteWrapper.enroute else {
            return
        }
        if (enroute.isStarted()) {
            enroute.registerDeviceToken("apple_background", deviceToken: pushToken)
        }
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
        delegate?.notificationManager(didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func notificationManager(didChangeAuthorizationStatus status: UNAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
    
    func notificationManager(didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let payload = userInfo["payload"] as? String else {
            completionHandler(.noData)
            return
        }
        
        enrouteWrapper.enroute?.handleRemoteNotification(payload)
        completionHandler(.newData)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.debug("NotificationManager: Notification will present in foreground: \(notification.request.content.title)")
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        logger.debug("NotificationManager: User responded to notification. Action: \(response.actionIdentifier), UserInfo: \(userInfo)")

        if response.notification.request.trigger is UNPushNotificationTrigger {
             self.delegate?.notificationManager(didReceiveRemoteNotification: userInfo, fetchCompletionHandler: { _ in })
        }
        completionHandler()
    }
}

