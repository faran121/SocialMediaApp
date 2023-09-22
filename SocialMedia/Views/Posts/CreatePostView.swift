//
//  CreatePostView.swift
//  SocialMedia
//
//  Created by Maliks on 21/09/2023.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct CreatePostView: View {
    
    var onPost: (Post) -> ()
    
    @State private var postText: String = ""
    @State private var postImageData: Data?
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    
    @FocusState private var showKeyboard: Bool
    
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .hAlign(.leading)
                
                Button(action: self.createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black, in: Capsule())
                }
                .disablingWithOpacity(self.postText == "")
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.black.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("What's Happening?", text: self.$postText, axis: .vertical)
                        .focused(self.$showKeyboard)
                    
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader {
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            
            Divider()
            
            HStack {
                Button {
                    self.showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done") {
                    self.showKeyboard = false
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .foregroundColor(.black)
        }
        .vAlign(.top)
        .photosPicker(isPresented: self.$showImagePicker, selection: self.$photoItem)
        .onChange(of: self.photoItem) { newValue in
            if let newValue {
                Task {
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        await MainActor.run(body: {
                            self.postImageData = compressedImageData
                            self.photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(self.errorMessage, isPresented: self.$showError, actions: {})
        .overlay {
            LoadingView(show: self.$isLoading)
        }
    }
    
    func createPost() {
        self.isLoading = true
        self.showKeyboard = false
        
        Task {
            do {
                guard let profileURL = self.profileURL else { return }
                
                // Upload Image if any
                let imageReferenceID = "\(self.userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                
                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    // Create post object with image ID and URL
                    let post = Post(text: self.postText, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: self.userName, userUID: self.userUID, userProfileURL: profileURL)
                    
                    try await createDocumentAtFirebase(post)
                }
                else {
                    // Post Text data
                    let post = Post(text: self.postText, userName: self.userName, userUID: self.userUID, userProfileURL: profileURL)
                    
                    try await createDocumentAtFirebase(post)
                }
            }
            catch {
                await setError(error)
            }
        }
    }
    
    func createDocumentAtFirebase(_ post: Post) async throws {
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: { error in
            if error == nil {
                isLoading = false
                
                var updatedPost = post
                updatedPost.id = doc.documentID
                
                onPost(updatedPost)
                dismiss()
            }
        })
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            self.errorMessage = error.localizedDescription
            self.showError.toggle()
        })
    }
}

#Preview {
    CreatePostView { _ in
        
    }
}
