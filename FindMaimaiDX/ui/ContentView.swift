import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var places: [Place] = []
    @State private var favoritePlaceIds: Set<Int> = []
    @State private var infoText: String = "卡在这个页面打开定位权限并且关闭夜间模式"
    @State private var errorMessage: String? = nil
    @StateObject private var locationManager = LocationManager()
    @State private var city :String? = nil

    var body: some View {
        NavigationView {
            VStack {
                Text(infoText)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.pink)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }

                TabView {
                    // 机厅页面
                    List(sortedPlaces) { place in
                        NavigationLink(destination: PageView(place: place, favoritePlaceIds: $favoritePlaceIds)) {
                            PlaceRow(place: place)
                        }
                    }
                    .tabItem {
                        Image(systemName: "house")
                        Text("机厅")
                    }

                    // 收藏页面
                    List(favoritePlaces) { place in
                        NavigationLink(destination: PageView(place: place, favoritePlaceIds: $favoritePlaceIds)) {
                            PlaceRow(place: place)
                        }
                    }
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("收藏")
                    }
                    MapView(
                        city: self.city ?? "北京",
                                    latitude: locationManager.location?.coordinate.latitude,
                                    longitude: locationManager.location?.coordinate.longitude
                                )
                                .tabItem {
                                    Image(systemName: "map.fill")
                                    Text("地图")
                                }
                    // 新增的 Paika 页面
                    PaikaView()
                        .tabItem {
                            Image(systemName: "tag.fill") // 使用标签图标表示 Paika
                            Text("排卡")
                        }
                    SettingsView()
                            .tabItem {
                                Image(systemName: "gear")
                                Text("设置")
                            }
                }
            }
            .onAppear {
                loadFavoritePlaceIds()
                let identifier = Bundle.main.bundleIdentifier
                print("应用标识符: \(identifier ?? "未知")")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("1 秒后执行")
                    // 确保一定会输出经纬度信息
                    if let currentLocation = locationManager.location {
                        let latitude = currentLocation.coordinate.latitude
                        let longitude = currentLocation.coordinate.longitude
                        print("✅ 成功获取当前位置 - 纬度: \(latitude), 经度: \(longitude)")
                        print("📍 位置精度 - 水平: \(currentLocation.horizontalAccuracy)米, 垂直: \(currentLocation.verticalAccuracy)米")
                        print("🕒 位置时间戳: \(currentLocation.timestamp)")
                        
                        // 强制输出到infoText
                        infoText = "当前位置: 纬度 \(String(format: "%.6f", latitude)), 经度 \(String(format: "%.6f", longitude))"
                        
                        reverseGeocodeLocation(latitude: latitude, longitude: longitude) { city in
                            if let city = city {
                                print("🌆 解析到的城市: \(city)")
                                self.city = city
                                infoText = "FindMaimaiDX - \(city)，当前位置: 纬度 \(String(format: "%.6f", latitude)), 经度 \(String(format: "%.6f", longitude))"
                                fetchPlaces(city: city)
                            } else {
                                print("⚠️ 无法解析城市，使用默认位置")
                                fetchPlaces(city: "北京")
                                infoText = "FindMaimaiDX - 无法解析城市，当前位置: 纬度 \(String(format: "%.6f", latitude)), 经度 \(String(format: "%.6f", longitude))"
                            }
                        }
                    } else {
                        // 使用测试坐标时也强制输出
                        let testLatitude: Double = 39.90923
                        let testLongitude: Double = 116.397428
                        print("⚠️ 使用测试坐标 - 纬度: \(testLatitude), 经度: \(testLongitude)")
                        infoText = "FindMaimaiDX - 使用测试坐标: 纬度 \(String(format: "%.6f", testLatitude)), 经度 \(String(format: "%.6f", testLongitude))"
                        
                        print("⚠️ 无法获取测试坐标城市")
                        fetchPlaces(city: "北京")
                        infoText = "FindMaimaiDX - 使用测试坐标: 纬度 \(String(format: "%.6f", testLatitude)), 经度 \(String(format: "%.6f", testLongitude))"
                    }
                }
                
            }
            .navigationTitle("")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fetchPlaces(city: String) {
        print("https://mais.godserver.cn/api/mai/v1/search?prompt1=\(city.replacingOccurrences(of: "市", with: ""))&status=市")
        guard let url = URL(string: "https://mais.godserver.cn/api/mai/v1/search?prompt1=\(city.replacingOccurrences(of: "市", with: ""))&status=市") else {
            errorMessage = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                errorMessage = "Error fetching places: \(error.localizedDescription)"
                return
            }

            guard let data = data else {
                errorMessage = "No data received"
                return
            }

            do {
                let fetchedPlaces = try JSONDecoder().decode([Place].self, from: data)
                DispatchQueue.main.async {
                    self.places = fetchedPlaces
                }
            } catch {
                errorMessage = "Error decoding JSON: \(error.localizedDescription)"
            }
        }.resume()
    }
    func reverseGeocodeLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        // 尝试离线解析
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("⚠️ 地理编码失败: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("⚠️ 无地理编码结果")
                completion(nil)
                return
            }
            
            // 优先取 locality（城市），若没有则取 administrativeArea（省份）
            let city = placemark.locality ?? placemark.administrativeArea ?? "未知位置"
            print("📍 解析结果: \(city)")
            completion(city)
        }
    }
    private func loadFavoritePlaceIds() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoritePlaceIds") as? [Int] {
            favoritePlaceIds = Set(savedFavorites)
        }
    }

    private func saveFavoritePlaceIds() {
        UserDefaults.standard.set(Array(favoritePlaceIds), forKey: "favoritePlaceIds")
    }

    var favoritePlaces: [Place] {
        places.filter { place in
            favoritePlaceIds.contains(place.id)
        }
    }

    var sortedPlaces: [Place] {
        places // 不再需要排序
    }
}

// 辅助视图组件
struct PlaceRow: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading) {
            Text(place.name ?? "Unknown Name")
                .font(.headline)
                .foregroundColor(place.name == nil ? .red : .primary)
            Text(place.address ?? "Unknown Address")
                .font(.subheadline)
                .foregroundColor(place.address == nil ? .red : .primary)
            Text(place.area ?? "")
                .font(.caption)
        }
    }
}

struct PlusButton: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.largeTitle)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
            .shadow(radius: 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
