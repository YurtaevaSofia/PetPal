import SwiftUI
import SwiftData

// MARK: - Add / Edit Event View

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let pet: Pet
    private let existingEvent: CareEvent?

    @State private var name: String
    @State private var eventType: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var repeatInterval: RepeatInterval
    @State private var reminderDaysBefore: Int

    private let eventTypes = ["Vet visit", "Vaccination", "Grooming", "Medication", "Walk", "Other"]
    private let reminderOptions = [0, 1, 2, 3, 7, 14]

    // MARK: Inits

    /// Create a new event for a pet.
    init(pet: Pet) {
        self.pet = pet
        self.existingEvent = nil
        _name = State(initialValue: "")
        _eventType = State(initialValue: "Vet visit")
        _notes = State(initialValue: "")
        _dueDate = State(initialValue: Date())
        _repeatInterval = State(initialValue: .never)
        _reminderDaysBefore = State(initialValue: 1)
    }

    /// Edit an existing event (pre-populated). Pet is derived from the event.
    init(existingEvent: CareEvent) {
        self.existingEvent = existingEvent
        guard let linkedPet = existingEvent.pet else {
            fatalError("CareEvent has no linked pet — data integrity violation")
        }
        self.pet = linkedPet
        _name = State(initialValue: existingEvent.name)
        _eventType = State(initialValue: existingEvent.eventType)
        _notes = State(initialValue: existingEvent.notes)
        _dueDate = State(initialValue: existingEvent.dueDate)
        _repeatInterval = State(initialValue: existingEvent.repeatInterval)
        _reminderDaysBefore = State(initialValue: existingEvent.reminderDaysBefore)
    }

    private var isEditing: Bool { existingEvent != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petBG.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Pet context banner
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.petIconBG)
                                    .frame(width: 34, height: 34)

                                if let data = pet.photoData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 34, height: 34)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.petBlue)
                                }
                            }

                            Text(isEditing ? "Editing event for **\(pet.name)**" : "Adding event for **\(pet.name)**")
                                .font(.subheadline)
                                .foregroundColor(.petTextMuted)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.petCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.petBorder, lineWidth: 0.5))

                        // Event details
                        FormSection(title: "Event Details") {
                            FormField(label: "Name") {
                                TextField("e.g. Vaccination booster", text: $name)
                                    .multilineTextAlignment(.trailing)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Type") {
                                Picker("Type", selection: $eventType) {
                                    ForEach(eventTypes, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(.petBlue)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Due Date") {
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.petBlue)
                            }
                        }

                        // Repeat & reminder
                        FormSection(title: "Repeat & Reminder") {
                            FormField(label: "Repeat") {
                                Picker("Repeat", selection: $repeatInterval) {
                                    ForEach(RepeatInterval.allCases, id: \.self) {
                                        Text($0.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.petBlue)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Remind me") {
                                Picker("Reminder", selection: $reminderDaysBefore) {
                                    ForEach(reminderOptions, id: \.self) { days in
                                        Text(days == 0 ? "On the day" : "\(days) day\(days == 1 ? "" : "s") before")
                                            .tag(days)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.petBlue)
                            }
                        }

                        // Notes
                        FormSection(title: "Notes") {
                            TextField("Add any notes (optional)…", text: $notes, axis: .vertical)
                                .font(.subheadline)
                                .foregroundColor(.petTextMain)
                                .padding(14)
                                .lineLimit(3...8)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                        dismiss()
                    }
                    .font(.headline)
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: Save

    private func saveEvent() {
        if let event = existingEvent {
            // Update in place
            event.name = name.trimmingCharacters(in: .whitespaces)
            event.eventType = eventType
            event.notes = notes
            event.dueDate = dueDate
            event.repeatInterval = repeatInterval
            event.reminderDaysBefore = reminderDaysBefore
            NotificationManager.schedule(for: event, petName: pet.name)
        } else {
            let event = CareEvent(
                name: name.trimmingCharacters(in: .whitespaces),
                eventType: eventType,
                notes: notes,
                dueDate: dueDate,
                repeatInterval: repeatInterval,
                reminderDaysBefore: reminderDaysBefore
            )
            event.pet = pet
            pet.careEvents.append(event)
            modelContext.insert(event)
            NotificationManager.schedule(for: event, petName: pet.name)
        }
    }
}
