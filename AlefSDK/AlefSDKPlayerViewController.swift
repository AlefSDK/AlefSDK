//
//  AlefPlayerViewController.swift
//  FELA
//
//  Created by Lam Ngo (Work) on 10/23/19.
//  Copyright © 2019 AlefEdge, Inc. All rights reserved.
//

import UIKit
import WebKit

class AlefSDKPlayerViewController: UIViewController, WKNavigationDelegate {
    var urlString: String?
    var titleString: String?
    let webView = WKWebView()
    
    init(urlString: String, titleString: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.urlString = urlString
        self.titleString = titleString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print ("Alef Player Web Deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissFunc))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.myColor(night: .white, day: .black)

        if let navigationController = navigationController {
            let startColor = UIColor().colorFromHex("E0267A")
            let endColor = UIColor().colorFromHex("7347E4")
            let navImage = CAGradientLayer.primaryGradient(on: navigationController.navigationBar, start: startColor, end: endColor)
            
            navigationController.navigationBar.barTintColor = UIColor(patternImage: navImage!)
        }
        
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        if let urlString = urlString {
            webView.load(urlString)
        }
        
        title = titleString ?? "Alef SDK"
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let cookieScript = "document.cookie;"
        webView.evaluateJavaScript(cookieScript) { (response, error) in
            if let response = response as? String {
                AlefSDK.shared().getCookie(cookies: response)
            }
        }
    }
    
    @objc func dismissFunc() {
        dismiss(animated: true, completion: nil)
    }
    
    override func loadView() {
        self.view = webView
    }
    
    func load(_ urlString: String) {
        webView.load(urlString)
    }
    
}

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}

extension UIColor {
    func colorFromHex(_ hex: String) -> UIColor {
        var colorString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if colorString.hasPrefix("#") {
            colorString.remove(at: colorString.startIndex)
        }
        
        if colorString.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: colorString).scanHexInt32(&rgbValue)
        
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                       blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                       alpha: 1.0)
    }
    
    static func myColor(night: UIColor, day: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor.init { (trait) -> UIColor in
                return trait.userInterfaceStyle == .dark ? night : day
            }
        }
        else { return night }
    }
}

extension CAGradientLayer {
    
    class func primaryGradient(on view: UIView, start: UIColor, end: UIColor) -> UIImage? {
        let gradient = CAGradientLayer()
        var bounds = view.bounds
        bounds.size.height += UIApplication.shared.statusBarFrame.height
        gradient.frame = bounds
        gradient.colors = [start.cgColor, end.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        return gradient.createGradientImage(on: view)
    }
    
    private func createGradientImage(on view: UIView) -> UIImage? {
        var gradientImage: UIImage?
        UIGraphicsBeginImageContext(view.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        }
        UIGraphicsEndImageContext()
        return gradientImage
    }
}
