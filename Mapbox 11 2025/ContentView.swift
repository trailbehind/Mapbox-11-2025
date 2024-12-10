//
//  ContentView.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//

import SwiftUI

import SwiftUI
@_spi(Experimental) import MapboxMaps

@available(iOS 14.0, *)
struct ContentView: View {
    @State private var style = Style.gaiaTopo
    
    var body: some View {
            let centerCoordinate = CLLocationCoordinate2D(latitude:  42.741971, longitude: -108.817711)
            Map(initialViewport: .camera(center: centerCoordinate, zoom: 14))
            .mapStyle(.outdoors)
                .ignoresSafeArea()
        }
}

enum Style: String {
  case gaiaTopo = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiatopo-feet.json"
  case gaiaWinter = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiawinter-feet.json"
    case mapboxOutdoors = "mapbox://styles/mapbox/outdoors-v11"
}

#Preview {
    ContentView()
}
