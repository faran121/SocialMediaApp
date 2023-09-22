//
//  PostsView.swift
//  SocialMedia
//
//  Created by Maliks on 22/09/2023.
//

import SwiftUI

struct PostsView: View {
    
    @State private var recentPosts: [Post] = []
    @State private var createNewPost: Bool = false
    
    var body: some View {
        NavigationStack {
            PostView(posts: self.$recentPosts)
                .hAlign(.center)
                .vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        self.createNewPost.toggle()
                    } label: {
                         Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(13)
                            .background(.black, in: Circle())
                    }
                    .padding(15)
                }
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SearchUserView()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                })
                .navigationTitle("Posts")
        }
        .fullScreenCover(isPresented: self.$createNewPost, content: {
            CreatePostView { post in
                self.recentPosts.insert(post, at: 0)
            }
        })
    }
}

#Preview {
    PostsView()
}
