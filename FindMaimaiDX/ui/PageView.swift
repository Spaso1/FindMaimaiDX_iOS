// PageView.swift
import SwiftUI

struct PageView: View {
    var place: Place

    var body: some View {
        VStack(alignment: .leading) {
            if let name = place.name {
                Text(" \(name)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.orange)

            } else {
                Text("Unknown Name")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            if let address = place.address {
                Text("具体地址: \(address)")
                    .font(.subheadline)
            } else {
                Text("Unknown Address")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            if let num = place.num {
                Text("Num: \(num)")
                    .font(.caption)
            } else {
                Text("Unknown Num")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let numJ = place.numJ {
                Text("NumJ: \(numJ)")
                    .font(.caption)
            } else {
                Text("Unknown NumJ")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if let x = place.x {
                Text("Longitude: \(x)")
                    .font(.caption)
            } else {
                Text("Unknown Longitude")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let y = place.y {
                Text("Latitude: \(y)")
                    .font(.caption)
            } else {
                Text("Unknown Latitude")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let count = place.count {
                Text("Count: \(count)")
                    .font(.caption)
            } else {
                Text("Unknown Count")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let good = place.good {
                Text("Good: \(good)")
                    .font(.caption)
            } else {
                Text("Unknown Good")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let bad = place.bad {
                Text("Bad: \(bad)")
                    .font(.caption)
            } else {
                Text("Unknown Bad")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let num = place.num {
                Text("Num: \(num)")
                    .font(.caption)
            } else {
                Text("Unknown Num")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let numJ = place.numJ {
                Text("NumJ: \(numJ)")
                    .font(.caption)
            } else {
                Text("Unknown NumJ")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(place.name ?? "Place Details")
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView(place: Place(id: 0, name: "Place 1", province: "北京市", city: "北京市", area: "朝阳区", address: "北京市朝阳区某地址", isUse: 1, x: 116.4074, y: 39.9042, count: 10, good: 5, bad: 2, num: 3, numJ: 1))
    }
}
