import SwiftUI
import SwiftData

// MARK: - Events Tab (Calendar)

struct EventsTab: View {
    @Query private var pets: [Pet]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddEvent = false
    @State private var showPetPicker = false
    @State private var selectedPet: Pet?
    @State private var editingEvent: CareEvent?

    // All incomplete events across every pet, sorted by date
    private var allUpcoming: [(event: CareEvent, pet: Pet)] {
        pets.flatMap { pet in
            pet.careEvents
                .filter { !$0.isCompleted }
                .map { (event: $0, pet: pet) }
        }
        .sorted { $0.event.dueDate < $1.event.dueDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petBG.ignoresSafeArea()

                if allUpcoming.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 56))
                            .foregroundColor(.petBlue.opacity(0.3))
                        Text("No upcoming events")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.petTextMain)
                        Text("Tap + to schedule care for your pet")
                            .font(.subheadline)
                            .foregroundColor(.petTextMuted)
                    }
                } else {
                    List {
                        ForEach(allUpcoming, id: \.event.id) { pair in
                            Button { editingEvent = pair.event } label: {
                                EventRowWithPet(event: pair.event, pet: pair.pet)
                            }
                            .buttonStyle(.plain)
                            // Swipe left → mark complete
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    NotificationManager.cancel(id: pair.event.notificationID)
                                    pair.event.isCompleted = true
                                } label: {
                                    Label("Done", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                            // Swipe right → delete
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    NotificationManager.cancel(id: pair.event.notificationID)
                                    modelContext.delete(pair.event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.petBG)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if pets.count == 1 {
                            selectedPet = pets[0]
                            showAddEvent = true
                        } else {
                            showPetPicker = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(pets.isEmpty)
                }
            }
            // Multi-pet picker
            .confirmationDialog("Add event for…", isPresented: $showPetPicker, titleVisibility: .visible) {
                ForEach(pets) { pet in
                    Button(pet.name) {
                        selectedPet = pet
                        showAddEvent = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showAddEvent) {
                if let pet = selectedPet {
                    AddEventView(pet: pet)
                }
            }
            .sheet(item: $editingEvent) { event in
                AddEventView(existingEvent: event)
            }
        }
    }
}

// MARK: - Event Row with Pet Label

struct EventRowWithPet: View {
    let event: CareEvent
    let pet: Pet

    private var iconName: String {
        switch event.eventType {
        case "Vaccination": return "syringe"
        case "Grooming":    return "scissors"
        case "Medication":  return "pill.fill"
        case "Vet visit":   return "stethoscope"
        case "Walk":        return "figure.walk"
        default:            return "calendar"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.petIconBG)
                    .frame(width: 34, height: 34)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.petBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.petTextMain)
                Text(pet.name)
                    .font(.caption)
                    .foregroundColor(.petTextMuted)
            }

            Spacer()

            HStack(spacing: 6) {
                Text(event.dateLabel)
                    .font(.caption)
                    .foregroundColor(.petTextMuted)

                if event.urgency == .soon || event.urgency == .overdue {
                    Text(event.urgency == .overdue ? "Overdue" : "Soon")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.petBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.petIconBG)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(Color.petCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.petBorder, lineWidth: 0.5))
    }
}
