// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var places: [Place] = []
    @State private var infoText: String = "卡在这个页面打开定位权限并且关闭夜间模式"
    @State private var errorMessage: String? = nil
    @State private var isActionSheetPresented = false
    @StateObject private var locationViewModel = LocationViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text(infoText)
                    .padding()
                    .background(Color.white) // 保持背景颜色为白色
                    .foregroundColor(.pink) // 修改字体颜色为粉色
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading) // 文本靠左显示
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                
                List(places) { place in
                    NavigationLink(destination: PageView(place: place)) {
                        VStack(alignment: .leading) {
                            if let name = place.name {
                                Text(name)
                                    .font(.headline)
                            } else {
                                Text("Unknown Name")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            if let address = place.address {
                                Text(address)
                                    .font(.subheadline)
                            } else {
                                Text("Unknown Address")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            if let area = place.area {
                                Text(area)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .onAppear {
                print("ContentView onAppear")
                locationViewModel.startUpdatingLocation()
            }
            .onChange(of: locationViewModel.isLocationAuthorized) { isAuthorized in
                if isAuthorized {
                    if let city = locationViewModel.city {
                        print("Fetching places for city: \(city)")
                        fetchPlaces(city: city)
                    } else {
                        errorMessage = "Failed to get city name"
                        print("Failed to get city name")
                    }
                }
            }
            .onChange(of: locationViewModel.formattedAddress) { formattedAddress in
                if let formattedAddress = formattedAddress {
                    infoText = formattedAddress
                }
            }
            .overlay(
                NavigationLink(destination: ActionSheetView()) {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding(),
                alignment: .bottomTrailing
            )
            .navigationTitle("")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func fetchPlaces(city: String) {
        guard let url = URL(string: "http://mai.godserver.cn:11451/api/mai/v1/search?prompt1=\(city)&status=市") else {
            print("Invalid URL")
            errorMessage = "Invalid URL"
            return
        }
        
        print("Fetching places from URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching places: \(error)")
                errorMessage = "Error fetching places: \(error.localizedDescription)"
                return
            }
            
            guard let data = data else {
                print("No data received")
                errorMessage = "No data received"
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let places = try decoder.decode([Place].self, from: data)
                DispatchQueue.main.async {
                    self.places = places
                    print("Places fetched successfully: \(places)")
                }
            } catch {
                print("Error decoding JSON: \(error)")
                print("JSON data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
                errorMessage = "Error decoding JSON: \(error.localizedDescription)"
            }
        }.resume()
    }
}

struct ActionSheetView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .padding()
                .background(Color.white) // 保持背景颜色为白色
                .foregroundColor(.pink) // 修改字体颜色为粉色
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading) // 文本靠左显示
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
