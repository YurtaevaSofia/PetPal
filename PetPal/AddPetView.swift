import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Add / Edit Pet View

struct AddPetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingPet: Pet?

    @State private var name: String
    @State private var breed: String
    @State private var species: String
    @State private var birthday: Date
    @State private var gender: String
    @State private var weightKg: Double
    @State private var isMicrochipped: Bool
    @State private var isNeutered: Bool
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    private let speciesOptions = ["Dog", "Cat", "Rabbit", "Bird", "Hamster", "Other"]
    private let genderOptions = ["Male", "Female"]

    // MARK: Inits

    /// Create a new pet.
    init() {
        existingPet = nil
        _name = State(initialValue: "")
        _breed = State(initialValue: "")
        _species = State(initialValue: "Dog")
        _birthday = State(initialValue: Date())
        _gender = State(initialValue: "Male")
        _weightKg = State(initialValue: 0.0)
        _isMicrochipped = State(initialValue: false)
        _isNeutered = State(initialValue: false)
        _photoData = State(initialValue: nil)
    }

    /// Edit an existing pet (pre-populated).
    init(existingPet: Pet) {
        self.existingPet = existingPet
        _name = State(initialValue: existingPet.name)
        _breed = State(initialValue: existingPet.breed)
        _species = State(initialValue: existingPet.species)
        _birthday = State(initialValue: existingPet.birthday)
        _gender = State(initialValue: existingPet.gender)
        _weightKg = State(initialValue: existingPet.weightKg)
        _isMicrochipped = State(initialValue: existingPet.isMicrochipped)
        _isNeutered = State(initialValue: existingPet.isNeutered)
        _photoData = State(initialValue: existingPet.photoData)
    }

    private var isEditing: Bool { existingPet != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !breed.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petBG.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color.petIconBG)
                                    .frame(width: 90, height: 90)
                                    .overlay(Circle().strokeBorder(Color.petBorder, lineWidth: 1.5))

                                if let photoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.petBlue)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundColor(.petTextMuted)
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                photoData = try? await item?.loadTransferable(type: Data.self)
                            }
                        }
                        .padding(.top, 8)

                        // Basic info
                        FormSection(title: "Basic Info") {
                            FormField(label: "Name") {
                                TextField("e.g. Buddy", text: $name)
                                    .multilineTextAlignment(.trailing)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Breed") {
                                TextField("e.g. Golden Retriever", text: $breed)
                                    .multilineTextAlignment(.trailing)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Species") {
                                Picker("Species", selection: $species) {
                                    ForEach(speciesOptions, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(.petBlue)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Gender") {
                                Picker("Gender", selection: $gender) {
                                    ForEach(genderOptions, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .tint(.petBlue)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Birthday") {
                                DatePicker("", selection: $birthday, in: ...Date(),
                                           displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.petBlue)
                            }
                        }

                        // Health
                        FormSection(title: "Health") {
                            FormField(label: "Weight (kg)") {
                                TextField("0.0", value: $weightKg, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Microchipped") {
                                Toggle("", isOn: $isMicrochipped).tint(.petBlue)
                            }
                            Divider().padding(.horizontal)
                            FormField(label: "Neutered / Spayed") {
                                Toggle("", isOn: $isNeutered).tint(.petBlue)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "Edit Pet" : "Add Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePet()
                        dismiss()
                    }
                    .font(.headline)
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: Save

    private func savePet() {
        if let pet = existingPet {
            // Update in place — SwiftData observes the changes automatically
            pet.name = name.trimmingCharacters(in: .whitespaces)
            pet.breed = breed.trimmingCharacters(in: .whitespaces)
            pet.species = species
            pet.birthday = birthday
            pet.gender = gender
            pet.weightKg = weightKg
            pet.isMicrochipped = isMicrochipped
            pet.isNeutered = isNeutered
            pet.photoData = photoData
        } else {
            let pet = Pet(
                name: name.trimmingCharacters(in: .whitespaces),
                breed: breed.trimmingCharacters(in: .whitespaces),
                species: species,
                birthday: birthday,
                gender: gender,
                weightKg: weightKg,
                isMicrochipped: isMicrochipped,
                isNeutered: isNeutered
            )
            pet.photoData = photoData
            modelContext.insert(pet)
        }
    }
}

// MARK: - Reusable Form Components

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.medium))
                .foregroundColor(.petTextMuted)
                .kerning(0.8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.petCard)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.petBorder, lineWidth: 0.5))
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.petTextMain)
            Spacer()
            content()
                .font(.subheadline)
                .foregroundColor(.petTextMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}
