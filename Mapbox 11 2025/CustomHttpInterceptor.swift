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
            url = tileURLTemplate.toURL(tile: tileID)
            
            let returnRequest = HttpRequest(method: request.method, url: url.absoluteString, headers: request.headers, timeout: request.timeout, networkRestriction: request.networkRestriction, sdkInformation: request.sdkInformation, body: request.body, flags: request.flags)
            continuation(HttpRequestOrResponse.fromHttpRequest(returnRequest))
        } else {
            continuation(HttpRequestOrResponse.fromHttpRequest(request))
        }
        
        //also test reading a tile from disk and then returning a fake request

    }
    
    
    func onResponse(for response: HttpResponse, continuation: @escaping HttpServiceInterceptorResponseContinuation) {
        continuation(response)
    }
}
    
 
