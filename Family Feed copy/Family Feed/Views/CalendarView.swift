import SwiftUI
import Foundation

struct CalendarView: View {
    let dates: [ImportantDate]
    let member: FamilyMember
    
    @Environment(\.calendar) var calendar
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            
            if let datesForSelectedDay = getDatesFor(selectedDate) {
                List(datesForSelectedDay) { date in
                    VStack(alignment: .leading) {
                        Text(date.description)
                            .font(.headline)
                        Text(date.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No events on this day")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("\(member.name)'s Calendar")
    }
    
    private func getDatesFor(_ date: Date) -> [ImportantDate]? {
        dates.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

#Preview {
    NavigationView {
        CalendarView(
            dates: [],
            member: FamilyMember()
        )
    }
} 