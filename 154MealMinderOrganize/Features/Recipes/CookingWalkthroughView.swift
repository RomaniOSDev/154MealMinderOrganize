import SwiftUI

struct CookingWalkthroughView: View {
    let recipe: RecipeListItem
    @EnvironmentObject private var store: MealPlannerStore
    @Environment(\.dismiss) private var dismiss

    @State private var activeStep = 0

    private var ingredientMultiplier: Double {
        store.normalizedIngredientMultiplier(forRecipeID: recipe.id)
    }

    private var scaledIngredients: [String] {
        recipe.scaledIngredientLines(multiplier: ingredientMultiplier)
    }

    private var steps: [String] {
        recipe.stepsList
    }

    private var normalizedStepIndex: Int {
        let maxIndex = max(0, steps.count - 1)
        return min(activeStep, maxIndex)
    }

    private var fractionProgress: CGFloat {
        guard steps.count > 1 else { return 1 }
        return CGFloat(normalizedStepIndex) / CGFloat(steps.count - 1)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        AppHaptics.lightTap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.appAccent)
                    }
                    .accessibilityLabel("Exit cooking mode")

                    Spacer()

                    Text(recipe.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)

                    Spacer()

                    Button {
                        if normalizedStepIndex < steps.count - 1 {
                            AppHaptics.lightTap()
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                activeStep += 1
                            }
                        } else {
                            AppHaptics.successNotice()
                            dismiss()
                        }
                    } label: {
                        Label(
                            normalizedStepIndex >= steps.count - 1 ? "Finish" : "Next",
                            systemImage: normalizedStepIndex >= steps.count - 1 ? "checkmark.circle.fill" : "arrow.forward.circle.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityHint("Advances one cooking step.")
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 6)

                VStack(spacing: 14) {
                    Text("Ingredient quick list")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(scaledIngredients.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(AppVisualGradients.mutedChipFill)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.appPrimary.opacity(0.12), lineWidth: 0.85)
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .opacity(scaledIngredients.isEmpty ? 0 : 1)
                }
                .padding(.horizontal, 18)

                Divider()
                    .background(Color.appTextSecondary.opacity(0.35))
                    .padding(.vertical, 8)

                if steps.indices.contains(normalizedStepIndex) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(
                            normalizedStepIndex < steps.count - 1 ? "Swipe up or tap Next to continue." : "You made it!"
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)

                        Text("\(normalizedStepIndex + 1)")
                            .font(.system(size: 68, weight: .bold))
                            .foregroundStyle(Color.appPrimary)

                        Text(steps[normalizedStepIndex])
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .minimumScaleFactor(0.74)
                            .fixedSize(horizontal: false, vertical: true)

                        if let hint = recipe.timerHint(forStepIndex: normalizedStepIndex) {
                            Button {
                                AppHaptics.mediumImpact()
                                let label = "\(recipe.title) • Step \(normalizedStepIndex + 1)"
                                store.addCookingTimer(
                                    dishName: label,
                                    durationSeconds: max(60, hint.durationMinutes * 60),
                                    from: Date(),
                                    linkedRecipeID: recipe.id,
                                    linkedStepIndex: normalizedStepIndex
                                )
                            } label: {
                                Label(
                                    "Start \(hint.durationMinutes)m timer",
                                    systemImage: "timer.circle.fill"
                                )
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(AppPrimaryRoundedButtonStyle())
                        }

                        if store.stepNote(forRecipeID: recipe.id, stepIndex: normalizedStepIndex).isEmpty == false {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your kitchen note")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(Color.appAccent)

                                Text(store.stepNote(forRecipeID: recipe.id, stepIndex: normalizedStepIndex))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appElevatedCard(cornerRadius: 16, tier: .subtle)
                        }
                    }
                    .padding(.horizontal, 22)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.35), value: normalizedStepIndex)
                }

                Spacer()

                HStack(spacing: 26) {
                    Button {
                        if activeStep > 0 {
                            AppHaptics.lightTap()
                            activeStep -= 1
                        }
                    } label: {
                        Label("Prev", systemImage: "arrow.backward.circle.fill")
                            .font(.title3.weight(.semibold))
                    }
                    .disabled(activeStep == 0)
                    .opacity(activeStep == 0 ? 0.35 : 1)

                    VStack(spacing: 10) {
                        ProgressView(value: fractionProgress)
                            .tint(Color.appAccent)
                        Text("Step \(normalizedStepIndex + 1) / \(steps.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 34)
                .foregroundStyle(Color.appAccent)
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }
}
