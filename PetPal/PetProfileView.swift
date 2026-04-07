import SwiftUI
import SwiftData

// MARK: - Pet Profile View

struct PetProfileView: View {
    let pet: Pet
    @Environment(\.modelContext) private var modelContext
    @State private var showAddEvent = false
    @State private var showEditPet = false
    @State private var editingEvent: CareEvent?

    private var upcomingEvents: [CareEvent] {
        pet.careEvents
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var completedEvents: [CareEvent] {
        pet.careEvents
            .filter { $0.isCompleted }
            .sorted { $0.dueDate > $1.dueDate }
    }

    var body: some View {
        ZStack {
            Color.petBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderCard(pet: pet)
                        .padding(.horizontal)

                    StatsGrid(pet: pet)
                        .padding(.horizontal)

                    // Care events section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CARE EVENTS")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.petTextMuted)
                                .kerning(0.8)

                            Spacer()

                            Button {
                                showAddEvent = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.petBlue)
                            }
                        }
                        .padding(.horizontal)

                        if upcomingEvents.isEmpty && completedEvents.isEmpty {
                            EmptyEventsView()
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(upcomingEvents) { event in
                                    // Tap to edit
                                    Button { editingEvent = event } label: {
                                        EventRow(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            NotificationManager.cancel(id: event.notificationID)
                                            event.isCompleted = true
                                        } label: {
                                            Label("Mark Complete", systemImage: "checkmark.circle")
                                        }
                                        Button(role: .destructive) {
                                            NotificationManager.cancel(id: event.notificationID)
                                            modelContext.delete(event)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }

                                if !completedEvents.isEmpty {
                                    Text("COMPLETED")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.petTextMuted)
                                        .kerning(0.8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 4)

                                    ForEach(completedEvents) { event in
                                        CompletedEventRow(event: event)
                                            .contextMenu {
                                                Button {
                                                    event.isCompleted = false
                                                    NotificationManager.schedule(for: event, petName: pet.name)
                                                } label: {
                                                    Label("Mark Incomplete", systemImage: "arrow.uturn.left.circle")
                                                }
                                                Button(role: .destructive) {
                                                    modelContext.delete(event)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.vertical)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEditPet = true }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView(pet: pet)
        }
        .sheet(isPresented: $showEditPet) {
            AddPetView(existingPet: pet)
        }
        .sheet(item: $editingEvent) { event in
            AddEventView(existingEvent: event)
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 2))

                if let data = pet.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Text("\(pet.breed) · \(pet.species)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))

                Text(pet.ageLabel)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(colors: [.petBlue, .petBlueDark],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(18)
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let pet: Pet

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            StatTile(icon: "scalemass.fill",
                     label: "Weight",
                     value: String(format: "%.1f kg", pet.weightKg))
            StatTile(icon: pet.gender == "Male" ? "mars" : "venus",
                     label: "Gender",
                     value: pet.gender)
            StatTile(icon: "cpu",
                     label: "Microchip",
                     value: pet.isMicrochipped ? "Yes" : "No")
            StatTile(icon: "bandage",
                     label: "Neutered",
                     value: pet.isNeutered ? "Yes" : "No")
        }
    }
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.petIconBG)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.petBlue)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.petTextMuted)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.petTextMain)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.petCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.petBorder, lineWidth: 0.5))
    }
}

// MARK: - Completed Event Row

struct CompletedEventRow: View {
    let event: CareEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.petBlue.opacity(0.4))
                .font(.system(size: 18))

            Text(event.name)
                .font(.subheadline)
                .foregroundColor(.petTextMuted)
                .strikethrough(true, color: .petTextMuted)

            Spacer()
        }
        .padding(12)
        .background(Color.petCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.petBorder, lineWidth: 0.5))
    }
}
