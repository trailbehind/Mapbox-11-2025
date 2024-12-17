//
//  MapViewModel.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/17/24.
//

import Foundation
import MapboxMaps

class MapViewModel: ObservableObject {
    var mapboxMap: MapboxMap?
    
    func clearCache() {
        MapboxMap.clearData(completion: {_ in })
    }

}
