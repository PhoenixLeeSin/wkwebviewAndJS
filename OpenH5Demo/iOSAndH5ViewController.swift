//
//  iOSAndH5ViewController.swift
//  OpenH5Demo
//
//  Created by 李桂盛 on 2020/6/17.
//  Copyright © 2020 陈良静. All rights reserved.
//
/* iOS传值给JS  以下三种情况
 *  1)webview加载完成前，将用户信息传给js
 *  2)webview加载完成，将相关信息传给js
 *  3)调用相册或相机时，将选择的图片请求后台接口，后台返回图片地址，将该地址回传给H5，H5将图片显示到页面上
 *
 *
 */
import UIKit
import WebKit
import JavaScriptCore

class iOSAndH5ViewController: UIViewController {

    var wkwebView: WKWebView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// JS调用iOS 并可以向iOS传值
        self.wkwebView.configuration.userContentController.add(self, name: "back")
        self.wkwebView.configuration.userContentController.add(self, name: "camera")
        self.wkwebView.configuration.userContentController.add(self, name: "album")
        self.wkwebView.configuration.userContentController.add(self, name: "loadIndicator")
        self.wkwebView.configuration.userContentController.add(self, name: "hiddenIndicator")
        
        // 针对1) 先用JS调用iOS方法
        self.wkwebView.configuration.userContentController.add(self, name: "getUserInfoBeforeLoaded")
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //移除
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "back")
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "camera")
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "album")
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "loadIndicator")
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "hiddenIndicator")
        
        self.wkwebView.configuration.userContentController.removeScriptMessageHandler(forName: "getUserInfoBeforeLoaded")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()
        self.wkwebView = WKWebView.init(frame: self.view.bounds, configuration: config)
        self.wkwebView.navigationDelegate = self
        self.wkwebView.uiDelegate = self
        self.view.addSubview(wkwebView)
        
        let path = Bundle.main.path(forResource: "11", ofType: "html")
        let count = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        self.wkwebView.loadHTMLString(count, baseURL: Bundle.main.bundleURL)
    }
}
//MARK: WKNavigationDelegate
extension iOSAndH5ViewController: WKNavigationDelegate {
    //MARK: 2) webview加载完成 iOS向JS传值
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let inputJS = "getUserInfo" + "('延迟5秒后:iOS向JS传递的值->sinleee hello')"
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+5) {
            self.wkwebView.evaluateJavaScript(inputJS) { (response, error) in
                print( response , error)
            }
        }
    }
}
//MARK: WKUIDelegate
extension  iOSAndH5ViewController: WKUIDelegate {
    
}
//MARK: WKScriptMessageHandler
extension iOSAndH5ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        print(message.body)
        /// message 是 JS向iOS传递的信息 message.name：方法名     message.body参数
        switch message.name {
        case "back":
            if let body = message.body as? String {
                print("这是返回" + body)
            } else {
                print("这是返回")
            }
        case "camera":
            print("这是相机")
        case "album":
            print("这是相册")
        case "loadIndicator":
            print("这是加载进度条")
        case "hiddenIndicator":
            print("这是取消进度条")
        // 针对1) 实现该方法并且在此向JS传值
        case "getUserInfoBeforeLoaded":
            let dic = ["id": "123","name": "iOS向JS传值"]
            if let data = try?JSONSerialization.data(withJSONObject: dic, options: JSONSerialization.WritingOptions.prettyPrinted) {
                let str = String(data: data, encoding: String.Encoding.utf8)
                
                let inputJS = "getCurrentUser" + "(\(str ?? ""))"
                print(inputJS)
                self.wkwebView.evaluateJavaScript(inputJS) { (response, error) in
                    print( response , error)
                }
            }
        default:
            break;
        }
    }
}
