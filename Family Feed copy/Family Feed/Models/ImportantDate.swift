import Foundation

enum DateCategory: String, Codable, CaseIterable {
    case birthday = "Birthday"
    case anniversary = "Anniversary"
    case graduation = "Graduation"
    case wedding = "Wedding"
    case memorial = "Memorial"
    case holiday = "Holiday"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .birthday: return "gift.fill"
        case .anniversary: return "heart.fill"
        case .graduation: return "graduationcap.fill"
        case .wedding: return "heart.circle.fill"
        case .memorial: return "star.fill"
        case .holiday: return "calendar.badge.clock"
        case .other: return "calendar"
        }
    }
}

struct ImportantDate: Codable, Equatable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(description)" }
    var date: Date
    var description: String
    var category: DateCategory
    var reminder: Bool
    
    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }
    
    var iconName: String {
        category.iconName
    }
} 