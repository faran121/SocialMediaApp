//
//  SocialMediaApp.swift
//  SocialMedia
//
//  Created by Maliks on 18/09/2023.
//

import SwiftUI
import Firebase

@main
struct SocialMediaApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
