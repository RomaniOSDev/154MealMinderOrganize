import PhotosUI
import SwiftUI
import UIKit

enum RecipeEditorPresentation: Identifiable, Hashable {
    case create(draftRecipeID: String)
    case edit(UserRecipeRecord)

    var id: String {
        switch self {
        case .create(let id): return id
        case .edit(let r): return r.id
        }
    }
}

extension RecipeEditorPresentation {
    fileprivate var symbolForPlaceholderHero: String {
        switch self {
        case .create:
            return "square.grid.2x2.fill"
        case .edit(let r):
            return r.previewSymbolName
        }
    }

    fileprivate var existingRecord: UserRecipeRecord? {
        if case let .edit(r) = self { return r }
        return nil
    }
}

private struct HintDraftEditor: Identifiable {
    let id: UUID
    var step: String
    var mins: String

    init(id: UUID = UUID(), step: String = "", mins: String = "") {
        self.id = id
        self.step = step
        self.mins = mins
    }
}

struct RecipeEditorView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @Environment(\.dismiss) private var dismiss

    let presentation: RecipeEditorPresentation

    @State private var titleText = ""
    @State private var summaryText = ""
    @State private var ingredientLines: [String] = [""]
    @State private var stepLines: [String] = [""]

    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedUIImage: UIImage?
    @State private var stripPhotoRequest = false

    @State private var selectedTags: Set<RecipeTag> = []
    @State private var baseServings: Int = 4
    @State private var activeMinutesEstimateField = ""

    @State private var hintDraftRows: [HintDraftEditor] = []

    @FocusState private var focusedFieldName: EditorField?

    private enum EditorField: Hashable {
        case titleRow
        case ingredient(Int)
        case step(Int)
    }

    private var recipeID: String {
        switch presentation {
        case .create(let id): return id
        case .edit(let r): return r.id
        }
    }

    private var trimmedTitleReady: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                coverSection

                Section {
                    TextField("Title", text: $titleText)
                        .foregroundStyle(Color.appTextPrimary)
                        .focused($focusedFieldName, equals: .titleRow)
                } header: {
                    Label("Recipe name", systemImage: "text.justify.leading")
                }

                Section {
                    TextField("Short description", text: $summaryText, axis: .vertical)
                        .lineLimit(2 ... 6)
                        .foregroundStyle(Color.appTextSecondary)
                } header: {
                    Label("Summary", systemImage: "text.alignleft")
                }

                Section {
                    ScrollView(.vertical, showsIndicators: false) {
                        ForEach(RecipeTag.allCases) { tag in
                            Toggle(
                                tag.filterLabel,
                                isOn: Binding(
                                    get: { selectedTags.contains(tag) },
                                    set: { next in
                                        if next {
                                            selectedTags.insert(tag)
                                        } else {
                                            selectedTags.remove(tag)
                                        }
                                    }
                                )
                            )
                            .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                    .frame(maxHeight: 240)
                } header: {
                    Label("Kitchen tags & filters", systemImage: "tag.fill")
                } footer: {
                    Text("These tags mirror the filters shoppers use inside the Recipes tab.")
                        .foregroundStyle(Color.appTextSecondary.opacity(0.94))
                        .font(.footnote)
                }

                Section {
                    Stepper(value: $baseServings, in: 1 ... 24) {
                        Text("Writes for \(baseServings) servings")
                            .foregroundStyle(Color.appTextPrimary)
                    }

                    TextField("", text: $activeMinutesEstimateField, prompt: Text("Active minutes estimate (optional)"))
                        .foregroundStyle(Color.appTextPrimary)
                        .keyboardType(.numberPad)

                    hintEditorBlock
                } header: {
                    Label("Prep metadata", systemImage: "timer.square")
                } footer: {
                    Text("Pair a step index (1-based row) with a suggested countdown for the Prep timers.")
                        .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                        .font(.footnote)
                }

                Section {
                    ingredientFields
                    Button {
                        ingredientLines.append("")
                    } label: {
                        Label("Add ingredient row", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.appAccent)
                    }
                    .disabled(ingredientLines.count >= 32)
                } header: {
                    Label("Ingredients", systemImage: "leaf.fill")
                }

                Section {
                    stepFields
                    Button {
                        stepLines.append("")
                    } label: {
                        Label("Add step row", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.appAccent)
                    }
                    .disabled(stepLines.count >= 48)
                } header: {
                    Label("Steps", systemImage: "list.number")
                }
            }
            .themedGroupedSurface()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        AppHaptics.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        persistRecipe()
                    }
                    .foregroundStyle(trimmedTitleReady ? Color.appPrimary : Color.appTextSecondary.opacity(0.65))
                    .fontWeight(.semibold)
                    .disabled(!trimmedTitleReady)
                }
            }
        }
        .onAppear {
            seedFromPresentation()
            pickedUIImage = nil
            pickerItem = nil
            stripPhotoRequest = false
        }
        .scrollContentBackground(.hidden)
        .onChange(of: pickerItem) { _, newItem in
            stripPhotoRequest = false
            guard let item = newItem else {
                pickedUIImage = nil
                return
            }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run { pickedUIImage = nil }
                    return
                }
                await MainActor.run {
                    pickedUIImage = image
                }
            }
        }
        .presentationDetents([.large])
        .sheetPresentationChrome()
    }

    @ViewBuilder
    private var coverSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                previewCoverHero
                    .frame(height: 184)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label(
                        heroShowsCustomImage ? "Replace photo" : "Add recipe photo",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryRoundedButtonStyle())

                if heroShowsCustomImage || pickedUIImage != nil {
                    Button(role: .destructive) {
                        AppHaptics.mediumImpact()
                        pickerItem = nil
                        pickedUIImage = nil
                        stripPhotoRequest = true
                    } label: {
                        Label("Remove photo", systemImage: "trash.slash.fill")
                            .foregroundStyle(Color.appAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text("Cover photo (optional)")
        } footer: {
            Text("Pick an image from your library. It stays on this device and is resized before saving.")
                .foregroundStyle(Color.appTextSecondary.opacity(0.92))
                .font(.footnote)
        }
    }

    private var heroShowsCustomImage: Bool {
        pickedUIImage != nil
            || (!stripPhotoRequest
                && (presentation.existingRecord?.hasCoverImage == true)
                && UserRecipeImageStore.load(recipeID: recipeID) != nil)
    }

    private var previewCoverHero: some View {
        Group {
            if let cover = pickedUIImage {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
            } else if !stripPhotoRequest,
                      let existing = presentation.existingRecord,
                      existing.hasCoverImage,
                      let stored = UserRecipeImageStore.load(recipeID: recipeID) {
                Image(uiImage: stored)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.45), Color.appAccent.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: presentation.symbolForPlaceholderHero)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary.opacity(0.88))
                }
            }
        }
        .overlay(
            LinearGradient(
                colors: [Color.appBackground.opacity(0.08), Color.appBackground.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.appPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(1)
    }

    private var ingredientFields: some View {
        ForEach(Array(ingredientLines.indices), id: \.self) { index in
            TextField("Ingredient line", text: bindingForIngredient(index))
                .foregroundStyle(Color.appTextPrimary)
                .focused($focusedFieldName, equals: .ingredient(index))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeIngredientRow(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }

    private var stepFields: some View {
        ForEach(Array(stepLines.indices), id: \.self) { index in
            TextField("Step description", text: bindingForStep(index), axis: .vertical)
                .lineLimit(2 ... 12)
                .foregroundStyle(Color.appTextPrimary)
                .focused($focusedFieldName, equals: .step(index))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeStepRow(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }

    private func bindingForIngredient(_ index: Int) -> Binding<String> {
        Binding(
            get: { ingredientLines.indices.contains(index) ? ingredientLines[index] : "" },
            set: { newValue in
                guard ingredientLines.indices.contains(index) else { return }
                ingredientLines[index] = newValue
            }
        )
    }

    private func bindingForStep(_ index: Int) -> Binding<String> {
        Binding(
            get: { stepLines.indices.contains(index) ? stepLines[index] : "" },
            set: { newValue in
                guard stepLines.indices.contains(index) else { return }
                stepLines[index] = newValue
            }
        )
    }

    private func removeIngredientRow(at index: Int) {
        ingredientLines.remove(at: index)
        if ingredientLines.isEmpty {
            ingredientLines = [""]
        }
    }

    private func removeStepRow(at index: Int) {
        stepLines.remove(at: index)
        if stepLines.isEmpty {
            stepLines = [""]
        }
    }

    @ViewBuilder
    private var hintEditorBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(hintDraftRows.indices), id: \.self) { index in
                HStack(spacing: 12) {
                    TextField("#", text: Binding(
                        get: { hintDraftRows[index].step },
                        set: { hintDraftRows[index].step = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .frame(width: 40)
                    .foregroundStyle(Color.appTextPrimary)

                    TextField("Min", text: Binding(
                        get: { hintDraftRows[index].mins },
                        set: { hintDraftRows[index].mins = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .frame(width: 56)
                    .foregroundStyle(Color.appTextPrimary)

                    Spacer(minLength: 0)

                    Button(role: .destructive) {
                        hintDraftRows.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }

            Button {
                hintDraftRows.append(HintDraftEditor())
            } label: {
                Label("Add timer cue", systemImage: "plus.circle.fill")
                    .foregroundStyle(Color.appAccent)
            }
            .disabled(hintDraftRows.count >= 12)
        }
    }

    private func seedFromPresentation() {
        hintDraftRows.removeAll()

        switch presentation {
        case .create:
            ingredientLines = [""]
            stepLines = [""]
            selectedTags = []
            baseServings = 4
            activeMinutesEstimateField = ""
            hintDraftRows = []

        case .edit(let r):
            titleText = r.title
            summaryText = r.summary
            ingredientLines = r.ingredients.isEmpty ? [""] : r.ingredients
            stepLines = r.steps.isEmpty ? [""] : r.steps
            selectedTags = Set(r.tags)
            baseServings = max(1, r.baseServings)
            activeMinutesEstimateField = r.activeMinutesEstimate.map { String($0) } ?? ""

            hintDraftRows = r.stepTimers.map {
                HintDraftEditor(step: String($0.stepIndex + 1), mins: String($0.durationMinutes))
            }
        }
    }

    private func persistRecipe() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let summaryTrimmed = summaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let ingredients = ingredientLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let steps = stepLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let parsedMinutesInt = Int(activeMinutesEstimateField.trimmingCharacters(in: .whitespacesAndNewlines))
        let sanitizedMinutes = parsedMinutesInt.flatMap { $0 > 0 ? $0 : nil }

        let cleanedHints = buildTimerHints(trimmedStepsCount: steps.count)

        let existing = presentation.existingRecord
        let symbol = existing?.previewSymbolName ?? "square.grid.2x2.fill"

        var nextCover = false
        if pickedUIImage != nil, let picked = pickedUIImage {
            do {
                if try UserRecipeImageStore.saveJPEG(recipeID: recipeID, image: picked) {
                    nextCover = true
                }
            } catch {
                nextCover = existing?.hasCoverImage == true && !stripPhotoRequest
            }
        } else if stripPhotoRequest {
            UserRecipeImageStore.deleteImage(recipeID: recipeID)
            nextCover = false
        } else if let existing, existing.hasCoverImage {
            nextCover = true
        }

        let record = UserRecipeRecord(
            id: recipeID,
            title: trimmedTitle,
            summary: summaryTrimmed,
            previewSymbolName: symbol,
            ingredients: ingredients,
            steps: steps,
            hasCoverImage: nextCover,
            updatedAt: Date(),
            tags: RecipeTag.allCases.filter { selectedTags.contains($0) },
            baseServings: baseServings,
            activeMinutesEstimate: sanitizedMinutes,
            stepTimers: cleanedHints
        )

        AppHaptics.successNotice()
        store.upsertUserRecipe(record)
        dismiss()
    }

    private func buildTimerHints(trimmedStepsCount: Int) -> [RecipeStepTimerHint] {
        guard trimmedStepsCount > 0 else { return [] }
        let maxIdx = trimmedStepsCount - 1

        var results: [RecipeStepTimerHint] = []
        for row in hintDraftRows {
            guard let idx = Int(row.step.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let mins = Int(row.mins.trimmingCharacters(in: .whitespacesAndNewlines)),
                  idx >= 1, mins >= 1 else {
                continue
            }
            let zero = idx - 1
            guard zero <= maxIdx else {
                continue
            }
            results.append(RecipeStepTimerHint(stepIndex: zero, durationMinutes: mins))
        }

        results.sort(by: {
            $0.stepIndex == $1.stepIndex ? $0.durationMinutes < $1.durationMinutes : $0.stepIndex < $1.stepIndex
        })
        return results
    }
}
