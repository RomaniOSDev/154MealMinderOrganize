import SwiftUI

struct CookingTimersView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = CookingTimersViewModel()
    @State private var pulsers: Set<UUID> = []
    @State private var completionHandled: Set<UUID> = []

    private var sceneIsActive: Bool {
        scenePhase == .active
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if sceneIsActive {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            timersList(referenceDate: timeline.date)
                        }
                    } else {
                        timersList(referenceDate: Date())
                    }
                }

                PrimaryTimerFAB {
                    AppHaptics.lightTap()
                    viewModel.beginAdd(store: store)
                }
                .zIndex(10)
                .padding(.trailing, 20)
                .padding(.bottom, 12)
            }
            .background(Color.appBackground)
            .navigationTitle("Cooking Timers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppHaptics.lightTap()
                        viewModel.beginAdd(store: store)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Add new timer")
                }
            }
            .sheet(isPresented: $viewModel.isPresentingAdd) {
                CookingTimerComposerView(viewModel: viewModel)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .sheetPresentationChrome()
            }
            .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
        }
        .onAppear {
            store.synchronizeCookingTimersForSceneActivation(true, date: Date())
        }
        .onChange(of: scenePhase, perform: { phase in
            let active = phase == .active
            store.synchronizeCookingTimersForSceneActivation(active, date: Date())
            if active {
                completionHandled.removeAll()
            }
        })
    }

    private func timersList(referenceDate: Date) -> some View {
        List {
            if store.cookingTimers.isEmpty {
                Section {
                    TimerEmptyHero()
                        .listRowInsets(EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            } else if sceneIsActive {
                Section {
                    Text("Timers pause automatically while this screen isn't active.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                ForEach(store.cookingTimers) { timer in
                    timerRow(for: timer, referenceDate: referenceDate)
                }
            } else {
                Section {
                    Text("Returning soon? Countdowns hold steady until you resume.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .listRowBackground(Color.clear)

                ForEach(store.cookingTimers) { timer in
                    timerRow(for: timer, referenceDate: referenceDate)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 56)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 76)
        }
    }

    private func timerLinkedCaption(for timer: PersistedCookingTimer) -> String? {
        guard let recipeID = timer.linkedRecipeID else { return nil }
        let dish = RecipeResolution.title(recipeID: recipeID, store: store)
        if let step = timer.linkedStepIndex {
            return "\(dish) • Step \(step + 1)"
        }
        return dish
    }

    private func timerRow(for timer: PersistedCookingTimer, referenceDate: Date) -> some View {
        CookingTimerCard(
            timer: timer,
            linkedCaption: timerLinkedCaption(for: timer),
            referenceDate: referenceDate,
            isPulsing: pulsers.contains(timer.id),
            isExpanded: viewModel.expandedTimerIDs.contains(timer.id),
            onToggleExpand: {
                AppHaptics.lightTap()
                if viewModel.expandedTimerIDs.contains(timer.id) {
                    viewModel.expandedTimerIDs.remove(timer.id)
                } else {
                    viewModel.expandedTimerIDs.insert(timer.id)
                }
            },
            onTogglePause: {
                AppHaptics.mediumImpact()
                store.togglePauseCookingTimer(id: timer.id, at: referenceDate)
            },
            onDelete: {
                AppHaptics.lightTap()
                store.removeCookingTimer(id: timer.id)
            },
            onReset: {
                AppHaptics.mediumImpact()
                store.resetCookingTimer(
                    id: timer.id,
                    durationSeconds: max(60, timer.totalDurationSeconds),
                    from: referenceDate
                )
            },
            onFinished: {
                handleCompletion(for: timer, at: referenceDate)
            }
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                AppHaptics.lightTap()
                store.removeCookingTimer(id: timer.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                AppHaptics.mediumImpact()
                store.resetCookingTimer(
                    id: timer.id,
                    durationSeconds: max(60, timer.totalDurationSeconds),
                    from: referenceDate
                )
            } label: {
                Label("Reset", systemImage: "arrow.clockwise.circle")
            }
            .tint(Color.appAccent)
        }
        .contextMenu {
            Button {
                AppHaptics.lightTap()
                store.togglePauseCookingTimer(id: timer.id, at: referenceDate)
            } label: {
                Label(
                    timer.isPaused ? "Resume" : "Pause",
                    systemImage: timer.isPaused ? "play.circle" : "pause.circle"
                )
            }

            Button {
                AppHaptics.lightTap()
                store.resetCookingTimer(
                    id: timer.id,
                    durationSeconds: max(120, timer.totalDurationSeconds),
                    from: referenceDate
                )
            } label: {
                Label("Reset with extra buffer", systemImage: "timer")
            }

            Divider()

            Button(role: .destructive) {
                store.removeCookingTimer(id: timer.id)
            } label: {
                Label("Delete Timer", systemImage: "trash")
            }
        }
    }

    private func handleCompletion(for timer: PersistedCookingTimer, at date: Date) {
        let remaining = timer.remainingSeconds(at: date)
        guard remaining == 0, timer.isPaused == false else { return }
        guard completionHandled.contains(timer.id) == false else { return }
        completionHandled.insert(timer.id)

        AppHaptics.successNotice()
        SystemSounds.play(SystemSounds.timerComplete)

        pulsers.insert(timer.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            pulsers.remove(timer.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            store.finishCookingTimer(id: timer.id)
            store.evaluateAchievements()
        }
    }
}

private struct CookingTimerComposerView: View {
    @EnvironmentObject private var store: MealPlannerStore
    @ObservedObject var viewModel: CookingTimersViewModel

    @State private var durationSelection: Date = Date()
    @State private var dayStart: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Dish name", text: $viewModel.draftName)
                        .foregroundStyle(Color.appTextPrimary)
                        .textInputAutocapitalization(.words)
                        .shake(times: viewModel.shakeToken)

                    if viewModel.showValidation {
                        Text("Provide a recognizable dish title.")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.red.opacity(0.85))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Duration")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)

                        DatePicker("", selection: $durationSelection, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()

                        Text(timeSummary)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                Button {
                    let trimmed = viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.isEmpty == false else {
                        AppHaptics.warningNotice()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.showValidation = true
                        }
                        viewModel.shakeToken += 1
                        return
                    }

                    AppHaptics.mediumImpact()
                    SystemSounds.play(SystemSounds.successPing)
                    AppHaptics.successNotice()

                    store.addCookingTimer(dishName: trimmed, durationSeconds: durationSeconds, from: Date())
                    viewModel.isPresentingAdd = false
                } label: {
                    Text("Start Timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryRoundedButtonStyle())
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }
            .themedGroupedSurface()
            .scrollIndicators(.automatic)
            .navigationTitle("Add New Timer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        AppHaptics.lightTap()
                        viewModel.isPresentingAdd = false
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
            .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
        }
        .screenBackground()
        .onAppear {
            dayStart = Calendar.current.startOfDay(for: Date())
            durationSelection = dayStart.addingTimeInterval(TimeInterval(store.lastUsedDurationSec))
        }
    }

    private var durationSeconds: Int {
        let seconds = Int(durationSelection.timeIntervalSince(dayStart))
        return max(60, seconds)
    }

    private var timeSummary: String {
        let total = durationSeconds
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return String(format: "Total %dh %dm", hours, minutes)
        }
        return String(format: "Total %dm", max(1, minutes))
    }
}

private struct CookingTimerCard: View {
    let timer: PersistedCookingTimer
    let linkedCaption: String?
    let referenceDate: Date
    let isPulsing: Bool

    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onTogglePause: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    let onFinished: () -> Void

    @State private var lastRemaining: Int?

    private var remaining: Int {
        timer.remainingSeconds(at: referenceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timer.dishName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)

                        if let linkedCaption {
                            Text(linkedCaption)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.appAccent)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Label(timeString(from: remaining), systemImage: "timer.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(timer.isPaused ? Color.appAccent : Color.appTextSecondary)

                        ProgressView(
                            value: Double(max(0, timer.totalDurationSeconds - remaining)),
                            total: Double(max(1, timer.totalDurationSeconds))
                        )
                        .tint(Color.appAccent)
                    }

                    Spacer()

                    Button(action: onTogglePause) {
                        Image(systemName: timer.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Stop and remove timer")
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Label("Swipe for quick actions • Long-press for presets", systemImage: "ellipsis.circle")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }

            if remaining > 0 {
                SecondaryTimerButton(title: "Reset Original Time", icon: "arrow.counterclockwise") {
                    onReset()
                }
            }
        }
        .padding(18)
        .appElevatedCard(cornerRadius: 22, tier: .standard)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isPulsing ? Color.appAccent.opacity(0.95) : Color.clear, lineWidth: isPulsing ? 2.2 : 0)
        )
        .onAppear {
            lastRemaining = remaining
        }
        .onChange(of: remaining) { newValue in
            if let previous = lastRemaining, previous > 0, newValue == 0 {
                onFinished()
            }
            lastRemaining = newValue
        }
    }

    private func timeString(from seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

private struct SecondaryTimerButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppVisualGradients.mutedChipFill)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.appPrimary)
    }
}

private struct TimerEmptyHero: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "timer")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.appPrimary)

            TimerGlyphIllustration()
                .frame(height: 120)

            Text("Start your first timer")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Stack multiple dishes and keep every countdown visible at a glance.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding(24)
        .appElevatedCard(cornerRadius: 24, tier: .standard)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

private struct TimerGlyphIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.45), lineWidth: 4)
                .frame(width: 120, height: 120)

            Capsule()
                .fill(Color.appPrimary)
                .frame(width: 4, height: 48)
                .offset(y: -12)
                .rotationEffect(.degrees(-30))

            Capsule()
                .fill(Color.appAccent)
                .frame(width: 4, height: 36)
                .offset(y: -6)
                .rotationEffect(.degrees(55))
        }
    }
}

private struct PrimaryTimerFAB: View {
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
        .accessibilityLabel("Add new timer")
    }
}
