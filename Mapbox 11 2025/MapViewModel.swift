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
    @Published var currentDownloads: [MapDownloadTask] = []
    @Published var mapStyle: String = Style.gaiaTopo.rawValue
    
    func clearCache() {
        MapboxMap.clearData(completion: {_ in })
    }
    
    func downloadOfflineMaps() {
        for sourceID in ["gaiaosmv3", "contoursfeetz12", "landcover", "gaiashadedrelief", "air-quality-today", "GaiaTopoRasterFeet"] {
          let source = MapSourcesService.shared.sources[sourceID]!
          let bounds = Bounds(west: -121.92, south: 46.72, east: -121.50, north: 47.00) // Mount Rainier National Park (approx)
          let downloadTask = MapDownloadService.shared.downloadTask(source: source, bounds: bounds, zooms: 0...12)!
          currentDownloads.append(downloadTask)
        }
    }
    
    func layerMaps() {
        var merger = StylesheetMerger(sources: [MapSourcesService.shared.sources["air-quality-today"]!, MapSourcesService.shared.sources["GaiaTopoRasterFeet"]!],
                         baseMapInteractionLayers: ["poi-clusters-minzoom", "poi-clusters"],
                                      basemapInteractionLayerDetailsTemplates: [:],
                         styleDictionary: ["glyphs": "https://static.gaiagps.com/GaiaTopoGL/glyphs/{fontstack}/{range}.pbf",
                                           "layers": [],
                                           "sources": [String: Any](),
                                           "version": 8],
                         baseMapSource: MapSourcesService.shared.sources["GaiaTopoRasterFeet"]!,
                         darkMode: false)
        // try just returning the gaiatopo stylesheet
        var styleDictionary = merger.mergeSources()
        let mergedStyleData = try! JSONSerialization.data(withJSONObject: styleDictionary, options: .prettyPrinted)
        let styleDirectory = "\(NSTemporaryDirectory())style"
        // TODO: Handle errors instead of force
        if !FileManager.default.fileExists(atPath: styleDirectory) {
            try! FileManager.default.createDirectory(atPath: styleDirectory, withIntermediateDirectories: true)
        }
        let fileName = "mergesource.json"
        let tempStylePath = "\(styleDirectory)\(fileName)"
        let url = URL(fileURLWithPath: tempStylePath)
        // TODO: Handle errors instead of force
        try! mergedStyleData.write(to: url)

        mapStyle = url.absoluteString
        
    }

}
