//
//  AppDelegate.swift
//  ios_nbcp
//
//  Created by phyrum on 3/18/19.
//  Copyright © 2019 phyrum. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Localize_Swift
import SVProgressHUD

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var vc: UIViewController!
    
    enum IntializeMainControllerType {
        case normal
        case notificationRedirectToChat
        case notificationRedirectToTransactionHistory
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Localize.setCurrentLanguage(AppUserDefault.getLanguageCode())
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        // [END register_for_notifications]
    
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        SVProgressHUD.setDefaultMaskType(.black)
        initializeMainController(type: .normal)
        AppTheme.applyTheme()
        
        return true
    }
    
    func switchRootDrawerController(notificationPayload: NotificationPayload? = nil) {
        let mainViewController = DashboardViewController()
        let mainNavigationController = UINavigationController(rootViewController: mainViewController)
        self.window?.rootViewController = mainNavigationController
        
        if let notificationPayload = notificationPayload {
            if notificationPayload.notifyType == 1 {
                let chatViewController = ChatViewController()
                chatViewController.matchId = notificationPayload.matchId
                mainNavigationController.pushViewController(chatViewController, animated: true)
            } else if notificationPayload.notifyType == 2 {
                mainNavigationController.pushViewController(TransactionHistoryTableViewController(), animated: true)
            } else if notificationPayload.notifyType == 3 {
                let chatViewController = ChatViewController()
                chatViewController.matchId = notificationPayload.matchId
                mainNavigationController.pushViewController(chatViewController, animated: true)
            }
        }
    }
    
    func switchRootLoginNavigationController() {
        window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
    }
    
    func initializeMainController(type: IntializeMainControllerType, notificationPayload: NotificationPayload? = nil) {
        if UserAuthentication.checkIfUserValidLoggedIn() {
            let mainViewController = DashboardViewController()
            let mainNavigationController = UINavigationController(rootViewController: mainViewController)
            self.window?.rootViewController = mainNavigationController
            switch type {
            case .notificationRedirectToChat:
                guard let notificationPayload = notificationPayload else {
                    return
                }
                
                let chatViewController = ChatViewController()
                chatViewController.matchId = notificationPayload.matchId
                mainNavigationController.pushViewController(chatViewController, animated: true)
                return
            case .notificationRedirectToTransactionHistory:
                mainNavigationController.pushViewController(TransactionHistoryTableViewController(), animated: true)
                return
            default:
                return
            }
        } else {
            let mainViewController = LoginViewController()
            if let notificationPayload = notificationPayload {
                mainViewController.notificationPayload = notificationPayload
            }
            let mainNavigationController = UINavigationController(rootViewController: mainViewController)
            self.window?.rootViewController = mainNavigationController
        }
    }

    func validateNotificationPayload(notificationPayload: NotificationPayload) {
        switch notificationPayload.notifyType {
        case 1:
            return initializeMainController(type: .notificationRedirectToChat, notificationPayload: notificationPayload)
        case 2:
            return initializeMainController(type: .notificationRedirectToTransactionHistory, notificationPayload: notificationPayload)
        case 3:
            return initializeMainController(type: .notificationRedirectToChat, notificationPayload: notificationPayload)
        default:
            return
        }
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification
      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
        
        guard let notificationPayload = Helper.convertToNotificationPayload(userInfo: userInfo) else {
            return
        }
        validateNotificationPayload(notificationPayload: notificationPayload)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification
      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
        
        Helper.sendLocalPushNotification(userInfor: userInfo)
      completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//      print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//      print("APNs token retrieved: \(deviceToken)")

      // With swizzling disabled you must set the APNs token here.
      // Messaging.messaging().apnsToken = deviceToken
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        /* Will enable after demo
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window!.frame
        blurEffectView.tag = 999999999

        self.window?.addSubview(blurEffectView)
        */
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        UserAuthentication.validateUserLoginAndLogout()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
//        initializeMainController(type: .normal)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        self.window?.viewWithTag(999999999)?.removeFromSuperview()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        UserAuthentication.validateUserLoginAndLogout()
    }
}
// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID. Print full message: print(userInfo)
        // Change this to your preferred presentation option
        
        if let viewControllers = window?.rootViewController?.children {
            var isFoundChatScreen = false
            for viewController in viewControllers where viewController is ChatViewController {
                isFoundChatScreen = true
            }
            if isFoundChatScreen {
                completionHandler([])
                return
            }
        }
        
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if userInfo[gcmMessageIDKey] != nil {
            guard let notificationPayload = Helper.convertToNotificationPayload(userInfo: userInfo) else {
                return
            }
            validateNotificationPayload(notificationPayload: notificationPayload)
        }
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate: MessagingDelegate {
  // [START refresh_token]
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    let dataDict: [String: String] = ["token": fcmToken]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
  }
  // [END refresh_token]
}
