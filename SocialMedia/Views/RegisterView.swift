//
//  RegisterView.swift
//  SocialMedia
//
//  Created by Maliks on 21/09/2023.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct RegisterView: View {
    
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePictureData: Data?
    @State var showImagePicker: Bool = false
    @State var profilePhoto: PhotosPickerItem?
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                Text("Lets Register")
                    .font(.largeTitle.bold())
                    .hAlign(.leading)
                
                Text("Hello, Lets Set you up")
                    .font(.title3)
                    .hAlign(.leading)
                
                ViewThatFits {
                    ScrollView(.vertical, showsIndicators: false) {
                        HelperView()
                    }
                    HelperView()
                }
                
                HStack {
                    Text("Already have an Account?")
                        .foregroundColor(.gray)
                    
                    Button("Login Now") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                }
                .vAlign(.bottom)
            }
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $profilePhoto)
        .onChange(of: profilePhoto) { newValue in
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        await MainActor.run(body: {
                            userProfilePictureData = imageData
                        })
                    }
                    catch {
                        
                    }
                }
            }
        }
        .alert(self.errorMessage, isPresented: self.$showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            
            ZStack {
                if let userProfilePictureData, let image = UIImage(data: userProfilePictureData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                else {
                    Image("NullProfilePicture")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .padding(.top, 25)
            .onTapGesture {
                self.showImagePicker.toggle()
            }
            
            TextField("Username", text: self.$userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email Address", text: self.$emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Password", text: self.$password)
                .textContentType(.password)
                .border(1, .gray.opacity(0.5))
            
            TextField("About You", text: self.$userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: self.$userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            Button(action: self.registerUser) {
                
                Text("Sign Up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disablingWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePictureData == nil)
            .padding(.top, 10)
        }
    }
    
    func registerUser() {
        
        self.isLoading = true
        self.closeKeyboard()
        
        Task {
            do {
                // Create Firebase Account
                try await Auth.auth().createUser(withEmail: self.emailID, password: self.password)
                
                // Upload Profile photo info firebase storage
                guard let userID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = self.userProfilePictureData else { return }
                
                let storageRef = Storage.storage().reference().child("Profile_Image").child(userID)
                let _ = try await storageRef.putDataAsync(imageData)
                
                // Download Photo URL
                let downloadURL = try await storageRef.downloadURL()
                
                // Create a User Firestore Object
                let user = User(userName: self.userName, userBio: self.userBio, userBioLink: self.userBioLink, userUUID: userID, userEmail: self.emailID, userProfileURL: downloadURL)
                
                // Save User doc into Firebase datastore
                let _ = try Firestore.firestore().collection("Users").document(userID).setData(from: user, completion: { error in
                    if error == nil {
                        print("Saved Successfully")
                        self.userNameStored = userName
                        self.userUID = userID
                        self.profileURL = downloadURL
                        self.logStatus = true
                    }
                })
            }
            catch {
                // try await Auth.auth().currentUser?.delete()
                await self.setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            self.errorMessage = error.localizedDescription
            self.showError.toggle()
            self.isLoading = false
        })
    }
}

#Preview {
    RegisterView()
}
