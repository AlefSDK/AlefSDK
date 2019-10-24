//
//  Environment.swift
//  FELA
//
//  Created by Lam Ngo (Work) on 10/23/19.
//  Copyright © 2019 AlefEdge, Inc. All rights reserved.
//

import Foundation

public enum Environment {
  // MARK: - Keys
  enum Keys {
    enum Plist {
        static let platformApplicationArn = "PLATFORM_APPLICATION_ARN"
        static let identityPoolId = "IDENTITY_POOL_ID"
        static let analyticsUrl = "ANALYTICS_URL"
    }
  }

  // MARK: - Plist
  private static let infoDictionary: [String: Any] = {
    print (Bundle(identifier: "org.cocoapods.AlefSDK"))
    print (Bundle(identifier: "com.alefedge.AlefSDK"))
    print (Bundle.main.path(forResource: "Info-Alef", ofType: "plist"))
    print (Bundle(for: AlefSDKPlayerViewController.self))
    print (Bundle.main)
    
    guard let dict = Bundle.main.infoDictionary else {
      print("Plist file not found")
        return [:]
    }
    
    print (dict)
    return dict
  }()

  // MARK: - Plist values
  static let platformApplicationArn: String = {
    guard let platformApplicationArn = Environment.infoDictionary[Keys.Plist.platformApplicationArn] as? String else {
      print ("Root URL not set in plist for this environment")
        return ""
    }
    
    return platformApplicationArn
  }()

  static let identityPoolId: String = {
    guard let identityPoolId = Environment.infoDictionary[Keys.Plist.identityPoolId] as? String else {
      print("Root URL not set in plist for this environment")
        return ""
    }
    
    return identityPoolId
  }()
    
static let analyticsUrl: String = {
  guard let analyticsUrl = Environment.infoDictionary[Keys.Plist.analyticsUrl] as? String else {
    print("Root URL not set in plist for this environment")
    return ""
  }
  
  return analyticsUrl
}()
}
