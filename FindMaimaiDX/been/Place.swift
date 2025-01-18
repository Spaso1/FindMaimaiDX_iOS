// Place.swift
import Foundation

struct Place: Codable, Identifiable {
    var id: Int
    var name: String?
    var province: String
    var city: String
    var area: String?
    var address: String
    var isUse: Int
    var x: Double
    var y: Double
    var count: Int
    var good: Int
    var bad: Int
    var num: Int
    var numJ: Int
}
