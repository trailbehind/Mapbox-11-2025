//
//  ContentView.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//

import SwiftUI
import MapboxMaps

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    @State private var style = Style.gaiaTopo
    
    let centerCoordinate = CLLocationCoordinate2D(latitude: 46.86, longitude: -121.71)
    
    var body: some View {
        VStack {
            MapReader { proxy in
                Map(initialViewport: .camera(center: centerCoordinate, zoom: 14))
                    .mapStyle(MapStyle(uri: StyleURI(rawValue: viewModel.mapStyle)!))
                    .ignoresSafeArea()
                    .onAppear {
                        guard let map = proxy.map else { return }
                        viewModel.mapboxMap = map
                    }
            }
            VStack {
              // Here's a demo of offline tile downloading. Currently the bounding box and list of
              // map sources is hardcoded here, but could also be selectable through the UI.
                Button("Clear cache") {
                    MapboxMap.clearData(completion: {_ in })
                }
              Button("Download offline maps for Mount Rainier NP") {
                  viewModel.downloadOfflineMaps()
              }
                
                Button("Layer maps") {
                    viewModel.layerMaps()
                }

              // Show progress bars for any tile downloads that are in progress
                if viewModel.currentDownloads.count > 0 {
                VStack {
                    ForEach(viewModel.currentDownloads, id: \.templateURL.rawValue) { download in
                      ProgressView(download.progress)
                  }
                }
              }

            }
        }
    }
}

enum Style: String {
  case gaiaTopo = "https://static.gaiagps.com/GaiaTopoGL/v5/gaiatopo-feet.json"
  case gaiaWinter = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiawinter-feet.json"
    case mapboxOutdoors = "mapbox://styles/mapbox/outdoors-v11"
}

#Preview {
    MapView(viewModel: MapViewModel())
}
