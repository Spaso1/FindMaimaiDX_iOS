import SwiftUI
import WebKit

struct MapView: View {
    let city: String
    let latitude: Double?
    let longitude: Double?
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var webViewURL: String {
        let y = latitude ?? 39.9042 // 默认北京纬度
        let x = longitude ?? 116.4074 // 默认北京经度
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "北京"
        return "https://www.godserver.cn/mapmaimai?type=phone&la=\(y)&lo=\(x)&city=\(encodedCity)"
    }
    
    var body: some View {
        ZStack {
            // WebView
            WebView(urlString: webViewURL)
                .edgesIgnoringSafeArea(.all)
            
            
            // 错误信息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            
            // 刷新按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        reloadWebView()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func reloadWebView() {
        isLoading = true
        errorMessage = nil
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 可以在这里处理加载开始事件
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 可以在这里处理加载完成事件
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // 可以在这里处理加载失败事件
        }
    }
}
