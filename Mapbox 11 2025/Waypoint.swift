//
//  Waypoint.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 2/5/25.
//

import MapboxMaps

struct Waypoint {
    var id: Int
    var latitude: Double
    var longitude: Double
    var image: String
    
    static func waypointToFeature(waypoint: Waypoint) -> Feature {
        let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
        let point = Point(coordinate)
        var feature = Feature(geometry: .point(point))
        feature.properties = [
            "id": .string(String(waypoint.id)),
            "icon": .string(waypoint.image)
        ]
        return feature
    }
}
