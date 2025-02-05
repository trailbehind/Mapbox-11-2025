//
//  MainMapViewModel.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/17/24.
//

import Foundation
import MapboxMaps

class MainMapViewModel: ObservableObject {
    var mapboxMap: MapboxMap?
    @Published var gridDataSource = GridDataSource()
    @Published var waypointDataSource = WaypointDataSource()
    
    func setupMap() {
           guard let map = mapboxMap else { return }
        waypointDataSource.options = waypointDataSource.makeCustomGeometrySourceOptions(for: map)
        waypointDataSource.configureWaypointsLayer(on: map)
        
           gridDataSource.options = gridDataSource.makeCustomGeometrySourceOptions(for: map)
           gridDataSource.configureGrid(on: map)
        
       }
    
    func clearCache() {
        MapboxMap.clearData(completion: {_ in })
    }

}
