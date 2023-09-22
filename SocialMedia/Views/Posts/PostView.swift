//
//  PostView.swift
//  SocialMedia
//
//  Created by Maliks on 22/09/2023.
//

import SwiftUI
import FirebaseFirestore

struct PostView: View {
    
    var basedOnUID: Bool = false
    var uid: String = ""
    
    @Binding var posts: [Post]
    
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if self.isFetching {
                    ProgressView()
                }
                else {
                    if self.posts.isEmpty {
                        Text("No Posts Found")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    }
                    else {
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            guard !basedOnUID else { return }
            
            self.isFetching = true
            self.posts = []
            self.paginationDoc = nil
            await self.fetchPosts()
        }
        .task {
            guard posts.isEmpty else { return }
            await fetchPosts()
        }
    }
    
    @ViewBuilder
    func Posts() -> some View {
        ForEach(self.posts) { post in
            PostCardView(post: post) { updatedPost in
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    posts.removeAll{ post.id == $0.id }
                }
            }
            .onAppear {
                if post.id == posts.last?.id && paginationDoc != nil {
                    Task { await self.fetchPosts() }
                }
            }
            
            Divider()
                .padding(.horizontal, -15)
        }
    }
    
    func fetchPosts() async {
        do {
            var query: Query!
            
            if let paginationDoc {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 5)
            }
            else {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 5)
            }
            
            if basedOnUID {
                query = query
                    .whereField("userUUID", isEqualTo: self.uid)
            }
                        
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
                        
            await MainActor.run(body: {
                self.posts.append(contentsOf: fetchedPosts)
                self.paginationDoc = docs.documents.last
                self.isFetching = false
            })
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
