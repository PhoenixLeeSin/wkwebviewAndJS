#### 有一段时间没写文章了，今天在水一篇关于WKWebview 和 JS 交互传值的文章，借鉴的OC版本[传送门](https://www.jianshu.com/p/0f825df61037),作者写的非常好，我本来想找一下swift的资料，大部分都是OC的，于是我就勤（chao）奋(xi)的写一下swift版本的。

### 正题

- wkwebview的实例化，这里的加载的html是本地写好的一个文件。

- ```swift
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
  
  ```



```html
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0">
        <meta http-equiv="Content-Type" content="text/html; charset=utf8">
        <script language="javascript">
            //1.返回
            function backClick() {
                window.webkit.messageHandlers.back.postMessage("这是JS传递iOS的信息");
            }
            //2.js向OC传值
            function paramClick() {
                var content = document.getElementById("firstid").value;
                window.webkit.messageHandlers.Param.postMessage(content);
            }
            //webview加载完成前，实现iOS向js传值
            window.webkit.messageHandlers.getUserInfoBeforeLoaded.postMessage(null);
                function getCurrentUser(str) {
                    document.getElementById("secondid").value = str;
                }
            //3.OC向js传值 加载完成时
            function getUserInfo(str) {
                document.getElementById("secondid").value = str;
            }
            function asyncAlert(content) {
                setTimeout(function() {
                   alert(content);
                           },1);
            }
            // 4.点击相机
            function cameraClick() {
              window.webkit.messageHandlers.camera.postMessage(null);
            }
            //5. 点击相册
            function albumClick() {
                window.webkit.messageHandlers.album.postMessage(null);
            }
         //显示图片
          function rtnCamera(basedata) {
            var zsz=document.getElementById('zsz');
            zsz.innerHTML="<image style='width:200px;height:200px;' src='data:image/png;base64,"+basedata+"'>";
        };
         </script>
    </head>
    <body>
        <h1>html5</h1>
        <input type="button" value="返回首页" onclick="backClick()" />
        <h1>传js数据给oc</h1>
        <textarea id ="firstid" type="value" rows="5" cols="40"></textarea>
        <input type="button" value="上传" onclick="paramClick()" />

        <h1>展示oc所传数据</h1>
        <textarea id ="secondid" type="value" rows="5" cols="40"> </textarea>
        
        <h1>调相机相册</h1>
        <input type="button" value="相机按钮" onclick="cameraClick()" />
        <input type="button" value="相册按钮" onclick="albumClick()" />
        <div id='zsz'></div>
        
    </body>
</html>

```

### JS调用iOS，向iOS传值 

> ```jsx
> // JS调OC，需要 H5端统一如下写法，方法名就是交互的名称，数据就是JS给OC传的值  
>   window.webkit.messageHandlers.<方法名>.postMessage(<数据>);
> 如果JS给OC传值为空，必须写成: postMessage(null)，如果什么都不写，方法是调不通的。          
> ```

#### 1. 在在viewWillAppear中配置，  `addScriptMessageHandler name: "这里就是JS的方法，方法名必须统一"`

```swift
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
```

#### 2. 配置完后必须在`viewWillDisappear`中 remove，否则会造成循环引用，导致crash

```swift
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
```

#### 3.在实现 WKScriptMessageHandler 协议

```
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
```

> 这样我们就实现了通过is调用ios方法的过程。



### 2. iOS调用JS,向JS传值

#### 这里分2种情况: 1）wkwebview加载完成前，将信息传递给js; 2) wkwebview加载完成后，将信息传递给js.

#### 2.1 wkwebview加载完成前，将信息传递给js

##### 因为 `evaluateJavaScript` 方法默认是在加载完成后调用，所以直接在页面开始加载中调用是传不过去的，这个时候怎么办呢？`我们可以让js端写两个方法， 第一个方法是js端开始向oc端发起信息需求的方法名，当oc端收到该方法名的时候，就去调用js端第二个获取传值的方法，把信息传递过去。` 详情看我在上面贴的代码或者下方的工程地址。

#### 2.2  wkwebview加载完成后，将信息传递给js.

##### 页面加载完成 直接在func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) 执行就可以啦

```swift
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

```

