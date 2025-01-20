import SwiftUI

struct ContentView: View {
    @State private var places: [Place] = []
    @State private var favoritePlaceIds: Set<Int> = []
    @State private var infoText: String = "卡在这个页面打开定位权限并且关闭夜间模式"
    @State private var errorMessage: String? = nil
    @StateObject private var locationViewModel = LocationViewModel()

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
                    List(sortedPlaces) { place in
                        NavigationLink(destination: PageView(place: place, favoritePlaceIds: $favoritePlaceIds)) {
                            PlaceRow(place: place)
                        }
                    }
                    .tabItem {
                        Image(systemName: "house")
                        Text("机厅")
                    }

                    List(favoritePlaces) { place in
                        NavigationLink(destination: PageView(place: place, favoritePlaceIds: $favoritePlaceIds)) {
                            PlaceRow(place: place)
                        }
                    }
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("收藏")
                    }
                }
            }
            .onAppear {
                loadFavoritePlaceIds()
                
                // 使用预定义的经纬度来测试
                let testLatitude: Double = 39.90923
                let testLongitude: Double = 116.397428
                
                locationViewModel.fetchCityName(latitude: testLatitude, longitude: testLongitude) { city in
                    if let city = city {
                        fetchPlaces(city: city)
                    } else {
                        fetchPlaces(city: "北京")
                        infoText = "FindMaimaiDX - 无法定位，使用默认位置：BeiJing"
                    }
                }
            }
            .onChange(of: locationViewModel.formattedAddress) { formattedAddress in
                infoText = formattedAddress ?? ""
            }
            .overlay(
                NavigationLink(destination: ActionSheetView()) {
                    PlusButton()
                }
                .padding(),
                alignment: .bottomTrailing
            )
            .navigationTitle("")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fetchPlaces(city: String) {
        guard let url = URL(string: "http://mai.godserver.cn:11451/api/mai/v1/search?prompt1=\(city)&status=市") else {
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
               // 使用 place.id 直接比较而不是 hashValue，确保 id 类型一致
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
