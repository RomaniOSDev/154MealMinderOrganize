import SwiftUI

struct RecipeIngredientGrocerySheet: View {
    let recipe: RecipeListItem
    let lines: [String]

    @EnvironmentObject private var store: MealPlannerStore
    @Environment(\.dismiss) private var dismiss

    @State private var selections: Set<Int> = []

    var body: some View {
        NavigationStack {
            List {
                if lines.isEmpty {
                    Text("This recipe doesn't list ingredients yet.")
                        .foregroundStyle(Color.appTextSecondary)
                } else {
                    Section("Choose rows to merge into your Prep list.") {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, row in
                            Button {
                                AppHaptics.lightTap()
                                if selections.contains(index) {
                                    selections.remove(index)
                                } else {
                                    selections.insert(index)
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selections.contains(index) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selections.contains(index) ? Color.appAccent : Color.appTextSecondary)
                                        .font(.title3.weight(.semibold))

                                    Text(row)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Grocery importer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add items") {
                        let chosen = selections.sorted().map { lines[$0] }
                        store.addGroceryItemsFromIngredientLines(chosen)
                        AppHaptics.successNotice()
                        dismiss()
                    }
                    .disabled(selections.isEmpty)
                    .foregroundStyle(selections.isEmpty ? Color.appTextSecondary : Color.appPrimary)
                    .bold()
                }
            }
            .themedGroupedSurface()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            selections = Set(0 ..< lines.count)
        }
    }
}
