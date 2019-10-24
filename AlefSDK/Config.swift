//
//  File.swift
//  AlefSDK
//
//  Created by Lam Ngo (Work) on 10/24/19.
//  Copyright © 2019 AlefEdge, Inc. All rights reserved.
//

import Foundation

struct Config {
    let identityPool = "ap-south-1:736953f0-9057-49f3-8e83-aac681ddf899"
    let platformApplicationArn = ["arn:aws:sns:ap-south-1:182890061560:app/GCM/RMN-Test", "arn:aws:sns:ap-south-1:182890061560:app/GCM/RMN-Dev", "arn:aws:sns:ap-south-1:182890061560:app/GCM/RMN-Prod"]
    let analyticsURL = ["https://analytics.testalef.net", "https://danalytics.testalef.net", "https://analytics.amclik.com"]
}
