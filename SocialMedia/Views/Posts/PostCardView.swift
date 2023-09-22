//
//  PostCardView.swift
//  SocialMedia
//
//  Created by Maliks on 22/09/2023.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage

struct PostCardView: View {
    
    var post: Post
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    @State private var docListener: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: self.post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(self.post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Text(self.post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(self.post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            if self.post.userUID == self.userUID {
                Menu {
                    Button("Delete Post", role: .destructive, action: self.deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            if self.docListener == nil {
                guard let postID = self.post.id else { return }
                
                self.docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            if let updatedPost = try? snapshot.data(as: Post.self) {
                                onUpdate(updatedPost)
                            }
                        }
                        else {
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear {
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button(action: self.likePost) {
                Image(systemName: post.likedIDs.contains(self.userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            
            Text("\(self.post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: self.dislikePost) {
                Image(systemName: post.dislikedIDs.contains(self.userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading, 25)
            
            Text("\(self.post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    
    func likePost() {
        Task {
            guard let postID = self.post.id else { return }
            
            if self.post.likedIDs.contains(self.userUID) {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([self.userUID])
                ])
            }
            else {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([self.userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([self.userUID])
                ])
            }
        }
    }
    
    func dislikePost() {
        Task {
            guard let postID = self.post.id else { return }
            
            if self.post.dislikedIDs.contains(self.userUID) {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([self.userUID])
                ])
            }
            else {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([self.userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([self.userUID])
                ])
            }
        }
    }
    
    func deletePost() {
        Task {
            do {
                // Delete Image from firebase storage
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("Post_Images").child(self.post.imageReferenceID).delete()
                }
                
                // Delete Firestore document
                guard let postID = self.post.id else { return }
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}

