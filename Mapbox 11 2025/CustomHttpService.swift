//
//  CustomHttpService.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//


import Foundation
import MapboxMaps
import MapboxCommon

class CustomHttpService: HttpServiceInterceptorInterface {
    
    func onRequest(for request: HttpRequest, continuation: @escaping HttpServiceInterceptorRequestContinuation) {
        
        // Mapbox calls this method to retrieve resources (including StyleJSONs, TileJSONs,
        // spritesheets, fonts, and tiles) from remote HTTP servers.
        
        // By supplying our own implementation of this, we can implement our own custom
        // behaviors, including:
        //   - rewriting the `g://` URLs found in our map stylesheets with real URLs (using
        //     the information in mapSourcesV2.json)
        //   - checking if tiles have been downloaded already for offline use before getting
        //     them from the server.
        
        var url = URL(string: request.url)!
        
        // if URL starts with g://, rewrite it as an https:// URL
        if url.scheme == "g" {
            // FIXME lots of unsafe force-unwrapping here
            let key = String(url.host!)
            let mapSource = MapSourcesService.shared.sources[key]!
            let tileURLTemplate = mapSource.tileURL!
            let components = url.pathComponents.suffix(3).map { Int($0)! }
            let tileID = TileID(z: components[0], x: components[1], y: components[2])
            
            // check if tile is avaiable in offline downloads
            // TODO this should be abstracted into an OfflineTileStore or something
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
                    let response = HttpResponse(identifier: 0, //FIXME: what id to use
                                                request: request,
                                                result: .success(data))
                    continuation(HttpRequestOrResponse.fromHttpResponse(response))
                    
                }
            }
            
            // not in offline storage; prepare to request from tile servers
            url = tileURLTemplate.toURL(tile: tileID)
        }
        
        var urlRequest = URLRequest(url: url)
        let methodMap: [HttpMethod: String] = [
            .get: "GET",
            .head: "HEAD",
            .post: "POST"
        ]
        
        urlRequest.httpMethod          = methodMap[request.method]!
        urlRequest.httpBody            = request.body
        urlRequest.allHTTPHeaderFields = request.headers
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            let result: Result<HttpResponseData, HttpRequestError>
            
            if let error = error {
                // Map NSURLError to HttpRequestError
                let requestError = HttpRequestError(type: .otherError, message: error.localizedDescription)
                result = .failure(requestError)
            } else if let response = response as? HTTPURLResponse, let data = data {
                // store HTTP response headers in a dictionary
                var headers: [String: String] = [:]
                for (key, value) in response.allHeaderFields {
                    guard let key = key as? String, let value = value as? String else { continue }
                    
                    // Mapbox expects header names to be lowercase
                    headers[key.lowercased()] = value
                }
                
                // Create an HttpResponseData containing the headers dictionary, status code, and body
                let responseData = HttpResponseData(headers: headers, code: Int32(response.statusCode), data: data)
                result = .success(responseData)
            } else {
                let requestError = HttpRequestError(type: .otherError, message: "Invalid response")
                result = .failure(requestError)
            }
            
            let response = HttpResponse(identifier: 1, request: request, result: result)
            continuation(HttpRequestOrResponse.fromHttpResponse(response))
        }
        
        task.resume()
    }
    
    
    func onResponse(for response: HttpResponse, continuation: @escaping HttpServiceInterceptorResponseContinuation) {
        //
    }
}
    
 
