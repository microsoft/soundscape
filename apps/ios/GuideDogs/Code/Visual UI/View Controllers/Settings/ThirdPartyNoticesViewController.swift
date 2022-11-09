//
//  ThirdPartyNoticesViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import WebKit
import SafariServices
import CocoaLumberjackSwift

class ThirdPartyNoticesViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webview.navigationDelegate = self
        webview.scrollView.indicatorStyle = .white
        
        loadLicenses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.about.third_party_notices")
    }
    
    // MARK: Actions
    
    private func loadLicenses() {
        if let licensesPath = Bundle.main.path(forResource: "licenses", ofType: "html") {
            let url = URL(fileURLWithPath: licensesPath)
            webview.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            DDLogWarn("no licenses HTML file found")
        }
    }
}

extension ThirdPartyNoticesViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // If we are loading the initial licenses HTML file
        guard !url.absoluteString.contains("licenses.html") else {
            decisionHandler(.allow)
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = Colors.Background.primary
        safariVC.preferredControlTintColor = Colors.Foreground.primary
        
        present(safariVC, animated: true, completion: nil)
        
        decisionHandler(.cancel)
    }
}

extension ThirdPartyNoticesViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
