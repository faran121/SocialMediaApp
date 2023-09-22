//
//  SearchUserView.swift
//  SocialMedia
//
//  Created by Maliks on 22/09/2023.
//

import SwiftUI
import FirebaseFirestore

struct SearchUserView: View {
    
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(self.fetchedUsers) { user in
                NavigationLink {
                    ProfileContent(user: user)
                } label: {
                    Text(user.userName)
                        .font(.callout)
                        .hAlign(.leading)
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User")
        .searchable(text: self.$searchText)
        .onSubmit(of: .search, {
            Task { await self.searchUsers() }
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty {
                self.fetchedUsers = []
            }
        })
    }
    
    func searchUsers() async {
        do {
            
            let documents = try await Firestore.firestore().collection("Users").whereField("userName", isGreaterThanOrEqualTo: searchText).whereField("userName", isLessThanOrEqualTo: "\(searchText)\u{f8ff}").getDocuments()

            let users = try documents.documents.compactMap { doc -> User? in
                try doc.data(as: User.self)
            }
            
            await MainActor.run(body: {
                self.fetchedUsers = users
            })
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    SearchUserView()
}
