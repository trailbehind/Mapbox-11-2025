//
//  StylesheetMerger.swift
//  Gaia GPS
//
//  Created by Ben Russell on 12/2/22.
//

import Foundation

struct StylesheetMerger {
  private var sources: [MapSource]
  private var baseMapInteractionLayers: [String]
  private var basemapInteractionLayerDetailsTemplates: [String: [String: Any]]
  private var styleDictionary: [String: Any]
  private var baseMapSource: MapSource
  private var darkMode: Bool

  public init(
    sources: [MapSource],
    baseMapInteractionLayers: [String],
    basemapInteractionLayerDetailsTemplates: [String: [String: Any]],
    styleDictionary: [String: Any],
    baseMapSource: MapSource,
    darkMode: Bool
  ) {
    self.sources = sources
    self.baseMapInteractionLayers = baseMapInteractionLayers
    self.basemapInteractionLayerDetailsTemplates = basemapInteractionLayerDetailsTemplates
    self.styleDictionary = styleDictionary
    self.baseMapSource = baseMapSource
    self.darkMode = darkMode
  }

  mutating func mergeSources() -> [String: Any] {
    let implicitBaseMap = !self.sources.contains(where: { $0.basemap && $0.isGlStyle() })
    let reorderStyleLayers = self.shouldReorderStyleLayers(for: self.sources, baseMap: self.baseMapSource)

    var overlayLineInsertIndex = 0
    var layers = [[String: Any]]()

    if reorderStyleLayers,
       let layersPreFilter = styleDictionary["layers"] as? [[String: Any]] {
      for layer in layersPreFilter {
        layers.append(layer)
        overlayLineInsertIndex += 1
        if layer["id"] as? String == "trail-label" {
          break
        }
      }
    } else if implicitBaseMap,
              let defaultLayers = styleDictionary["layers"] as? [[String: Any]] {
      layers += defaultLayers
    }

    var finalSources = self.styleDictionary["sources"] as? [String: Any]
    for source in self.sources {
      if reorderStyleLayers, source == self.baseMapSource {
        continue
      }

      if source.isGlStyle() {
        guard var styleToMerge = source.getStyleDictionary(dark: darkMode) else {
          print("Failed to load style for source:\(String(describing: source.uniqueTilecacheKey))")
          continue
        }

        if source != self.sources.first {
          styleToMerge["layers"] = (styleToMerge["layers"] as? [[String: Any]])?.filter { $0["type"] as? String != "background" }
          if source.opacity() < 0.99 {
            if let newStyle = changeOpacityFor(style: styleToMerge, toValue: source.opacity()) {
              styleToMerge = newStyle
            } else {
              print("Setting opacity failed")
            }
          }
        }

        // Prefix source and layer names incase they are not unique across styles, then merge
        let prefix = source.id + "."

        if source != self.baseMapSource,
           var sourceSources = styleToMerge["sources"] as? [String: Any] {
          for (key, value) in sourceSources {
            sourceSources[prefix + key] = value
            sourceSources[key] = nil
          }
          finalSources?.merge(sourceSources) { _, new in new }
        }

        if let sourceLayers = styleToMerge["layers"] as? [[String: Any]] {
          if source != self.baseMapSource {
            self.addPrefixedSourceLayers(
              sourceLayers,
              to: &layers,
              withPrefix: prefix
            )
          } else {
            layers += sourceLayers
          }
        }

        // ORIGINAL COMMENT FROM OBJC:
        // There is no way to merge glyphs or sprites, but if they were not set in the basemap, set from overlay
        if let glyphs = styleToMerge["glyphs"], styleDictionary["glyphs"] == nil {
          self.styleDictionary["glyphs"] = glyphs
        }

        if let sprite = styleToMerge["sprite"], styleDictionary["sprite"] == nil {
          self.styleDictionary["sprite"] = sprite
        }

        // ORIGINAL COMMENT FROM OBJC:
        // interaction layers from merge layer
        if source != self.baseMapSource, let interactionLayersKeys = styleToMerge["interaction-layers"] as? [String] {
          var layerIndex = 0
          for interactionLayerKey in interactionLayersKeys {
            let key = prefix + interactionLayerKey
            layerIndex += 1
            self.baseMapInteractionLayers.insert(key, at: layerIndex)

            if let detailsTemplateKey = styleToMerge["details-template"] as? [String: Any] {
              var template: [String: Any]?

              if let interactionLayer = detailsTemplateKey[interactionLayerKey] as? [String: Any] {
                template = interactionLayer
              } else {
                template = detailsTemplateKey["*"] as? [String: Any]
              }

              if template != nil {
                self.basemapInteractionLayerDetailsTemplates[key] = template
              }
            }
          }
        }
      } else {
        var alpha: Double = 1.0
        if self.sources.first != source {
          alpha = source.opacity()
        }

        let sourceDictionary = source.getStyleSourceDictionary()
        finalSources?[source.id] = sourceDictionary
        if let layerDictionary = source.getStyleLayerDictionary(alpha: alpha) {
          layers.append(layerDictionary)
        } else {
          print("Error, source getStyleLayerDictionary: returned nil. source:\(source)")
        }
      }
    }

    if reorderStyleLayers, let availableLayers = styleDictionary["layers"] as? [[String: Any]] {
      var addLayers = false

      for layer in availableLayers {
        if addLayers {
          layers.append(layer)
        } else if layer["id"] as? String == "trail-label" {
          addLayers = true
        }
      }
    }

    self.styleDictionary["sources"] = finalSources
    self.styleDictionary["layers"] = layers
    self.styleDictionary["interaction-layers"] = self.baseMapInteractionLayers
    self.styleDictionary["details-template"] = self.basemapInteractionLayerDetailsTemplates

    return self.styleDictionary
  }

  private func shouldReorderStyleLayers(for sources: [MapSource], baseMap: MapSource) -> Bool {
    if sources.first == baseMap, baseMap.id.hasPrefix("GaiaTopoRaster") {
      let hasRasterLayer = sources.contains(where: { !$0.isGlStyle() })
      return !hasRasterLayer
    }
    return false
  }

  private func addPrefixedSourceLayers(_ sourceLayers: [[String: Any]], to layers: inout [[String: Any]], withPrefix prefix: String) {
    let sourceLayersToAdd = sourceLayers.map { layer in
      var layer = layer
      if let id = layer["id"] as? String {
        layer["id"] = prefix + id
      }

      if let source = layer["source"] as? String {
        layer["source"] = prefix + source
      }

      if let ref = layer["ref"] as? String {
        layer["ref"] = prefix + ref
      }

      return layer
    }

    layers += sourceLayersToAdd
  }
    
    func changeOpacityFor(style: [String: Any]?, toValue alpha: Double) -> [String: Any]? {
      guard var style = style,
            var styleLayers = style["layers"] as? [[String: Any]] else {
        print("Opacity change failed")
        return style
      }

      for (index, layer) in styleLayers.enumerated() {
        // NOTE: 'background' layer type is currently unimplemented, because we
        // never need to change the alpha for background layers (they are removed
        // from styles other than the bottom-most style in the layer stack prior
        // to style merging).

        if layer["type"] as? String == "fill" {
          if var paint = layer["paint"] as? [String: Any] {
            if let currentValue = paint["fill-opacity"] as? Double {
              paint["fill-opacity"] = currentValue * alpha
              styleLayers[index]["paint"] = paint
            } else if var opacityDictionary = paint["fill-opacity"] as? [String: Any] {
              if var stops = opacityDictionary["stops"] as? [[Double]] {
                for index in stops.indices {
                  if stops[index].count == 2 {
                    stops[index][1] = stops[index][1] * Double(alpha)
                  }
                }
                opacityDictionary["stops"] = stops
                paint["fill-opacity"] = opacityDictionary
                styleLayers[index]["paint"] = paint
              }
            } else {
              if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
                paintDictionary["fill-opacity"] = alpha
                styleLayers[index]["paint"] = paintDictionary
              } else {
                let alphaDictionary = ["fill-opacity": alpha]
                styleLayers[index]["paint"] = alphaDictionary
              }
            }
          }
        }

        if layer["type"] as? String == "line" {
          if var paint = layer["paint"] as? [String: Any] {
            if let currentValue = paint["line-opacity"] as? Double {
              paint["line-opacity"] = currentValue * alpha
              styleLayers[index]["paint"] = paint
            } else if var opacityDictionary = paint["line-opacity"] as? [String: Any] {
              if var stops = opacityDictionary["stops"] as? [[Double]] {
                for index in stops.indices {
                  if stops[index].count == 2 {
                    stops[index][1] = stops[index][1] * Double(alpha)
                  }
                }
                opacityDictionary["stops"] = stops
                paint["line-opacity"] = opacityDictionary
                styleLayers[index]["paint"] = paint
              }
            } else {
              if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
                paintDictionary["line-opacity"] = alpha
                styleLayers[index]["paint"] = paintDictionary
              } else {
                let alphaDictionary = ["line-opacity": alpha]
                styleLayers[index]["paint"] = alphaDictionary
              }
            }
          }
        }

        if layer["type"] as? String == "raster" {
          if var paint = layer["paint"] as? [String: Any] {
            if let currentValue = paint["raster-opacity"] as? Double {
              paint["raster-opacity"] = currentValue * alpha
              styleLayers[index]["paint"] = paint
            } else if var opacityDictionary = paint["raster-opacity"] as? [String: Any] {
              if var stops = opacityDictionary["stops"] as? [[Double]] {
                for index in stops.indices {
                  if stops[index].count == 2 {
                    stops[index][1] = stops[index][1] * Double(alpha)
                  }
                }
                opacityDictionary["stops"] = stops
                paint["raster-opacity"] = opacityDictionary
                styleLayers[index]["paint"] = paint
              }
            }
          } else {
            if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
              paintDictionary["raster-opacity"] = alpha
              styleLayers[index]["paint"] = paintDictionary
            } else {
              let alphaDictionary = ["raster-opacity": alpha]
              styleLayers[index]["paint"] = alphaDictionary
            }
          }
        }

        if layer["type"] as? String == "symbol" {
          if let layout = layer["layout"] as? [String: Any],
             layout["text-field"] != nil,
             var paint = layer["paint"] as? [String: Any] {
            if let currentValue = paint["text-opacity"] as? Double {
              paint["text-opacity"] = currentValue * alpha
              styleLayers[index]["paint"] = paint
            } else if var opacityDictionary = paint["text-opacity"] as? [String: Any] {
              if var stops = opacityDictionary["stops"] as? [[Double]] {
                for index in stops.indices {
                  if stops[index].count == 2 {
                    stops[index][1] = stops[index][1] * Double(alpha)
                  }
                }
                opacityDictionary["stops"] = stops
                paint["text-opacity"] = opacityDictionary
                styleLayers[index]["paint"] = paint
              }
            } else {
              if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
                paintDictionary["text-opacity"] = alpha
                styleLayers[index]["paint"] = paintDictionary
              } else {
                let alphaDictionary = ["text-opacity": alpha]
                styleLayers[index]["paint"] = alphaDictionary
              }
            }
          }

          if let layout = layer["layout"] as? [String: Any],
             layout["icon-image"] != nil,
             var paint = layer["paint"] as? [String: Any] {
            if let currentValue = paint["icon-opacity"] as? Double {
              paint["icon-opacity"] = currentValue * alpha
              styleLayers[index]["paint"] = paint
            } else if var opacityDictionary = paint["icon-opacity"] as? [String: Any] {
              if var stops = opacityDictionary["stops"] as? [[Double]] {
                for index in stops.indices {
                  if stops[index].count == 2 {
                    stops[index][1] = stops[index][1] * Double(alpha)
                  }
                }
                opacityDictionary["stops"] = stops
                paint["icon-opacity"] = opacityDictionary
                styleLayers[index]["paint"] = paint
              }
            } else {
              if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
                paintDictionary["icon-opacity"] = alpha
                styleLayers[index]["paint"] = paintDictionary
              } else {
                let alphaDictionary = ["icon-opacity": alpha]
                styleLayers[index]["paint"] = alphaDictionary
              }
            }
          }
        }

        if layer["type"] as? String == "circle" {
          for key in ["circle-opacity", "circle-stroke-opacity"] {
            if var paint = layer["paint"] as? [String: Any] {
              if let currentValue = paint[key] as? Double {
                paint[key] = currentValue * alpha
                styleLayers[index]["paint"] = paint
              } else if var opacityDictionary = paint[key] as? [String: Any] {
                if var stops = opacityDictionary["stops"] as? [[Double]] {
                  for index in stops.indices {
                    if stops[index].count == 2 {
                      stops[index][1] = stops[index][1] * Double(alpha)
                    }
                  }
                  opacityDictionary["stops"] = stops
                  paint[key] = opacityDictionary
                  styleLayers[index]["paint"] = paint
                }
              } else {
                if var paintDictionary = styleLayers[index]["paint"] as? [String: Any] {
                  paintDictionary[key] = alpha
                  styleLayers[index]["paint"] = paintDictionary
                } else {
                  let alphaDictionary = [key: alpha]
                  styleLayers[index]["paint"] = alphaDictionary
                }
              }
            }
          }
        }
      }
      style["layers"] = styleLayers
      return style
    }
}
