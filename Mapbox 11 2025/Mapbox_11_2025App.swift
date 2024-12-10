//
//  Mapbox_11_2025App.swift
//  Mapbox 11 2025
//
//  Created by Jim Margolis on 12/9/24.
//

import SwiftUI
import MapboxMaps

@main
struct Mapbox_11_2025App: App {
    init() {
        let interceptor = CustomHttpService()
        HttpServiceFactory.setHttpServiceInterceptorForInterceptor(interceptor)
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
