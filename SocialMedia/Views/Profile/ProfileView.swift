//
//  ProfileView.swift
//  SocialMedia
//
//  Created by Maliks on 21/09/2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    
    @State private var myProfile: User?
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile {
                    ProfileContent(user: myProfile)
                        .refreshable {
                            self.myProfile = nil
                            await self.fetchUserData()
                        }
                }
                else {
                    ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Logout", action: self.logOut)
                        Button("Delete Profile", role: .destructive, action: self.deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay {
                LoadingView(show: self.$isLoading)
            }
            .alert(self.errorMessage, isPresented: self.$showError) {}
            .task {
                if self.myProfile != nil { return }
                await self.fetchUserData()
            }
        }
    }
    
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else { return }
        
        await MainActor.run(body: {
            self.myProfile = user
        })
    }
    
    func logOut() {
        try? Auth.auth().signOut()
        self.logStatus = false
    }
    
    func deleteAccount() {
        self.isLoading = true
        
        Task {
            do {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                
                // Delete profile picture from storage
                let reference = Storage.storage().reference().child("Profile_Image").child(userID)
                try await reference.delete()
                
                // Delete firestore user document
                try await Firestore.firestore().collection("Users").document(userID).delete()
                
                // Delete log account and set log status to false
                try await Auth.auth().currentUser?.delete()
                self.logStatus = false
            } 
            catch {
                await self.setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError.toggle()
        })
    }
}

#Preview {
    ProfileView()
}
