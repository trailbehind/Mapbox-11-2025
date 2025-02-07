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
                    .onMapLoaded { _ in
                        guard let map = proxy.map else { return }
                        viewModel.mapboxMap = map
                        viewModel.setupMap()
                    }
                    .ignoresSafeArea()
                //jmTODO: this needs to become onCameraChanged and adapt the grid for different zoom levels, see DistanceGrid in the current project
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
