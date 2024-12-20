import SwiftUI
import UserNotifications

struct AddImportantDateView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var member: FamilyMember
    let viewModel: FamilyMembersViewModel
    
    @State private var title = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory: DateCategory = .other
    @State private var reminderEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DateCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: ImportantDate(date: Date(), description: "", category: category, reminder: false).iconName)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                }
            }
            .navigationTitle("Add Important Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDate()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addDate() {
        let newDate = ImportantDate(
            date: selectedDate,
            description: title,
            category: selectedCategory,
            reminder: reminderEnabled
        )
        
        Task {
            var updatedMember = member
            var dates = updatedMember.importantDates ?? []
            dates.append(newDate)
            updatedMember.importantDates = dates
            
            if reminderEnabled {
                scheduleReminder(for: newDate)
            }
            
            await viewModel.updateMember(updatedMember)
            dismiss()
        }
    }
    
    private func scheduleReminder(for date: ImportantDate) {
        let content = UNMutableNotificationContent()
        content.title = date.description
        content.body = "Important date for \(member.name)"
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: date.id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 