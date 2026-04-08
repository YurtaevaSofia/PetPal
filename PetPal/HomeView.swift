import SwiftUI
import SwiftData

// MARK: - Colour Theme

extension Color {
    static let petBlue       = Color(red: 0.23, green: 0.36, blue: 0.96)
    static let petBlueDark   = Color(red: 0.42, green: 0.23, blue: 0.96)
    static let petBG         = Color(red: 0.94, green: 0.96, blue: 1.00)
    static let petCard       = Color.white
    static let petBorder     = Color(red: 0.87, green: 0.89, blue: 0.97)
    static let petIconBG     = Color(red: 0.91, green: 0.93, blue: 1.00)
    static let petTextMain   = Color(red: 0.10, green: 0.12, blue: 0.24)
    static let petTextMuted  = Color(red: 0.48, green: 0.54, blue: 0.76)
}

// MARK: - Home View

struct HomeView: View {

    // @Query fetches all pets from the phone's database automatically
    @Query private var pets: [Pet]

    // Environment gives us access to the database context
    @Environment(\.modelContext) private var modelContext

    // The first pet, or nil if none added yet
    private var currentPet: Pet? { pets.first }

    // Only show upcoming (not completed) events, sorted by date
    private var upcomingEvents: [CareEvent] {
        guard let pet = currentPet else { return [] }
        return pet.careEvents
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petBG.ignoresSafeArea()

                if let pet = currentPet {
                    // ── Main content when we have a pet ──────────────
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            // Greeting
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greetingText)
                                    .font(.title2.weight(.medium))
                                    .foregroundColor(.petTextMain)

                                Text("Here's what's ahead for \(pet.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.petTextMuted)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            // Pet hero card
                            PetHeroCard(pet: pet)
                                .padding(.horizontal)

                            // Upcoming care events
                            if !upcomingEvents.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("UPCOMING CARE")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.petTextMuted)
                                        .kerning(0.8)
                                        .padding(.horizontal)

                                    VStack(spacing: 8) {
                                        ForEach(upcomingEvents) { event in
                                            EventRow(event: event, onComplete: {
                                                NotificationManager.cancel(id: event.notificationID)
                                                event.isCompleted = true
                                            })
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                EmptyEventsView()
                                    .padding(.horizontal)
                            }

                            // Age-based tip
                            TipCard(pet: pet)
                                .padding(.horizontal)

                            Spacer(minLength: 20)
                        }
                        .padding(.bottom, 80)
                    }

                } else {
                    // ── Empty state: no pets added yet ───────────────
                    NoPetView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Insert sample data on first launch so the app isn't empty
            SampleData.insert(into: modelContext)
        }
    }

    // Time-of-day greeting
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }
}

// MARK: - Pet Hero Card

struct PetHeroCard: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: 14) {
            // Avatar — shows photo if available, paw icon otherwise
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 58, height: 58)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 2))

                if let data = pet.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(pet.breed)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))

                Text(pet.ageLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(16)
        .background(
            Group {
                if let data = pet.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 24, opaque: true)
                        .overlay(Color.black.opacity(0.35))
                } else {
                    LinearGradient(colors: [.petBlue, .petBlueDark],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
        )
        .cornerRadius(16)
        .clipped()
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CareEvent
    var onComplete: (() -> Void)? = nil

    private var iconName: String {
        switch event.eventType {
        case "Vaccination": return "syringe"
        case "Grooming":    return "scissors"
        case "Medication":  return "pill.fill"
        case "Vet visit":   return "stethoscope"
        default:            return "calendar"
        }
    }

    private var isOverdue: Bool { event.urgency == .overdue }

    var body: some View {
        HStack(spacing: 10) {
            // Completion checkbox
            Button {
                onComplete?()
            } label: {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(event.isCompleted ? .petBlue : (isOverdue ? .orange : .petTextMuted))
            }
            .buttonStyle(.plain)

            // Icon box
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOverdue ? Color.orange.opacity(0.12) : Color.petIconBG)
                    .frame(width: 34, height: 34)

                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(isOverdue ? .orange : .petBlue)
            }

            Text(event.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.petTextMain)

            Spacer()

            HStack(spacing: 6) {
                Text(event.dateLabel)
                    .font(.caption)
                    .foregroundColor(isOverdue ? .orange : .petTextMuted)

                if event.urgency == .soon || event.urgency == .overdue {
                    Text(event.urgency == .overdue ? "Overdue" : "Soon")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(isOverdue ? .orange : .petBlue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isOverdue ? Color.orange.opacity(0.12) : Color.petIconBG)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(isOverdue ? Color(red: 1.0, green: 0.96, blue: 0.92) : Color.petCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isOverdue ? Color.orange.opacity(0.5) : Color.petBorder,
                              lineWidth: isOverdue ? 1.0 : 0.5)
        )
    }
}

// MARK: - Tip Card

struct TipCard: View {
    let pet: Pet

    private var tip: String {
        switch pet.ageInYears {
        case 0...1:
            return "Puppies need short walks and lots of play. Avoid hard surfaces on growing joints."
        case 2...5:
            return "\(pet.breed)s need 45–60 min of exercise daily. A great time to build on leash training!"
        case 6...9:
            return "Your dog is entering middle age. Watch for joint stiffness after walks."
        default:
            return "Senior dogs benefit from gentle, shorter walks. Vet check-ups every 6 months are key."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tip · \(pet.ageLabel)")
                .font(.caption.weight(.medium))
                .foregroundColor(Color(red: 0.16, green: 0.24, blue: 0.69))

            Text(tip)
                .font(.caption)
                .foregroundColor(.petBlue)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color.petIconBG)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(red: 0.77, green: 0.82, blue: 0.98), lineWidth: 0.5)
        )
    }
}

// MARK: - Empty states

struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.petBlue.opacity(0.4))
            Text("No upcoming events")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.petTextMuted)
            Text("Tap the Calendar tab to add care events")
                .font(.caption)
                .foregroundColor(.petTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.petCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.petBorder, lineWidth: 0.5))
    }
}

struct NoPetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.petBlue.opacity(0.3))
            Text("No pets yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.petTextMain)
            Text("Go to the Pets tab to add your first pet")
                .font(.subheadline)
                .foregroundColor(.petTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [Pet.self, CareEvent.self], inMemory: true)
}
