import Foundation
import ParseSwift

struct User: ParseUser {
    // Required by ParseUser protocol
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
    
    // Required by ParseObject protocol
    var originalData: Data?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    // Custom properties
    var fullName: String?
    var phoneNumber: String?
} 