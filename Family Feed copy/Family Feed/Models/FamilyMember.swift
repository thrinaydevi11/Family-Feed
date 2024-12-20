import Foundation
import ParseSwift

struct FamilyMember: ParseObject {
    // Required by ParseObject protocol
    var originalData: Data?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    // Custom properties
    var name: String = ""
    var dateOfBirth: Date = Date()
    var relationship: String = ""
    var birthPlace: String = ""
    var birthChart: String?
    var importantDates: [ImportantDate]?
    var userId: String?
    
    // Custom keys
    static var className: String { "FamilyMember" }
    
    // Required init for ParseObject
    init() {
        self.userId = User.current?.objectId
    }
    
    // Custom initializer for creating copies
    init(copying member: FamilyMember) {
        self.originalData = member.originalData
        self.objectId = member.objectId
        self.createdAt = member.createdAt
        self.updatedAt = member.updatedAt
        self.ACL = member.ACL
        self.name = member.name
        self.dateOfBirth = member.dateOfBirth
        self.relationship = member.relationship
        self.birthPlace = member.birthPlace
        self.birthChart = member.birthChart
        self.importantDates = member.importantDates
        self.userId = member.userId
    }
}

// Make FamilyMember conform to Equatable
extension FamilyMember: Equatable {
    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        return lhs.objectId == rhs.objectId
    }
}

// Add helper methods for important dates
extension FamilyMember {
    mutating func addImportantDate(_ date: ImportantDate) {
        var dates = importantDates ?? []
        dates.append(date)
        importantDates = dates
    }
    
    mutating func removeImportantDate(_ date: ImportantDate) {
        importantDates?.removeAll { existingDate in
            existingDate.id == date.id
        }
    }
    
    func hasImportantDates() -> Bool {
        return !(importantDates?.isEmpty ?? true)
    }
    
    func getUpcomingDates(within days: Int = 30) -> [ImportantDate] {
        guard let dates = importantDates else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        let futureDate = calendar.date(byAdding: .day, value: days, to: today) ?? today
        
        return dates.filter { date in
            date.date >= today && date.date <= futureDate
        }.sorted { $0.date < $1.date }
    }
    
    func getDatesForCategory(_ category: DateCategory) -> [ImportantDate] {
        return importantDates?.filter { $0.category == category } ?? []
    }
} 