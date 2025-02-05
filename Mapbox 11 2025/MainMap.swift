//
//  ContentView.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//

import SwiftUI
import MapboxMaps

struct MainMap: View {
    @StateObject var viewModel: MainMapViewModel
    @State private var style = Style.gaiaTopo
    @State private var currentDownloads: [MapDownloadTask] = []
    let centerCoordinate = CLLocationCoordinate2D(latitude: 46.86, longitude: -121.71)
    
    var body: some View {
        VStack {
            MapReader { proxy in
                Map(initialViewport: .camera(center: centerCoordinate, zoom: 14))
                    .mapStyle(MapStyle(uri: StyleURI(rawValue: style.rawValue)!))
                    .onStyleLoaded { _ in
                        guard let map = proxy.map else { return }
                        viewModel.mapboxMap = map
                        viewModel.setupMap()
                    }
                    .ignoresSafeArea()
                    .onChange(of: viewModel.gridDataSource.gridSpacing) { _ in
                        guard let map = proxy.map else { return }
                        try? map.invalidateCustomGeometrySourceRegion(forSourceId: GridDataSource.gridSourceId, bounds: .world)
                                }
            }
            VStack {
                Text("Grid Spacing: \(viewModel.gridDataSource.gridSpacing, specifier: "%.2f")")
                Slider(value: $viewModel.gridDataSource.gridSpacing, in: 0.01...10) {
                            Text("Grid Spacing")
                        } minimumValueLabel: {
                            Image(systemName: "grid")
                                .font(.system(size: 12))
                        } maximumValueLabel: {
                            Image(systemName: "grid")
                                .font(.system(size: 24))
                        }
                    }
                    .padding(10)
// ignore
//            VStack {
//               
//                
//                
//              // Here's a demo of offline tile downloading. Currently the bounding box and list of
//              // map sources is hardcoded here, but could also be selectable through the UI.
//                Button("Clear cache") {
//                    MapboxMap.clearData(completion: {_ in })
//                }
//              Button("Download offline maps for Mount Rainier NP") {
//                for sourceID in ["gaiaosmv3", "contoursfeetz12", "landcover", "gaiashadedrelief"] {
//                  let source = MapSourcesService.shared.sources[sourceID]!
//                  let bounds = Bounds(west: -121.92, south: 46.72, east: -121.50, north: 47.00) // Mount Rainier National Park (approx)
//                  let downloadTask = MapDownloadService.shared.downloadTask(source: source, bounds: bounds, zooms: 0...12)!
//                  currentDownloads.append(downloadTask)
//                }
//              }
//
//              // Show progress bars for any tile downloads that are in progress
//              if currentDownloads.count > 0 {
//                VStack {
//                  ForEach(currentDownloads, id: \.templateURL.rawValue) { download in
//                      ProgressView(download.progress)
//                  }
//                }
//              }
//
//            }
        }
    }
}

enum Style: String {
  case gaiaTopo = "https://static.gaiagps.com/GaiaTopoGL/v5/gaiatopo-feet.json"
  case gaiaWinter = "https://static.gaiagps.com/GaiaTopoGL/v3/gaiawinter-feet.json"
    case mapboxOutdoors = "mapbox://styles/mapbox/outdoors-v11"
}

#Preview {
    MainMap(viewModel: MainMapViewModel())
}
