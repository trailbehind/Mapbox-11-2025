//
//  ContentView.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//

import SwiftUI
import MapboxMaps

struct ContentView: View {
    @State private var style = Style.gaiaTopo
    @State private var currentDownloads: [MapDownloadTask] = []
    let centerCoordinate = CLLocationCoordinate2D(latitude:  42.741971, longitude: -108.817711)
    
    var body: some View {
        VStack {
            Map(initialViewport: .camera(center: centerCoordinate, zoom: 14))
                .mapStyle(MapStyle(uri: StyleURI(rawValue: style.rawValue)!))
                .ignoresSafeArea()
            VStack {
              // Here's a demo of offline tile downloading. Currently the bounding box and list of
              // map sources is hardcoded here, but could also be selectable through the UI.
              Button("Download offline maps for Mount Rainier NP") {
                for sourceID in ["gaiaosmv3", "contoursfeetz12", "landcover", "gaiashadedrelief"] {
                  let source = MapSourcesService.shared.sources[sourceID]!
                  let bounds = Bounds(west: -121.92, south: 46.72, east: -121.50, north: 47.00) // Mount Rainier National Park (approx)
                  let downloadTask = MapDownloadService.shared.downloadTask(source: source, bounds: bounds, zooms: 0...12)!
                  currentDownloads.append(downloadTask)
                }
              }

              // Show progress bars for any tile downloads that are in progress
              if currentDownloads.count > 0 {
                VStack {
                  ForEach(currentDownloads, id: \.templateURL.rawValue) { download in
                      ProgressView(download.progress)
                  }
                }
              }

            }
        }
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
