import SwiftUI
import ParseSwift

@main
struct FamilyFeedApp: App {
    init() {
        initializeParse()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func initializeParse() {
        ParseSwift.initialize(
            applicationId: "6hrmC25B1G171q4O7NhQ1RzTUttYG6OEBPSaT9GI",
            clientKey: "LEerxXnORaTcxtz8iAiBnA4Z4DJUVTcYd8hEcNE8",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
        print("Parse initialized successfully")
    }
} 
