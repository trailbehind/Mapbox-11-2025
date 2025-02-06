//
//  GridDataSource.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 2/3/25.
//

import Foundation
import SwiftUI
import Combine
import MapboxMaps

class GridDataSource: ObservableObject {
    @Published var gridSpacing: Double = 7
    @Published var options: CustomGeometrySourceOptions?
    static let gridSourceId = "custom-geo-grid"
    static let gridLayerId = "grid_layer"

    func configureGrid(on map: MapboxMap) {
            guard let options = options else { return }
            do {
                // Remove existing layer/source if present.
                try? map.removeLayer(withId: Self.gridLayerId)
                try? map.removeSource(withId: Self.gridSourceId)
                // configure new source and layer
                let source = CustomGeometrySource(id: Self.gridSourceId, options: options)
                try map.addSource(source)
                
                var lineLayer = LineLayer(id: Self.gridLayerId, source: Self.gridSourceId)
                lineLayer.lineColor = .constant(StyleColor(.black))
                
                try map.addLayer(lineLayer)
            } catch {
                print("Error configuring grid: \(error)")
            }
        }
    
    func makeCustomGeometrySourceOptions(for mapboxMap: MapboxMap) -> CustomGeometrySourceOptions {
        return CustomGeometrySourceOptions(
           fetchTileFunction: { [weak self] tileId in
               guard let self else {
                   return
               }
               let neighborTile = CanonicalTileID(z: tileId.z, x: tileId.x + 1, y: tileId.y + 1)
               let bounds = CoordinateBounds(
                   southwest: CLLocationCoordinate2D(latitude: neighborTile.latitude, longitude: tileId.longitude),
                   northeast: CLLocationCoordinate2D(latitude: tileId.latitude, longitude: neighborTile.longitude)
               )

               let latFrom = ceil(bounds.northeast.latitude / gridSpacing) * gridSpacing
               let latTo = floor(bounds.southwest.latitude / gridSpacing) * gridSpacing
               let latLines = stride(from: latFrom, through: latTo, by: -gridSpacing).map { lat in
                   LineString([
                       CLLocationCoordinate2D(latitude: lat, longitude: bounds.southwest.longitude),
                       CLLocationCoordinate2D(latitude: lat, longitude: bounds.northeast.longitude)
                   ])
               }

               let lonFrom = floor(bounds.southwest.longitude / gridSpacing) * gridSpacing
               let lonTo = ceil(bounds.northeast.longitude / gridSpacing) * gridSpacing
               let lonLines = stride(from: lonFrom, through: lonTo, by: gridSpacing).map { lng in
                   LineString([
                       CLLocationCoordinate2D(latitude: bounds.southwest.latitude, longitude: lng),
                       CLLocationCoordinate2D(latitude: bounds.northeast.latitude, longitude: lng)
                   ])
               }
               try! mapboxMap.setCustomGeometrySourceTileData(
                forSourceId: Self.gridSourceId,
                   tileId: tileId,
                   features: (latLines + lonLines).map(Feature.init)
               )
           },
           cancelTileFunction: { _ in },
           tileOptions: TileOptions()
       )
    }
}

extension CanonicalTileID {
    var latitude: CLLocationDegrees {
        let n = Double.pi - 2.0 * Double.pi * Double(y) / pow(2.0, Double(z))
        return (180.0 / .pi) * atan(0.5 * (exp(n) - exp(-n)))
    }

    var longitude: CLLocationDegrees {
        return Double(x) / pow(2.0, Double(z)) * 360.0 - 180.0
    }
}


