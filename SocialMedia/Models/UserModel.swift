//
//  UserModel.swift
//  SocialMedia
//
//  Created by Maliks on 20/09/2023.
//

import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var userName: String
    var userBio: String
    var userBioLink: String
    var userUUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id
        case userName
        case userBio
        case userBioLink
        case userUUID
        case userEmail
        case userProfileURL
    }
}
