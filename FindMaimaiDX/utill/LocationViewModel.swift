// LocationViewModel.swift
import Foundation
import CoreLocation

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    @Published var city: String?
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var errorMessage: String?
    @Published var isLocationAuthorized: Bool = false
    @Published var formattedAddress: String?
    private let apiKey = "bb0e04ceb735481cf4e461628345f4ec" // 替换为你的高德地图 API Key
    private let defaultCity = "北京"

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        print("LocationViewModel initialized")
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        fetchCityName(from: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to find user's location: \(error.localizedDescription)"
    }

    private func fetchCityName(from location: CLLocation) {
        guard let latitude = latitude, let longitude = longitude else {
            return
        }
        
        guard let url = URL(string: "https://restapi.amap.com/v3/geocode/regeo?location=\(longitude),\(latitude)&key=\(apiKey)&output=json") else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch city name: \(error.localizedDescription)"
                    self.setDefaultCity()
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                    self.setDefaultCity()
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
                        self.isLocationAuthorized = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No city found"
                        self.setDefaultCity()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error decoding JSON: \(error.localizedDescription)"
                    self.setDefaultCity()
                }
            }
        }.resume()
    }

    private func setDefaultCity() {
        city = defaultCity
        formattedAddress = "FindMaimaiDX 北京"
        isLocationAuthorized = true
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted, .notDetermined:
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied"
                self.setDefaultCity()
            }
        @unknown default:
            break
        }
    }
}

struct GeocodeResponse: Codable {
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
