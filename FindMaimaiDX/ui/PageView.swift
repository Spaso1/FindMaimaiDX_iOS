import SwiftUI

struct PageView: View {
    @State var place: Place
    @Binding var favoritePlaceIds: Set<Int> // 新增绑定属性
    @State private var markets: [Market] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var hasLiked = false // 新增状态变量
    @State private var hasDisliked = false // 新增状态变量
    
    var body: some View {
        VStack(alignment: .leading) {
            if let address = place.address {
                Text("地址: \(address)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            } else {
                Text("未知地址")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            if let x = place.x {
                Text("经度: \(x)")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("未知经度")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let y = place.y {
                Text("纬度: \(y)")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("未知纬度")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let count = place.count {
                Text("总数量: \(count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("未知总数量")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let good = place.good {
                Text("好评: \(good)")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("未知好评")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let bad = place.bad {
                Text("差评: \(bad)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("未知差评")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let num = place.num {
                Text("国机数量: \(num)")
                    .font(.caption)
                    .foregroundColor(.purple)
            } else {
                Text("未知国机数量")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let numJ = place.numJ {
                Text("其他数量: \(numJ)")
                    .font(.caption)
                    .foregroundColor(.purple)
            } else {
                Text("未知其他数量")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            if showToast {
                ToastView(message: toastMessage)
                    .transition(.opacity)
                    .padding(.bottom, 20)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
            }
            // 显示 markets 列表
            if isLoading {
                ProgressView()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                List(markets) { market in
                    VStack(alignment: .leading) { // 确保 VStack 靠左对齐
                        Text(market.marketName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("距离机厅: \(market.distance) 米")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .listStyle(PlainListStyle())
                .padding(.leading, 10)
                
            }
        }
        .padding()
        .navigationTitle(place.name ?? "地点详情")
        .toolbar {
            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.largeTitle)
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
            
            // 检查是否已经点赞或踩过
            hasLiked = UserDefaults.standard.bool(forKey: "hasLiked_\(place.id)")
            hasDisliked = UserDefaults.standard.bool(forKey: "hasDisliked_\(place.id)")
            print("Initial state: hasLiked = \(hasLiked), hasDisliked = \(hasDisliked)")
        }
    }
    
    func fetchMarkets(for placeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "http://mai.godserver.cn:11451/api/mai/v1/near?id=\(placeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        print("Fetching markets for placeId: \(placeId)")
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
                print("Markets fetched successfully: \(markets)")
                completion(markets)
            } catch {
                print("Error decoding JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func likeMarket(placeId: Int, typeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "http://mai.godserver.cn:11451/api/mai/v1/place?id=\(placeId)&type=\(typeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        print("Sending like request with typeId: \(typeId) for placeId: \(placeId)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error sending like request: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received in like request")
                completion(nil)
                return
            }
            
            do {
                showToast(message: "操作成功")
                if typeId == 1 {
                    place.good = (place.good ?? 0) + 1
                    print("Updated place.good: \(place.good ?? 0)")
                } else if typeId == 4 {
                    place.good = (place.good ?? 0) + 1
                    place.bad = (place.bad ?? 0) - 1
                    print("Updated place.good: \(place.good ?? 0), place.bad: \(place.bad ?? 0)")
                }
                completion(nil)
            } catch {
                print("Error decoding JSON in like request: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func dislikeMarket(placeId: Int, typeId: Int, completion: @escaping ([Market]?) -> Void) {
        let urlString = "http://mai.godserver.cn:11451/api/mai/v1/place?id=\(placeId)&type=\(typeId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        print("Sending dislike request with typeId: \(typeId) for placeId: \(placeId)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error sending dislike request: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received in dislike request")
                completion(nil)
                return
            }
            
            do {
                showToast(message: "操作成功")
                if typeId == 2 {
                    place.bad = (place.bad ?? 0) + 1
                    print("Updated place.bad: \(place.bad ?? 0)")
                } else if typeId == 3 {
                    place.bad = (place.bad ?? 0) + 1
                    place.good = (place.good ?? 0) - 1
                    print("Updated place.bad: \(place.bad ?? 0), place.good: \(place.good ?? 0)")
                }
                completion(nil)
            } catch {
                print("Error decoding JSON in dislike request: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func showToast(message: String) {
        toastMessage = message
        showToast = true
        print("Showing toast message: \(message)")
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
        PageView(
            place: Place(id: 0, name: "天河城", province: "广东省", city: "广州市", area: "天河区", address: "天河区天河城", isUse: 1, x: 113.322647, y: 23.131985, count: 10, good: 5, bad: 2, num: 3, numJ: 1),
            favoritePlaceIds: .constant([])
        )
    }
}
