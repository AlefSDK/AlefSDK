//
//  AlefSDK.swift
//  FELA
//
//  Created by Lam Ngo (Work) on 10/20/19.
//  Copyright © 2019 AlefEdge, Inc. All rights reserved.
//

import UIKit
//import Firebase
import FirebaseCore
import FirebaseMessaging
import AWSSNS
import AWSCognitoIdentityProvider

public class AlefSDK: NSObject {
    
    private static var sharedAlefSDK: AlefSDK = {
        let sdk = AlefSDK()
        
        return sdk
    }()
    
    let gcmMessageIDKey = "gcm.message_id"
    
    public class func shared() -> AlefSDK {
        return sharedAlefSDK
    }
    
    public func initialize() {
        awsInit()
        firebaseInit()
    }
    
    private func awsInit() {
        print (Environment.identityPoolId)
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APSouth1, identityPoolId: Environment.identityPoolId)
        
        let defaultServiceConfiguration = AWSServiceConfiguration(region: .APSouth1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default()?.defaultServiceConfiguration = defaultServiceConfiguration
    }
    
    private func firebaseInit() {
        FirebaseApp.configure()
        
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            let openAction = UNNotificationAction(identifier: "OpenNotification", title: NSLocalizedString("Abrir", comment: ""), options: UNNotificationActionOptions.foreground)
            let defaultCategory = UNNotificationCategory(identifier: "CustomPush", actions: [openAction], intentIdentifiers: [], options: [])
            UNUserNotificationCenter.current().setNotificationCategories(Set([defaultCategory]))
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }

        UIApplication.shared.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
    }
    
    func handle(_ userInfo: [AnyHashable: Any], background: Bool) {
        print (userInfo)
        if let rmnLink = userInfo["rmn_link"] as? String {
            if let currentTop = UIApplication.shared.topMostViewController() {
                currentTop.present(UINavigationController(rootViewController: AlefSDKPlayerViewController(urlString: rmnLink, titleString: nil)), animated: true, completion: nil)
            }
        }
    }
}

extension AlefSDK: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        register(customUserData: "iOS", deviceToken: fcmToken)
    }
}

extension AlefSDK: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handle(notification.request.content.userInfo, background: false)
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handle(response.notification.request.content.userInfo, background: true)
    }
}

extension AlefSDK {
    private func register(customUserData: String, deviceToken: String) {
        guard UserDefaults.standard.string(forKey: "endpointArnForSNS") != nil else {
            let snsClient = AWSSNS.default()
            
            let platformEndpointRequest = AWSSNSCreatePlatformEndpointInput()
            platformEndpointRequest?.token = deviceToken
            platformEndpointRequest?.platformApplicationArn = Environment.platformApplicationArn
            platformEndpointRequest?.customUserData = customUserData
            
            snsClient.createPlatformEndpoint(platformEndpointRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
                if task.error != nil {
                    print("Error: \(String(describing: task.error))")
                } else {
                    let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                    
                    if let endpointArnForSNS = createEndpointResponse.endpointArn {
                        print("endpointArn: \(endpointArnForSNS)")
                        UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                    }
                }
                
                return nil
            })
            
            return
        }
    }
    
    private func unregisterCurrent() {
        if let currentEndpointArn = UserDefaults.standard.string(forKey: "endpointArnForSNS") {
            let snsClient = AWSSNS.default()
            
            let deleteEndpointRequest = AWSSNSDeleteEndpointInput()
            deleteEndpointRequest?.endpointArn = currentEndpointArn
            
            snsClient.deleteEndpoint(deleteEndpointRequest!, completionHandler: { error in
                if let error = error {
                    print ("Error: \(error)")
                } else {
                    UserDefaults.standard.removeObject(forKey: "endpointArnForSNS")
                }
            })
        }
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab.topMostViewController()
        }
        
        return self
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}
