//
//  LoginView.swift
//  SocialMedia
//
//  Created by Maliks on 18/09/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    
    @State var emailID: String = ""
    @State var password: String = ""
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome Back!")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Lets Sign you in")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 10) {
                TextField("Email Address", text: self.$emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 15)
                
                SecureField("Password", text: self.$password)
                    .textContentType(.password)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset Password?", action: self.resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                
                Button(action: self.loginUser) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)
            }
            
            HStack {
                Text("Don't have an Account?")
                    .foregroundColor(.gray)
                
                Button("Register Now") {
                    self.createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: self.$isLoading)
        })
        .fullScreenCover(isPresented: $createAccount, content: {
            RegisterView()
        })
        .alert(self.errorMessage, isPresented: self.$showError, actions: {})
    }
    
    func loginUser() {
        
        self.isLoading = true
        self.closeKeyboard()
        
        Task {
            do {
                try await Auth.auth().signIn(withEmail: self.emailID, password: self.password)
                try await self.fetchUser()
            }
            catch {
                await setError(error)
            }
        }
    }
    
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        
        await MainActor.run(body: {
            userUID = userID
            userNameStored = user.userName
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    func resetPassword() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: self.emailID)
            }
            catch {
                await setError(error)
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
