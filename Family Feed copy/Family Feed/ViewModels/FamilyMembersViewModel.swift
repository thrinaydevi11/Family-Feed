import Foundation
import ParseSwift
import UIKit

@MainActor
class FamilyMembersViewModel: ObservableObject {
    @Published var familyMembers: [FamilyMember] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOption = SortOption.name
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case relationship = "Relationship"
        case age = "Age"
        
        var comparator: (FamilyMember, FamilyMember) -> Bool {
            switch self {
            case .name:
                return { $0.name < $1.name }
            case .relationship:
                return { $0.relationship < $1.relationship }
            case .age:
                return { $0.dateOfBirth > $1.dateOfBirth }
            }
        }
    }
    
    var filteredAndSortedMembers: [FamilyMember] {
        let filtered = searchText.isEmpty ? familyMembers : familyMembers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.relationship.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.sorted(by: sortOption.comparator)
    }
    
    func deleteMember(_ member: FamilyMember) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let objectId = member.objectId else {
            await MainActor.run {
                errorMessage = "Member not found"
                isLoading = false
            }
            return
        }
        
        do {
            let query = FamilyMember.query("objectId" == objectId)
            let result: FamilyMember? = try await query.first()
            
            if let existingMember = result {
                try await existingMember.delete()
                await MainActor.run {
                    familyMembers.removeAll { $0.objectId == objectId }
                    errorMessage = nil
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Member not found in database"
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Delete failed: \(error.localizedDescription)"
                print("Delete error: \(error)")
                isLoading = false
            }
        }
    }
    
    func updateMember(_ member: FamilyMember) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let objectId = member.objectId else {
            await MainActor.run {
                errorMessage = "Member not found"
                isLoading = false
            }
            return
        }
        
        do {
            let query = FamilyMember.query("objectId" == objectId)
            let result: FamilyMember? = try await query.first()
            
            if let existingMember = result {
                var updatedMember = existingMember
                updatedMember.name = member.name
                updatedMember.relationship = member.relationship
                updatedMember.dateOfBirth = member.dateOfBirth
                updatedMember.birthPlace = member.birthPlace
                updatedMember.birthChart = member.birthChart
                updatedMember.importantDates = member.importantDates
                
                let saved = try await updatedMember.save()
                
                await MainActor.run {
                    if let index = familyMembers.firstIndex(where: { $0.objectId == objectId }) {
                        familyMembers[index] = saved
                    }
                    errorMessage = nil
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Member not found in database"
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Update failed: \(error.localizedDescription)"
                print("Update error: \(error)")
                isLoading = false
            }
        }
    }
    
    func fetchFamilyMembers() {
        Task(priority: .userInitiated) {  // Set high priority for user-facing tasks
            isLoading = true
            
            guard let currentUserId = User.current?.objectId else {
                self.errorMessage = "No user logged in"
                isLoading = false
                return
            }
            
            do {
                let query = FamilyMember.query("userId" == currentUserId)
                let members = try await query.find()
                
                await MainActor.run {
                    self.familyMembers = members
                    self.errorMessage = nil
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func addFamilyMember(name: String, dateOfBirth: Date, relationship: String, birthPlace: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let currentUser = User.current else {
            await MainActor.run {
                errorMessage = "No user logged in"
                isLoading = false
            }
            return
        }
        
        var member = FamilyMember()
        member.name = name
        member.dateOfBirth = dateOfBirth
        member.relationship = relationship
        member.birthPlace = birthPlace
        member.userId = currentUser.objectId
        
        var acl = ParseACL()
        acl.publicRead = false
        acl.publicWrite = false
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)
        member.ACL = acl
        
        do {
            let savedMember = try await member.save()
            
            await MainActor.run {
                self.familyMembers.append(savedMember)
                self.errorMessage = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add member: \(error.localizedDescription)"
                self.isLoading = false
                print("Add member error: \(error)")
            }
        }
    }
    
    func uploadBirthChart(for member: FamilyMember, image: UIImage) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            await MainActor.run {
                errorMessage = "Failed to process image"
                isLoading = false
            }
            return
        }
        
        let fileSizeInMB = Double(imageData.count) / 1_000_000
        if fileSizeInMB > 10 {
            await MainActor.run {
                errorMessage = "Image is too large. Please choose a smaller image."
                isLoading = false
            }
            return
        }
        
        let fileName = "\(member.objectId ?? UUID().uuidString)_birthchart.jpg"
        let parseFile = ParseFile(name: fileName, data: imageData)
        
        do {
            let savedFile = try await withTimeout(seconds: 30) {
                try await parseFile.save()
            }
            
            var updatedMember = member
            updatedMember.birthChart = savedFile.url?.absoluteString
            
            let saved = try await withTimeout(seconds: 15) {
                try await updatedMember.save()
            }
            
            await MainActor.run {
                if let index = self.familyMembers.firstIndex(where: { $0.objectId == saved.objectId }) {
                    self.familyMembers[index] = saved
                }
                self.errorMessage = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                if let timeoutError = error as? TimeoutError {
                    self.errorMessage = "Upload timed out. Please try again with a smaller image or check your connection."
                    print("Timeout error: \(timeoutError)")
                } else {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                    print("Upload error: \(error)")
                }
                self.isLoading = false
            }
        }
    }
    
    func addImportantDate(to member: FamilyMember, date: ImportantDate) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var updatedMember = member
        updatedMember.addImportantDate(date)
        await updateMember(updatedMember)
    }
    
    func removeImportantDate(from member: FamilyMember, date: ImportantDate) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var updatedMember = member
        updatedMember.removeImportantDate(date)
        await updateMember(updatedMember)
    }
    
    func getUpcomingDates() -> [(FamilyMember, [ImportantDate])] {
        return familyMembers.compactMap { member in
            let dates = member.getUpcomingDates()
            return dates.isEmpty ? nil : (member, dates)
        }
    }
    
    func updateBirthChart(for member: FamilyMember, image: UIImage) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // First delete the existing birth chart if it exists
        if member.birthChart != nil {
            var updatedMember = member
            updatedMember.birthChart = nil
            await updateMember(updatedMember)
        }
        
        // Then upload the new birth chart
        await uploadBirthChart(for: member, image: image)
    }
}

// Helper for timeout
struct TimeoutError: Error {}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

