//
//  CustomHttpInterceptor.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//


import Foundation
import MapboxMaps
import MapboxCommon

class CustomHttpInterceptor: HttpServiceInterceptorInterface {
    
    func onRequest(for request: HttpRequest, continuation: @escaping HttpServiceInterceptorRequestContinuation) {
    
        var url = URL(string: request.url)!
        if url.scheme == "g" {
            // FIXME lots of unsafe force-unwrapping here
            let key = String(url.host!)
            let mapSource = MapSourcesService.shared.sources[key]!
            let tileURLTemplate = mapSource.tileURL!
            let components = url.pathComponents.suffix(3).map { Int($0)! }
            let tileID = TileID(z: components[0], x: components[1], y: components[2])
            
            //check if the tile exists offline
            let mbtilesPath = MapDownloadService.shared.storageDirectory
              .appendingPathComponent(key)
              .appendingPathExtension("mbtiles")
              .path

            if let mbtiles = try? MBTiles.open(path: mbtilesPath) {
                if let tile = mbtiles[z: tileID.z, x: tileID.x, y: tileID.y] {
                    // the tile exists in the offline cache; construct a fake HTTP response
                    // in order to hand the tile data back to Mapbox
                    let headers = [
                        "content-type": "application/x-protobuf",
                        "content-encoding": "gzip",
                    ]
                    let data = HttpResponseData(headers: headers, code: 200, data: tile)
                    let response = HttpResponse(identifier: 0, request: request, result: .success(data))
                    continuation(HttpRequestOrResponse.fromHttpResponse(response))
                    return
                }
            }
            
            // not in offline storage; request from server
            url = tileURLTemplate.toURL(tile: tileID)
            
            let returnRequest = HttpRequest(method: request.method, url: url.absoluteString, headers: request.headers, timeout: request.timeout, networkRestriction: request.networkRestriction, sdkInformation: request.sdkInformation, body: request.body, flags: request.flags)
            continuation(HttpRequestOrResponse.fromHttpRequest(returnRequest))
        } else {
            continuation(HttpRequestOrResponse.fromHttpRequest(request))
        }
    }
    
    
    func onResponse(for response: HttpResponse, continuation: @escaping HttpServiceInterceptorResponseContinuation) {
        continuation(response)
    }
}
    
 
