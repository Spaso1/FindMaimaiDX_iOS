import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://mais.godserver.cn/api/mai/v1"
    
    func fetchPlaces(latitude: Double, longitude: Double) -> AnyPublisher<[Place], Error> {
        let urlString = "\(baseURL)/search?lat=\(latitude)&lng=\(longitude)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Place].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
