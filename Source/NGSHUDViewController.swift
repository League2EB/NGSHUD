//
// NGSHUD
// NGSHUDViewController 建立時間：2019/1/28 3:45 PM

import UIKit
import WebKit
import SnapKit
import Kingfisher
import PKHUD
import Reachability

open class NGSHUDViewController: UIViewController {

    open var baseURL: String = ""

    private let statusCode = Reachability()!
    private var GASMapContentView: WKWebView = WKWebView()
    private let ov = ImageDownloader.default

    open override func viewDidLoad() {
        super.viewDidLoad()

        bindUI()

        statusCode.whenReachable = { [weak self] reachability in
            guard let w = self else { return }
            if reachability.connection != .none {
                w.GASMapContentView.load(URLRequest(url: URL(string: w.baseURL)!))
            }
        }

        statusCode.whenUnreachable = { [weak self] reachability in
            guard let w = self else { return }
            let alert = UIAlertController(title: "当前无网络", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确认", style: .default, handler: nil))
            w.present(alert, animated: true, completion: nil)
        }

        do {
            try statusCode.startNotifier()
        } catch {

        }
    }

    @objc
    func pictureObject(_ ges: UIGestureRecognizer?) {
        let point: CGPoint = ges!.location(in: GASMapContentView)
        let java = "document.elementFromPoint(\(point.x), \(point.y)).src"
        GASMapContentView.evaluateJavaScript(java) { [weak self] (obj, error) in
            guard let w = self else { return }
            let imgString = obj as? String
            w.MainQueue {
                guard let imgStr = imgString else { return }
                if imgStr.count > 0 {
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "保存图片", style: .default, handler: { [weak self] (act) in
                        guard let w = self else { return }
                        let _ = w.ov.downloadImage(with: URL(string: imgString ?? "")!, retrieveImageTask: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, url, dat) in
                            guard let img = image else { return }
                            UIImageWriteToSavedPhotosAlbum(img, self, #selector(w.image(image: didFinishSavingWithError: contextInfo:)), nil)
                        })
                    }))
                    alert.addAction(UIAlertAction(title: "取消", style: .default, handler: nil))
                    w.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    @objc
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error != nil {
            HUD.flash(.labeledError(title: "保存失败", subtitle: "请至设定允许权限"), onView: self.view, delay: 0.5, completion: nil)
        } else {
            HUD.show(.labeledSuccess(title: "保存成功", subtitle: ""))
            HUD.hide(afterDelay: 0.2)
        }
    }


    public func openStringValue(webView: WKWebView) {
        guard let strValue = webView.url else { return }
        if strValue.absoluteString.hasPrefix("https://itunes.apple.com") || strValue.absoluteString.hasPrefix("https://itms-services://") {
            UIApplication.shared.openURL(strValue)
        } else {
            if !strValue.absoluteString.hasPrefix("http") {
                let wL = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as! [String]
                for i in wL {
                    let rulesString = String(format: "%@://", i)
                    if strValue.absoluteString.hasPrefix(rulesString) {
                        UIApplication.shared.openURL(strValue)
                    }
                }
            }
        }
    }

    private func openStringURLValueWithManager(str: String) -> Bool {
        if str.hasPrefix("mqq") || str.hasPrefix("weixin") || str.hasPrefix("alipay") || str.hasPrefix("wechat") {
            let success = UIApplication.shared.canOpenURL(URL(string: str)!)
            if success {
                UIApplication.shared.openURL(URL(string: str)!)
            } else if !str.hasPrefix("http") {
                let whitelist = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as! [String]
                for i in whitelist {
                    let rulesString = String(format: "%@://", i)
                    if str.hasPrefix(rulesString) {
                        UIApplication.shared.openURL(URL(string: "str")!)
                    }
                }
            } else {
                let appurl = str.hasPrefix("alipay") ? "https://itunes.apple.com/cn/app/%E6%94%AF%E4%BB%98%E5%AE%9D-%E8%AE%A9%E7%94%9F%E6%B4%BB%E6%9B%B4%E7%AE%80%E5%8D%95/id333206289?mt=8" : (str.hasPrefix("weixin") ? "https://itunes.apple.com/cn/app/%E5%BE%AE%E4%BF%A1/id414478124?mt=8" : "https://itunes.apple.com/cn/app/qq/id444934666?mt=8")
                let title = str.hasPrefix("mqq") ? "QQ" : (str.hasPrefix("weixin") ? "微信" : "支付宝")
                let titleString = "该设备未安装\(title)客户端"
                let alert = UIAlertController(title: nil, message: titleString, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "立即安装", style: .default, handler: { (act) in
                    let url = URL(string: appurl)
                    UIApplication.shared.openURL(url!)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            return true
        }
        return false
    }

    private func bindUI() {
        self.view.addSubview(GASMapContentView)
        GASMapContentView.navigationDelegate = self
        GASMapContentView.allowsBackForwardNavigationGestures = true
        GASMapContentView.allowsLinkPreview = false
        GASMapContentView.uiDelegate = self

        let UFIP = UILongPressGestureRecognizer(target: self, action: #selector(pictureObject(_:)))
        UFIP.delegate = self
        UFIP.minimumPressDuration = 0.25
        GASMapContentView.addGestureRecognizer(UFIP)

        let jsp = "document.documentElement.style.webkitTouchCallout='none';document.documentElement.style.webkitUserSelect='none';"
        let usc = WKUserContentController()
        let script = WKUserScript(source: jsp, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        usc.addUserScript(script)
        let processPool = WKProcessPool()
        let oneOKRock = WKWebViewConfiguration()
        oneOKRock.processPool = processPool
        oneOKRock.allowsInlineMediaPlayback = true
        oneOKRock.userContentController = usc
        if #available(iOS 11.0, *) {
            GASMapContentView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        GASMapContentView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func MainQueue(block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
}

extension NGSHUDViewController: WKNavigationDelegate, WKUIDelegate {

    private func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    private func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let absStringValue = navigationAction.request.url?.absoluteString {

            if openStringURLValueWithManager(str: absStringValue) {
                decisionHandler(.cancel)
                return
            }

            if absStringValue.hasPrefix("itunes.apple.com") {
                if UIApplication.shared.canOpenURL(URL(string: absStringValue)!) {
                    let alert = UIAlertController(title: nil, message: "在App Store中打开?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "打开", style: .default, handler: { (act) in
                        UIApplication.shared.openURL(URL(string: absStringValue)!)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    decisionHandler(.cancel)
                    return
                } else if absStringValue.hasPrefix("itms") {
                    UIApplication.shared.openURL(URL(string: absStringValue)!)
                } else {
                    HUD.flash(.labeledSuccess(title: "跳转失败", subtitle: ""), onView: self.view, delay: 0.5, completion: nil)

                }
            }

            let lambOfGod = "UseBrowser"
            if absStringValue.hasPrefix("my") || absStringValue.range(of: lambOfGod) != nil {
                var distanceString = absStringValue
                if absStringValue.hasPrefix("my") {
                    if let subRange = Range<String.Index>(NSRange(location: 0, length: 2), in: distanceString) { distanceString.removeSubrange(subRange) }
                }

                if distanceString.range(of: lambOfGod) != nil {
                    distanceString = distanceString.replacingOccurrences(of: lambOfGod, with: "")
                }

                if openStringURLValueWithManager(str: distanceString) {
                    decisionHandler(.cancel)
                    return
                } else {
                    let url = URL(string: distanceString)
                    if UIApplication.shared.canOpenURL(url!) {
                        let canOpen = UIApplication.shared.openURL(url!)
                        if canOpen {
                            decisionHandler(.cancel)
                            return
                        }
                    }
                }
            }
        }

        decisionHandler(.allow)
    }

    private func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteString else { return }
        if !openStringURLValueWithManager(str: url) {
            openStringValue(webView: webView)
        }
    }

    private func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';")
    }

    private func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {

    }

    private func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {

    }

    private func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
        let alertVC = UIAlertController(title: "提示 !", message: "\(message)", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "确认", style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension NGSHUDViewController: UIGestureRecognizerDelegate {
    private func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

