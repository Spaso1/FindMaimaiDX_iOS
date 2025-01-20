import Foundation

class LocationViewModel: ObservableObject {
    @Published var city: String?
    @Published var formattedAddress: String?
    private let apiKey = "bb0e04ceb735481cf4e461628345f4ec" // 替换为你的高德地图 API Key
    
    func fetchCityName(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://restapi.amap.com/v3/geocode/regeo?location=\(longitude),\(latitude)&key=\(apiKey)&output=json") else {
            completion("北京")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to fetch city name: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let geocodeResponse = try decoder.decode(GeocodeResponse.self, from: data)
                if let regeocode = geocodeResponse.regeocode, let addressComponent = regeocode.addressComponent, let city = addressComponent.city, let formattedAddress = regeocode.formattedAddress {
                    DispatchQueue.main.async {
                        self.city = city
                        self.formattedAddress = "FindMaimaiDX \(formattedAddress)"
                        completion(city)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

struct GeocodeResponse: Codable {
    let status: String
    let info: String
    let infocode: String
    let regeocode: Regeocode?
}

struct Regeocode: Codable {
    let addressComponent: AddressComponent?
    let formattedAddress: String?
}

struct AddressComponent: Codable {
    let city: String?
    let province: String?
    let district: String?
}
