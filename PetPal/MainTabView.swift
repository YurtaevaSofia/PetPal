import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            PetsTab()
                .tabItem { Label("Pets", systemImage: "pawprint.fill") }

            EventsTab()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .tint(.petBlue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Pet.self, CareEvent.self], inMemory: true)
}
