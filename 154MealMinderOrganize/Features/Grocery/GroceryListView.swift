import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @StateObject private var viewModel = GroceryListViewModel()
    @State private var pulsingItemIDs: Set<UUID> = []

    private var grouped: [(GroceryCategory, [GroceryItem])] {
        let dict = Dictionary(grouping: store.groceryItems, by: \.category)
        return GroceryCategory.allCases.compactMap { category in
            guard let items = dict[category], !items.isEmpty else { return nil }
            let sortedItems = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return (category, sortedItems)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    if store.groceryItems.isEmpty {
                        Section {
                            EmptyGroceryListHero()
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            Text(
                                "Your list is currently empty. Add items to get started!"
                            )
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.appSurface.opacity(0.94))
                    } else {
                        Section {
                            Text("Swipe to check items off. Completed ingredients glow briefly.")
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.vertical, 6)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)

                        ForEach(grouped, id: \.0) { category, items in
                            Section(header: sectionHeader(for: category)) {
                                ForEach(items) { item in
                                    GroceryRowView(
                                        item: item,
                                        pulseAccent: pulsingItemIDs.contains(item.id)
                                    )
                                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            completeItemToggle(item.id)
                                        } label: {
                                            Label(item.completed ? "Reopen" : "Complete", systemImage: item.completed ? "arrow.uturn.left" : "checkmark.circle.fill")
                                        }
                                        .tint(Color.appAccent)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            AppHaptics.lightTap()
                                            store.removeGroceryItem(id: item.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        AppHaptics.lightTap()
                                        viewModel.beginEdit(item)
                                    }
                                }
                            }
                        }

                        Section {
                            if store.groceryItems.allSatisfy(\.completed), !store.groceryItems.isEmpty {
                                Button {
                                    AppHaptics.mediumImpact()
                                    SystemSounds.play(SystemSounds.successPing)
                                    AppHaptics.successNotice()
                                    store.completeGroceryShoppingSession()
                                } label: {
                                    Label("Checkout Completed List", systemImage: "shippingbox.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(AppPrimaryRoundedButtonStyle())
                                .padding(.vertical, 6)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .environment(\.defaultMinListRowHeight, 48)
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 76)
                }

                FloatingAddGroceriesButton {
                    AppHaptics.lightTap()
                    viewModel.beginAdd()
                }
                .zIndex(10)
                .padding(.trailing, 20)
                .padding(.bottom, 12)
                .opacity(store.groceryItems.isEmpty ? 1 : 0.95)
                .allowsHitTesting(true)
            }
            .background(Color.appBackground)
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(BuiltInGroceryListPreset.allCases) { preset in
                            Button {
                                AppHaptics.mediumImpact()
                                store.applyGrocerPreset(preset)
                                AppHaptics.successNotice()
                                SystemSounds.play(SystemSounds.successPing)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(preset.title)
                                    Text(preset.detail)
                                        .font(.caption)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "wand.and.sparkles.inverse")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("List templates")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        AppHaptics.lightTap()
                        viewModel.beginAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Add grocery item")

                    if store.groceryItems.isEmpty == false {
                        ShareLink(item: viewModel.shareLines(from: store.groceryItems)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.appPrimary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            AppHaptics.lightTap()
                        })
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingEditor) {
                GroceryEditorSheet(
                    viewModel: viewModel,
                    onSave: { name, category in
                        persistEditor(name: name, category: category)
                    },
                    onCancel: {
                        viewModel.dismissEditor()
                    }
                )
                .presentationDetents([.medium])
                .sheetPresentationChrome()
            }
            .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
        }
    }

    private func sectionHeader(for category: GroceryCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.grid.cross")
                .foregroundStyle(Color.appPrimary)
                .accessibilityHidden(true)
            Text(category.rawValue.uppercased())
                .foregroundStyle(Color.appTextSecondary)
                .font(.caption.weight(.heavy))
                .tracking(0.9)
            Spacer()
        }
    }

    private func completeItemToggle(_ id: UUID) {
        let wasIncomplete = !(store.groceryItems.first(where: { $0.id == id })?.completed ?? false)
        AppHaptics.mediumImpact()
        SystemSounds.play(SystemSounds.groceryChecked)
        store.toggleGroceryCompleted(id: id, at: Date())
        if wasIncomplete {
            AppHaptics.successNotice()
            SystemSounds.play(SystemSounds.successPing)
            animatePulse(for: id)
        }
        store.evaluateAchievements()
    }

    private func animatePulse(for id: UUID) {
        _ = pulsingItemIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            pulsingItemIDs.remove(id)
        }
    }

    private func persistEditor(name: String, category: GroceryCategory) {
        AppHaptics.mediumImpact()
        SystemSounds.play(SystemSounds.successPing)
        AppHaptics.successNotice()
        if let existing = viewModel.itemBeingEdited {
            store.updateGroceryItem(id: existing.id, name: name, category: category)
        } else {
            store.addGroceryItem(name: name, category: category)
        }
        viewModel.dismissEditor()
        store.evaluateAchievements()
    }

}

private struct GroceryEditorSheet: View {
    @ObservedObject var viewModel: GroceryListViewModel
    let onSave: (_ name: String, _ category: GroceryCategory) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var category: GroceryCategory = .produce
    @State private var showValidation = false
    @State private var shakeToken: CGFloat = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("e.g., Baby spinach", text: $name)
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(Color.appTextPrimary)
                        .shake(times: shakeToken)

                    if showValidation {
                        Text("Add a descriptive name.")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .transition(.opacity)
                    }

                    Picker("Category", selection: $category) {
                        ForEach(GroceryCategory.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .tint(Color.appPrimary)
                    .foregroundStyle(Color.appTextPrimary)
                }

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        AppHaptics.warningNotice()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            showValidation = true
                        }
                        shakeToken += 1
                        return
                    }

                    AppHaptics.lightTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showValidation = false
                    }
                    onSave(trimmed, category)
                } label: {
                    Text(viewModel.itemBeingEdited == nil ? "Add Item" : "Save Changes")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryRoundedButtonStyle())
                .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 26, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .themedGroupedSurface()
            .scrollIndicators(.automatic)
            .navigationTitle(viewModel.itemBeingEdited == nil ? "New Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        AppHaptics.lightTap()
                        onCancel()
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .foregroundStyle(Color.appTextPrimary)
            .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
        }
        .screenBackground()
        .onAppear {
            name = viewModel.draftName
            category = viewModel.draftCategory
        }
    }
}

private struct GroceryRowView: View {
    let item: GroceryItem
    let pulseAccent: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(item.completed ? Color.appAccent : Color.appTextSecondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(item.category.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                .padding(.leading, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .appElevatedCard(cornerRadius: 14, tier: .subtle)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(pulseAccent ? Color.appAccent : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.35).repeatCount(1, autoreverses: true), value: pulseAccent)
    }
}

private struct EmptyGroceryListHero: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary)
                .symbolRenderingMode(.hierarchical)

            BasketIllustration()
                .frame(height: 150)

            Text("Start adding your first grocery item")
                .font(.headline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .appElevatedCard(cornerRadius: 22, tier: .standard)
    }
}

private struct BasketIllustration: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.appAccent.opacity(0.45), lineWidth: 3)
                .frame(width: 180, height: 110)
                .offset(y: 10)

            Path { path in
                path.move(to: CGPoint(x: 30, y: 20))
                path.addCurve(
                    to: CGPoint(x: 170, y: 20),
                    control1: CGPoint(x: 80, y: -10),
                    control2: CGPoint(x: 120, y: -10)
                )
            }
            .stroke(Color.appPrimary, lineWidth: 4)
            .offset(y: -40)

            Circle()
                .fill(Color.appAccent.opacity(0.35))
                .frame(width: 18, height: 18)
                .offset(x: -50, y: 6)

            Circle()
                .fill(Color.appPrimary.opacity(0.45))
                .frame(width: 16, height: 16)
                .offset(x: 10, y: 12)

            Circle()
                .fill(Color.appAccent.opacity(0.45))
                .frame(width: 12, height: 12)
                .offset(x: 55, y: 4)
        }
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.76)) {
                appeared = true
            }
        }
    }
}

private struct FloatingAddGroceriesButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .appFABGradientBackdrop()
        .accessibilityLabel("Add grocery item")
    }
}
