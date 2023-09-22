//
//  MainView.swift
//  SocialMedia
//
//  Created by Maliks on 21/09/2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Posts")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
        }
        .tint(.black)
    }
}

#Preview {
    MainView()
}
