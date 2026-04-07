import SwiftUI
import SwiftData

// MARK: - Pet Model
// @Model tells SwiftData to save this to the phone automatically

@Model
class Pet {
    var name: String
    var breed: String
    var species: String
    var birthday: Date
    var gender: String
    var weightKg: Double
    var isMicrochipped: Bool
    var isNeutered: Bool
    var photoData: Data?           // stores the pet photo as raw bytes

    // One pet can have many care events
    @Relationship(deleteRule: .cascade)
    var careEvents: [CareEvent] = []

    init(
        name: String,
        breed: String,
        species: String = "Dog",
        birthday: Date,
        gender: String = "Male",
        weightKg: Double = 0,
        isMicrochipped: Bool = false,
        isNeutered: Bool = false
    ) {
        self.name = name
        self.breed = breed
        self.species = species
        self.birthday = birthday
        self.gender = gender
        self.weightKg = weightKg
        self.isMicrochipped = isMicrochipped
        self.isNeutered = isNeutered
    }

    // Calculates age from birthday automatically
    var ageInYears: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }

    // Short label like "3 years old"
    var ageLabel: String {
        let years = ageInYears
        return years == 1 ? "1 year old" : "\(years) years old"
    }
}

// MARK: - Care Event Model

@Model
class CareEvent {
    var name: String
    var eventType: String          // e.g. "Vaccination", "Grooming", "Vet visit"
    var notes: String
    var dueDate: Date
    var repeatInterval: RepeatInterval
    var reminderDaysBefore: Int
    var isCompleted: Bool
    var notificationID: String  // used to cancel/reschedule local notifications

    // Link back to the pet this event belongs to
    var pet: Pet?

    init(
        name: String,
        eventType: String,
        notes: String = "",
        dueDate: Date,
        repeatInterval: RepeatInterval = .never,
        reminderDaysBefore: Int = 1,
        isCompleted: Bool = false,
        notificationID: String = UUID().uuidString
    ) {
        self.name = name
        self.eventType = eventType
        self.notes = notes
        self.dueDate = dueDate
        self.repeatInterval = repeatInterval
        self.reminderDaysBefore = reminderDaysBefore
        self.isCompleted = isCompleted
        self.notificationID = notificationID
    }

    // How urgent is this event?
    var urgency: Urgency {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        if days < 0  { return .overdue }
        if days <= 2 { return .soon }
        if days <= 7 { return .upcoming }
        return .scheduled
    }

    // Friendly date label
    var dateLabel: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        switch days {
        case ..<0:   return "Overdue"
        case 0:      return "Today"
        case 1:      return "Tomorrow"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: dueDate)
        }
    }

    enum Urgency {
        case overdue, soon, upcoming, scheduled
    }
}

// MARK: - Repeat Interval

enum RepeatInterval: String, Codable, CaseIterable {
    case never       = "Never"
    case weekly      = "Every week"
    case monthly     = "Every month"
    case every3months = "Every 3 months"
    case every6months = "Every 6 months"
    case yearly      = "Every year"
}

// MARK: - Sample Data (for testing the app)

struct SampleData {
    static func insert(into context: ModelContext) {
        // Only insert if no pets exist yet
        let descriptor = FetchDescriptor<Pet>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        let buddy = Pet(
            name: "Buddy",
            breed: "Golden Retriever",
            species: "Dog",
            birthday: Calendar.current.date(byAdding: .year, value: -3, to: Date())!,
            gender: "Male",
            weightKg: 28,
            isMicrochipped: true,
            isNeutered: true
        )

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let inSixDays = Calendar.current.date(byAdding: .day, value: 6, to: Date())!
        let inNineDays = Calendar.current.date(byAdding: .day, value: 9, to: Date())!
        let inSixteenDays = Calendar.current.date(byAdding: .day, value: 16, to: Date())!

        let events: [CareEvent] = [
            CareEvent(name: "Vaccination booster", eventType: "Vaccination",
                      dueDate: tomorrow, repeatInterval: .yearly, reminderDaysBefore: 1),
            CareEvent(name: "Grooming appointment", eventType: "Grooming",
                      dueDate: inSixDays, repeatInterval: .every3months),
            CareEvent(name: "Anti-tick tablet",     eventType: "Medication",
                      dueDate: inNineDays, repeatInterval: .monthly),
            CareEvent(name: "Vet check-up",         eventType: "Vet visit",
                      dueDate: inSixteenDays, repeatInterval: .every6months),
        ]

        for event in events {
            event.pet = buddy
            buddy.careEvents.append(event)
            context.insert(event)
        }

        context.insert(buddy)
        try? context.save()
    }
}
