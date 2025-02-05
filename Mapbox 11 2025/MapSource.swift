//
//  MapSource.swift
//  Mapbox 10 prototype
//
//  Created by Jesse Crocker on 6/13/19.
//

// Most of this code is copied from the Gaia GPS iOS app's MapSource.swift

import Foundation
import CoreLocation
import UIKit

enum TileServiceScheme: String, Codable {
    case tms, xyz
}

enum StyleLoadingError: Error {
  case jsonLoadingError
}

/// MapSource represents a Gaia GPS map source.
///
/// Users see representations of these map sources when they open the map layers menu.
/// (Not to be confused with a Mapbox map source, which is a distinct and lower level concept).
struct MapSource: Identifiable {
    
    var attribution: String
    var autoResumeDownloads: Bool
    var averageTileSize: Int
    var averageTileSizeHD: Int
    var averageTileSizeVector: Int
    var basemap: Bool
    var bounds: Bounds = MapSource.defaultBounds
    var center: [Double] = MapSource.defaultCenter
    var dataFile: String?
    var dataFileType: String?
    var defaultOpacity: Double?
    var deprecated: Bool = false
    var disclaimer: String?
    var icon: String?
    var iconURL: String?
    var iconURLLarge: String?
    var id: String
    var legendURL: String?
    var maxDownload: Int = 0
    var maxDownloadPro: Int = 0
    var maxZoom: Int = 0
    var maxZoomVector: Int = 0
    var minZoom: Int = 0
    var name: String
    var notes: String?
    var referer: String?
    var replaces: [String]?
    var replacesReason: String?
    var scheme: TileServiceScheme
    var searchKeywords: String?
    var shortName: String?
    var styleURL: String?
    var styleURLDark: String?
    var subscriptionDataset: String?
    var supportsCors: Bool?
    var tileDataType: String?
    var tileSize: Int = 256
    var tileSizeHD: Int = 256
    var tiles: [TileURLTemplate]
    var tilesHD: [TileURLTemplate]?
    var tilesPreview: [TileURLTemplate]?
    var version: Int = 1
    
    // MARK: Properties not from remote API
    
    var opacityOverride: Float?
    var isCustom: Bool = false
    var localFile: String?
}

// MARK: static properties
extension MapSource {
    private static let defaultCenter: [Double] = [-117.0209, 36.4307, 13]
    private static let defaultBounds = Bounds.mercatorSquare
    static let retinaTilesScaleThreshold = 2.0
}


// MARK: Codable
extension MapSource: Codable {
    enum CodingKeys: String, CodingKey {
        case attribution
        case autoResumeDownloads
        case averageTileSize
        case averageTileSizeHD
        case averageTileSizeVector
        case basemap
        case bounds
        case center
        case dataFile
        case dataFileType
        case defaultOpacity
        case deprecated
        case disclaimer
        case icon
        case iconURL
        case iconURLLarge
        case id
        case legendURL
        case maxDownload
        case maxDownloadPro
        case maxZoom = "maxzoom"
        case maxZoomVector = "maxzoomVector"
        case minZoom = "minzoom"
        case notes = "description"
        case name
        case referer
        case replaces
        case replacesReason
        case scheme
        case searchKeywords
        case shortName = "nameShort"
        case styleURL
        case styleURLDark
        case subscriptionDataset
        case supportsCors
        case tileDataType
        case tileSize
        case tileSizeHD
        case tiles
        case tilesHD
        case tilesPreview
        case version
    }
}

extension MapSource {
    var tileURL: TileURLTemplate? {
        return tiles.first
    }
    
    var tileURLHD: TileURLTemplate? {
        guard let url = tilesHD?.first else { return nil }
        return url
    }
    
    var tileURLPreview: TileURLTemplate? {
        guard let url = tilesPreview?.first else { return nil }
        return url
    }
    
    var reverseY: Bool { scheme == .tms }
    
    func shortNameOrName() -> String {
        if let shortName = shortName, shortName.count > 0 {
            return shortName
        } else {
            return name
        }
    }
    
    var demoCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: center[1], longitude: center[0])
    }
    
    var demoZoom: Float { Float(center[2]) }
    
    /**
     This is a versioned key that should only be used for caching tiles or styles. Otherwise use key.
     */
    func uniqueTilecacheKey() -> String {
        if version == 0 || version == 1 {
            return id
        } else {
            return "\(id)-\(version)"
        }
    }
    
    func isGlStyle() -> Bool {
        return styleURL != nil && styleURL!.count > 0
    }
    
    func getStyleDictionary(dark: Bool) -> [String: Any]? {
      guard let url = bestStyleURL(dark: dark) else {
        return nil
      }

      do {
        let styleData = try Data(contentsOf: url, options: [])
        guard let styleJson = try JSONSerialization.jsonObject(with: styleData, options: []) as? [String: Any] else {
          throw StyleLoadingError.jsonLoadingError
        }
        return styleJson
      } catch {
        print("Error loading style from URL:\(url.absoluteString) error:\(error)")
        if url.isFileURL {
          print("Removing style file because reading file failed:" + url.absoluteString)
          try? FileManager.default.removeItem(at: url)
        }
        return nil
      }
    }
    
    func bestStyleURL(dark: Bool) -> URL? {
      let styleSheetDirectory = MapDownloadService.shared.storageDirectory.absoluteString

      let useDark = dark && hasDarkModeStyle()

      // Use local style if it exists
      let localPath = localStylesheetPath(dark: useDark, styleDirectory: styleSheetDirectory)
      if FileManager.default.fileExists(atPath: localPath) {
        return URL(fileURLWithPath: localPath, isDirectory: false)
      }

      // No local copy, so check the bundle
      let resourceName = useDark ? "style-\(uniqueTilecacheKey())-dark" : "style-\(uniqueTilecacheKey())"
      if let bundlePath = Bundle.main.path(forResource: resourceName, ofType: "json") {
        if FileManager.default.fileExists(atPath: bundlePath) {
          return URL(fileURLWithPath: bundlePath, isDirectory: false)
        }
      }

      // Not in the bundle, fall back to web
      guard let styleURL = (useDark ? styleURLDark : styleURL), let remoteUrl = URL(string: styleURL) else {
        return nil
      }
      return remoteUrl
    }
    
    func hasDarkModeStyle() -> Bool {
      return styleURLDark != nil && styleURLDark!.count > 0
    }
    
    func localStylesheetPath(dark: Bool, styleDirectory: String) -> String {
      let styleDirectoryURL = URL(fileURLWithPath: styleDirectory)
      if dark {
        return styleDirectoryURL.appendingPathComponent(uniqueTilecacheKey() + "-dark.json").path
      } else {
        return styleDirectoryURL.appendingPathComponent(uniqueTilecacheKey() + ".json").path
      }
    }
    
    func getStyleSourceDictionary() -> [String: Any] {
      var type: String = tileDataType ?? "raster"
      if type == "vector.pbf" {
        type = "vector"
      }
      var sourceDictionary = [
        "bounds": bounds,
        "maxzoom": max(minZoom, maxZoom),
        "minzoom": min(minZoom, maxZoom),
        "scheme": "xyz",
        "tiles": [mapboxCacheTileURLTemplate()],
        "type": type,
      ] as [String: Any]

      if type == "raster" {
        // We could use [[UIScreen mainScreen] scale], but i think pixel perfect raster tiles on @3x displays is overkill
        let scale = Int(min(UIScreen.main.scale, 2))
        sourceDictionary["tileSize"] = pixelsPerSide() / scale
      }

      return sourceDictionary
    }
    
    func mapboxCacheTileURLTemplate() -> String {
      return "g://\(uniqueTilecacheKey())/{z}/{x}/{y}"
    }

    
    func getStyleLayerDictionary(alpha: Double) -> [String: Any]? {
      if tileDataType != "raster", tileDataType != nil {
        return nil
      }
      return [
        "id": id,
        "layout": ["visibility": "visible"],
        "paint": ["raster-opacity": alpha],
        "source": id,
        "type": "raster",
      ]
    }
    
    func pixelsPerSide() -> Int {
      if Double(UIScreen.main.scale) >= MapSource.retinaTilesScaleThreshold, tilesHD != nil {
        return tileSizeHD
      } else {
        return tileSize
      }
    }
    
    // TODO: check MB 11 for apocaity handling
    func opacity() -> Double {
      if let opacityOverride = opacityOverride {
          return Double(opacityOverride)
      }

        // TODO: I thinnk this is where the current set opacity for the layer should be read

    //    if let alpha = MapSceneDelegate.current?.mapSourcesController.alpha(for: self) {
    //      return Double(alpha)
    //    }


      return 0.3
    }
    
    
}

// MARK: Equatable
extension MapSource: Equatable {
    
    
}

