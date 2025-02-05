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
    
    func setupMap() {
           guard let map = mapboxMap else { return }
           // Create options for the grid and then configure it.
           gridDataSource.options = gridDataSource.makeCustomGeometrySourceOptions(for: map)
           gridDataSource.configureGrid(on: map)
       }
    
    func clearCache() {
        MapboxMap.clearData(completion: {_ in })
    }

}
