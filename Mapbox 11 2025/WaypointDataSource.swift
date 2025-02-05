//
//  WaypointDataSource.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 2/5/25.
//

import SwiftUI
import MapboxMaps

class WaypointDataSource: ObservableObject {
    @Published var options: CustomGeometrySourceOptions?
    static let layerId = "waypoint-layer"
    static let sourceId = "waypoints"
    private let defaultImageName = "pin"
    var grid = false
    
    @Published var waypoints: [Waypoint] = []
    
    init() {
        self.waypoints = fetchWaypoints()
    }
    
    
    // Simulate fetching from CoreData
     private func fetchWaypoints() -> [Waypoint] {
         var generatedWaypoints: [Waypoint] = []

         let startLatitude = 47.42
         let startLongitude = -121.425
         let spacing = 0.1
         let gridDimension = 10
         let totalPoints = 1000
         if grid {
             for row in 0..<gridDimension {
                 for col in 0..<gridDimension {
                     let latitude = startLatitude + (Double(row) * spacing)
                     let longitude = startLongitude + (Double(col) * spacing)

                     let waypoint = Waypoint(id: row * gridDimension + col, latitude: latitude, longitude: longitude, image: randomMarkerImage())
                     generatedWaypoints.append(waypoint)
                 }
             }
         } else {
             for i in 0..<totalPoints {
                 let latitude = startLatitude + Double.random(in: -spacing...spacing)
                 let longitude = startLongitude + Double.random(in: -spacing...spacing)
                 let waypoint = Waypoint(id: i, latitude: latitude, longitude: longitude, image: randomMarkerImage())
                 generatedWaypoints.append(waypoint)
             }
         }
         print("Generated waypoint count: \(generatedWaypoints.count)")
         return generatedWaypoints
     }

    
    private func randomMarkerImage() -> String {
        return MarkerDecoration.allCases.randomElement()?.rawValue ?? defaultImageName

    }
    
    
    func configureWaypointsLayer(on mapboxMap: MapboxMap) {
        do {
            // Remove existing layer/source if present.
            try? mapboxMap.removeLayer(withId: Self.layerId)
            try? mapboxMap.removeSource(withId: Self.sourceId)
            
            // Create the custom geometry source with current options.
            let options = makeCustomGeometrySourceOptions(for: mapboxMap)
            let source = CustomGeometrySource(id: Self.sourceId, options: options)
            try mapboxMap.addSource(source)
            
            // Create and configure a symbol layer for waypoints.
            var symbolLayer = SymbolLayer(id: Self.layerId, source: Self.sourceId)
            symbolLayer.iconImage = .expression(Exp(.get) { "icon" })
            symbolLayer.iconAllowOverlap = .constant(true)
            symbolLayer.iconSize = .constant(1.0)
            symbolLayer.iconAnchor = .constant(.center)
            symbolLayer.iconOffset = .constant([0, 0])
            symbolLayer.textField = .constant("{id}")
            symbolLayer.textSize = .constant(12.0)
            symbolLayer.textColor = .constant(StyleColor(.black))
            symbolLayer.textOffset = .constant([0, 2])
            
            try mapboxMap.addLayer(symbolLayer)
        } catch {
            print("Error configuring waypoints layer: \(error)")
        }
    }
    
    func makeCustomGeometrySourceOptions(for mapboxMap: MapboxMap) -> CustomGeometrySourceOptions {
        let tileOptions = TileOptions(
            tolerance: 0.375,
            tileSize: 256,
            buffer: 1,
            clip: true,
            wrap: false
        )
        
        return CustomGeometrySourceOptions(
            fetchTileFunction: { [weak self] tileID in
                guard let self = self else { return }
                
    
                var bounds = Math.boundsFromTile(tileID)
                bounds = Math.bufferBounds(bounds: bounds, buffer: 1 / 256)
                
                var imagesToLoad = Set<String>()
                let features: [Feature] = self.waypoints.compactMap { waypoint in
                    if bounds.contains(latitude: waypoint.latitude, longitude: waypoint.longitude) {
                        imagesToLoad.insert(waypoint.image)
                        return Waypoint.waypointToFeature(waypoint: waypoint)
                    } else {
                        return nil
                    }
                }
                self.loadImagesForCurrentTile(imageNames: imagesToLoad, mapboxMap: mapboxMap)
                try! mapboxMap.setCustomGeometrySourceTileData(
                    forSourceId: Self.sourceId,
                    tileId: tileID,
                    features: features
                )
            },
            cancelTileFunction: { _ in },
            tileOptions: tileOptions
        )
    }
    
    
    // MARK: - Helper: Load Images
    
    /// Loads all required images for the current tile into the style.
    private func loadImagesForCurrentTile(imageNames: Set<String>, mapboxMap: MapboxMap) {
        imageNames.forEach { loadImage(named: $0, mapboxMap: mapboxMap) }
    }
    
    /// Loads a single image into the map style if it isn't already present.
    private func loadImage(named name: String, mapboxMap: MapboxMap) {
        if let image = UIImage(named: name) {
            do {
                if !mapboxMap.imageExists(withId: name) {
                    try mapboxMap.addImage(image, id: name, sdf: false)
                }
            } catch {
                print("Failed to add image \(name): \(error)")
            }
        } else {
            print("Image \(name) not found in bundle.")
        }
    }
}
