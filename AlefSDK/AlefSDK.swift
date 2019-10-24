//
//  AlefSDK.swift
//  FELA
//
//  Created by Lam Ngo (Work) on 10/20/19.
//  Copyright © 2019 AlefEdge, Inc. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import AWSSNS
import AWSCognitoIdentityProvider
import NotificationBannerSwift

public class AlefSDK: NSObject {
    private var config = Config()
    
    private var buildType: Int?
    
    public var setBuildType: Int? {
        set {
            if buildType == nil {
                if let newValue = newValue {
                    if newValue > 2 || newValue < 0 {
                        buildType = 2
                    } else {
                        buildType = newValue
                    }
                }
            }
        }
        
        get {
            return buildType
        }
    }
    
    private static var sharedAlefSDK: AlefSDK = {
        let sdk = AlefSDK()
        
        return sdk
    }()
    
    let gcmMessageIDKey = "gcm.message_id"
    
    public class func shared() -> AlefSDK {
        return sharedAlefSDK
    }
    
    public func initialize(options: FirebaseOptions) {
        awsInit()
        firebaseInit(options: options)
    }
    
    private func awsInit() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APSouth1, identityPoolId: config.identityPool)
        
        let defaultServiceConfiguration = AWSServiceConfiguration(region: .APSouth1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default()?.defaultServiceConfiguration = defaultServiceConfiguration
    }
    
    private func firebaseInit(options: FirebaseOptions) {
        if FirebaseApp.app() != nil {
            FirebaseApp.configure(name: "alef", options: options)
        } else {
            FirebaseApp.configure(options: options)
        }
        
        Messaging.messaging().delegate = self
    }
    
    public func requestUserNotification() {
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in
                    Messaging.messaging().isAutoInitEnabled = true
            })
            
//            let openAction = UNNotificationAction(identifier: "OpenNotification", title: NSLocalizedString("Abrir", comment: ""), options: UNNotificationActionOptions.foreground)
//            let defaultCategory = UNNotificationCategory(identifier: "CustomPush", actions: [openAction], intentIdentifiers: [], options: [])
//            UNUserNotificationCenter.current().setNotificationCategories(Set([defaultCategory]))
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }

        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func handle(_ userInfo: [AnyHashable: Any], background: Bool) {
        if let rmnLink = userInfo["rmn_link"] as? String {
            if let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: String] {
                let banner = NotificationBanner(title: alert["title"], subtitle: alert["body"], style: .success)
                banner.show()
                
                banner.onTap = {
                    if let currentTop = UIApplication.shared.topMostViewController() {
                        currentTop.present(UINavigationController(rootViewController: AlefSDKPlayerViewController(urlString: rmnLink, titleString: nil)), animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

extension AlefSDK {
    func getCookie(cookies: String) {
        let cookieList = cookies.split(separator: ";")
        
        for cookie in cookieList {
            if cookie.contains("uuid") {
                let uuid = cookie.split(separator: "=")[1]
                syncUUID(uuid: String(uuid))
                return
            }
        }
    }
    
    func syncUUID(uuid: String?) {
        if let uuid = uuid, let endpointArn = UserDefaults.standard.string(forKey: "endpointArnForSNS") {
            let parameters = ["userID" : uuid, "endpointArn" : endpointArn]
            
            if let url = URL(string: config.analyticsURL[buildType ?? 2]) {
                let session = URLSession.shared
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                } catch let error {
                    print (error.localizedDescription)
                    
                    return
                }
                
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let task = session.dataTask(with: request, completionHandler: { data, response ,error in
                    guard error == nil else {
                        print (error!.localizedDescription)
                        return
                    }
                    
                    guard data != nil else {
                        return
                    }
                })
                
                task.resume()
            }
            
            
        }
    }
}

extension AlefSDK: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        if let currentToken = UserDefaults.standard.string(forKey: "alefFcmToken") {
            print (currentToken)
            if currentToken != fcmToken {
                unregisterCurrent()
                register(customUserData: "iOS", deviceToken: fcmToken)
            }
        } else {
            unregisterCurrent()
            register(customUserData: "iOS", deviceToken: fcmToken)
        }
    }
}

extension AlefSDK: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print ("helloooooooooooo")
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
            platformEndpointRequest?.platformApplicationArn = config.platformApplicationArn[buildType ?? 2]
            platformEndpointRequest?.customUserData = customUserData
            
            snsClient.createPlatformEndpoint(platformEndpointRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
                if task.error != nil {
                    print("Error: \(String(describing: task.error))")
                } else {
                    let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                    
                    if let endpointArnForSNS = createEndpointResponse.endpointArn {
                        print("endpointArn: \(endpointArnForSNS)")
                        UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                        UserDefaults.standard.set(deviceToken, forKey: "alefFcmToken")
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
