import SwiftUI
import WebKit // 导入WebKit以使用WebView

struct PageView: View {
    @State var place: Place
    @Binding var favoritePlaceIds: Set<Int>
    @State private var markets: [Market] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var hasLiked = false
    @State private var hasDisliked = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 基本信息网格布局
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    // 第一行
                    InfoCell(title: "地址", value: place.address ?? "未知", color: .blue)
                    InfoCell(title: "总数量", value: place.count?.description ?? "未知", color: .purple)
                    
                    // 第二行
                    InfoCell(title: "经度", value: place.x?.description ?? "未知", color: .gray)
                    InfoCell(title: "纬度", value: place.y?.description ?? "未知", color: .gray)
                    
                    // 第三行
                    InfoCell(title: "好评", value: place.good?.description ?? "未知", color: .green)
                    InfoCell(title: "差评", value: place.bad?.description ?? "未知", color: .red)
                    
                    // 第四行
                    InfoCell(title: "国机数量", value: place.num?.description ?? "未知", color: .purple)
                    InfoCell(title: "其他数量", value: place.numJ?.description ?? "未知", color: .purple)
                }
                .padding(.bottom, 16)
                
                // 点赞和踩按钮
                HStack(spacing: 20) {
                    Button(action: {
                        if !hasLiked {
                            likeMarket(placeId: place.id, typeId: 1) { _ in
                                hasLiked.toggle()
                                if hasDisliked {
                                    hasDisliked.toggle()
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 20))
                            Text("点赞")
                                .font(.subheadline)
                        }
                        .padding(10)
                        .background(hasLiked ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(hasLiked ? .blue : .gray)
                    }
                    
                    Button(action: {
                        if !hasDisliked {
                            dislikeMarket(placeId: place.id, typeId: 2) { _ in
                                hasDisliked.toggle()
                                if hasLiked {
                                    hasLiked.toggle()
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: hasDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .font(.system(size: 20))
                            Text("踩")
                                .font(.subheadline)
                        }
                        .padding(10)
                        .background(hasDisliked ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(hasDisliked ? .red : .gray)
                    }
                }
                .padding(.bottom, 16)
                
                // WebView
                if let x = place.x, let y = place.y, let city = place.city {
                    let webViewURL = "https://www.godserver.cn/mapmaimai?type=phone&la=\(y)&lo=\(x)&city=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    
                    WebView(urlString: webViewURL)
                        .frame(height: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.bottom, 16)
                    
                } else {
                    Text("无法加载地图: 缺少位置信息")
                        .foregroundColor(.red)
                        .padding(.bottom, 16)
                }
                
                // 市场列表
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 40)
                } else if !markets.isEmpty {
                    VStack(alignment: .leading) {
                        Text("附近商超")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        ForEach(markets) { market in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(market.marketName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("距离机厅: \(market.distance) 米")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.bottom, 8)
                        )}
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear() {
                if let x = place.x, let y = place.y, let city = place.city {
                    let webViewURL = "https://www.godserver.cn/mapmaimai?type=phone&la=\(y)&lo=\(x)&city=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    print(webViewURL)
                }
            }
            // Toast 提示
            if showToast {
                ToastView(message: toastMessage)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
            }
        }
        .navigationTitle(place.name ?? "地点详情")
        .toolbar {
            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .yellow : .gray)
            }
        }
        .onAppear {
            isLoading = true
            fetchMarkets(for: place.id) { fetchedMarkets in
                DispatchQueue.main.async {
                    isLoading = false
                    if let fetchedMarkets = fetchedMarkets {
                        markets = fetchedMarkets
                    } else {
                        errorMessage = "无法获取市场数据"
                    }
                }
            }
            
            hasLiked = UserDefaults.standard.bool(forKey: "hasLiked_\(place.id)")
            hasDisliked = UserDefaults.standard.bool(forKey: "hasDisliked_\(place.id)")
        }
    }
    
    // 自定义信息单元格视图
    struct InfoCell: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
    
    // WebView实现
    struct WebView: UIViewRepresentable {
        let urlString: String
        
        func makeUIView(context: Context) -> WKWebView {
            let webView = WKWebView()
            return webView
        }
        
        func updateUIView(_ uiView: WKWebView, context: Context) {
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                uiView.load(request)
            }
        }
    }
    
    // 其他方法保持不变...
    func fetchMarkets(for placeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "https://mais.godserver.cn/api/mai/v1/near?id=\(placeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching markets: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            do {
                let markets = try JSONDecoder().decode([Market].self, from: data)
                completion(markets)
            } catch {
                print("Error decoding JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func likeMarket(placeId: Int, typeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "https://mais.godserver.cn/api/mai/v1/place?id=\(placeId)&type=\(typeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error sending like request: \(error)")
                completion(nil)
                return
            }
            
            if typeId == 1 {
                DispatchQueue.main.async {
                    place.good = (place.good ?? 0) + 1
                    showToast(message: "点赞成功")
                }
            }
            completion(nil)
        }.resume()
    }
    
    func dislikeMarket(placeId: Int, typeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "https://mais.godserver.cn/api/mai/v1/place?id=\(placeId)&type=\(typeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error sending dislike request: \(error)")
                completion(nil)
                return
            }
            
            if typeId == 2 {
                DispatchQueue.main.async {
                    place.bad = (place.bad ?? 0) + 1
                    showToast(message: "已踩")
                }
            }
            completion(nil)
        }.resume()
    }
    
    func showToast(message: String) {
        toastMessage = message
        showToast = true
    }
    
    var isFavorite: Bool {
        favoritePlaceIds.contains(place.id)
    }
    
    func toggleFavorite() {
        if isFavorite {
            favoritePlaceIds.remove(place.id)
        } else {
            favoritePlaceIds.insert(place.id)
        }
        saveFavoritePlaceIds()
    }
    
    func saveFavoritePlaceIds() {
        UserDefaults.standard.set(Array(favoritePlaceIds), forKey: "favoritePlaceIds")
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PageView(
                place: Place(id: 0, name: "天河城", province: "广东省", city: "广州市", area: "天河区", address: "天河区天河城", isUse: 1, x: 113.322647, y: 23.131985, count: 10, good: 5, bad: 2, num: 3, numJ: 1),
                favoritePlaceIds: .constant([])
            )
        }
    }
}
