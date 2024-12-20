import Foundation
import ParseSwift

@MainActor  // Add this to ensure all operations run on the main thread
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    init() {
        currentUser = User.current
    }
    
    func signUp(username: String, email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        var user = User()
        user.username = username
        user.email = email
        user.password = password
        user.fullName = fullName
        
        do {
            let signedUpUser = try await user.signup()
            self.currentUser = signedUpUser
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loggedInUser = try await User.login(username: username, password: password)
            self.currentUser = loggedInUser
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func signOut() async {
        do {
            try await User.logout()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        guard let currentUser = User.current else {
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            // Delete all family members associated with the user
            let query = FamilyMember.query("userId" == currentUser.objectId)
            let familyMembers = try await query.find()
            
            // Delete each family member using async/await properly
            try await withThrowingTaskGroup(of: Void.self) { group in
                for member in familyMembers {
                    group.addTask {
                        try await member.delete()
                    }
                }
                try await group.waitForAll()
            }
            
            // Delete the user account
            try await currentUser.delete()
            
            // Clear current user and sign out
            self.currentUser = nil
            try await User.logout()
            
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 
