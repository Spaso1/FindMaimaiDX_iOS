struct Market: Codable, Identifiable {
    var id: Int
    var marketName: String
    var parentId: Int
    var distance: Double
    var type: Int
    var x: Double
    var y: Double
}
