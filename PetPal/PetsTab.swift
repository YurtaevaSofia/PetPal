import SwiftUI
import SwiftData

// MARK: - Pets Tab

struct PetsTab: View {
    @Query private var pets: [Pet]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddPet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.petBG.ignoresSafeArea()

                if pets.isEmpty {
                    NoPetPromptView(showAddPet: $showAddPet)
                } else {
                    List {
                        ForEach(pets) { pet in
                            NavigationLink(destination: PetProfileView(pet: pet)) {
                                PetListRow(pet: pet)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    // Cancel all notifications before deleting
                                    pet.careEvents.forEach {
                                        NotificationManager.cancel(id: $0.notificationID)
                                    }
                                    modelContext.delete(pet)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.petBG)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My Pets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddPet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetView()
            }
        }
    }
}

// MARK: - Pet List Row

struct PetListRow: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.petIconBG)
                    .frame(width: 54, height: 54)

                if let data = pet.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.petBlue)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name)
                    .font(.headline)
                    .foregroundColor(.petTextMain)
                Text(pet.breed)
                    .font(.subheadline)
                    .foregroundColor(.petTextMuted)
                Text(pet.ageLabel)
                    .font(.caption)
                    .foregroundColor(.petTextMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.petBorder)
        }
        .padding(14)
        .background(Color.petCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.petBorder, lineWidth: 0.5))
    }
}

// MARK: - Empty State

private struct NoPetPromptView: View {
    @Binding var showAddPet: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.petBlue.opacity(0.3))

            Text("No pets yet")
                .font(.title3.weight(.medium))
                .foregroundColor(.petTextMain)

            Text("Add your first pet to get started")
                .font(.subheadline)
                .foregroundColor(.petTextMuted)

            Button {
                showAddPet = true
            } label: {
                Label("Add Pet", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.petBlue)
                    .clipShape(Capsule())
            }
        }
    }
}
