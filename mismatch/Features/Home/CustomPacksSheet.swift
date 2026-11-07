import SwiftUI

// Home-screen custom packs. https://github.com/kotinarupali/mismatch-ios/issues/32
// Email sign-in. https://github.com/kotinarupali/mismatch-ios/issues/36
struct CustomPacksSheet: View {
    @Bindable var viewModel: CustomPacksViewModel
    @FocusState private var promptFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                if CustomPackConfig.requirePremium {
                    premiumLock
                } else {
                    packEditor
                }
            }
            .navigationTitle("Custom Packs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { viewModel.dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await viewModel.onAppear() }
    }

    private var premiumLock: some View {
        VStack(spacing: 16) {
            Text("Custom packs are part of premium.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
            Text("Built-in packs are still ready for a game.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
        }
        .padding(24)
    }

    private var packEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.isConfigured {
                    Text("Add the Supabase URL and anon key to turn on custom packs.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("A theme, like a Goa trip", text: $viewModel.prompt)
                            .textInputAutocapitalization(.sentences)
                            .foregroundStyle(AppColor.label)
                            .focused($promptFocused)
                            .disabled(viewModel.isGenerating)
                        Stepper(value: $viewModel.count, in: 1...CustomWordRules.maxCount) {
                            Text("\(viewModel.count) pairs")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.label)
                        }
                        .disabled(viewModel.isGenerating)
                    }
                    .padding(16)
                }

                PrimaryButton(
                    title: viewModel.isGenerating ? "Making words…" : "Generate",
                    isEnabled: viewModel.canGenerate
                ) {
                    promptFocused = false
                    viewModel.generateTapped()
                }

                if !viewModel.samplePairs.isEmpty {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Samples")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.label)
                            Text("Not saved, and not used in a game.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                            wordToggle(shown: viewModel.samplesVisible) {
                                viewModel.samplesVisible.toggle()
                            }
                            if viewModel.samplesVisible {
                                ForEach(viewModel.samplePairs) { pair in
                                    Text("\(pair.insiderWord)  /  \(pair.mismatchWord)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.label)
                                }
                            }
                        }
                        .padding(16)
                    }
                }

                if let pendingTitle = viewModel.pendingTitle {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("That name is already used. Choose another.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                            TextField("Pack title", text: Binding(
                                get: { viewModel.replacementTitle },
                                set: { viewModel.replacementTitle = $0 }
                            ))
                            .foregroundStyle(AppColor.label)
                            Button("Save pack") { viewModel.savePendingTitle() }
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.accent)
                            wordToggle(shown: viewModel.pendingWordsVisible) {
                                viewModel.pendingWordsVisible.toggle()
                            }
                            if viewModel.pendingWordsVisible {
                                ForEach(viewModel.pendingPairs) { pair in
                                    Text("\(pair.insiderWord)  /  \(pair.mismatchWord)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.label)
                                    Text(pair.category)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.secondaryLabel)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .onAppear {
                        if viewModel.replacementTitle.isEmpty {
                            viewModel.replacementTitle = pendingTitle
                        }
                    }
                }

                if let message = viewModel.statusMessage {
                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accentSecondary)
                }

                if !viewModel.packs.isEmpty {
                    Text("Your packs")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.label)
                    ForEach(viewModel.packs) { pack in
                        packCard(pack)
                    }
                }
            }
            .padding(24)
        }
    }

    // Edit, replace, remove, rename, and archive. https://github.com/kotinarupali/mismatch-ios/issues/34
    private func packCard(_ pack: CustomWordPack) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: titleBinding(for: pack))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.label)
                    .onSubmit { viewModel.rename(pack) }
                if let stamp = generatedStamp(pack.createdAt) {
                    Text(stamp)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                Text("\(pack.stats.remaining) left · \(pack.stats.used) played")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                wordToggle(shown: viewModel.revealedPackIDs.contains(pack.id)) {
                    viewModel.toggleWords(for: pack)
                }
                if viewModel.revealedPackIDs.contains(pack.id) {
                    ForEach(pack.visiblePairs) { pair in
                        pairRow(pair, in: pack)
                    }
                }
                Button("Archive pack", role: .destructive) {
                    viewModel.packPendingArchive = pack
                }
                .font(AppTypography.caption)
                .disabled(viewModel.isBusy)
                .confirmationDialog(
                    "Archive \(pack.title)?",
                    isPresented: Binding(
                        get: { viewModel.packPendingArchive?.id == pack.id },
                        set: { if !$0 { viewModel.packPendingArchive = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Archive", role: .destructive) {
                        viewModel.archive(pack)
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.packPendingArchive = nil
                    }
                } message: {
                    Text("It leaves your list. The words can be used in a new pack.")
                }
            }
            .padding(16)
        }
    }

    private func pairRow(_ pair: CustomWordPair, in pack: CustomWordPack) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if pair.playedAt == nil, viewModel.editingPairID == pair.id {
                TextField("Insider", text: $viewModel.editInsider)
                TextField("Mismatch", text: $viewModel.editMismatch)
                TextField("Category", text: $viewModel.editCategory)
                    .font(AppTypography.caption)
                HStack {
                    Button("Save") { viewModel.saveEdit(pack: pack, pair: pair) }
                    Button("Cancel") { viewModel.editingPairID = nil }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.accent)
            } else {
                Text("\(pair.insiderWord)  /  \(pair.mismatchWord)")
                    .font(AppTypography.body)
                    .foregroundStyle(pair.playedAt == nil ? AppColor.label : AppColor.secondaryLabel)
                Text(pair.category)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                if pair.playedAt == nil {
                    HStack {
                        Button("Edit") { viewModel.beginEdit(pair) }
                        Button("Replace") { viewModel.replace(pack: pack, pair: pair) }
                        Button("Remove") { viewModel.remove(pack: pack, pair: pair) }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)
                    .disabled(viewModel.isBusy)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func wordToggle(shown: Bool, action: @escaping () -> Void) -> some View {
        Button(shown ? "Hide words" : "Show words", action: action)
            .font(AppTypography.body)
            .foregroundStyle(AppColor.accent)
    }

    private func generatedStamp(_ raw: String?) -> String? {
        guard let raw, let date = Self.parseGeneratedDate(raw) else { return nil }
        return "Generated \(Self.generatedDateFormatter.string(from: date))"
    }

    private static func parseGeneratedDate(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }

    private static let generatedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func titleBinding(for pack: CustomWordPack) -> Binding<String> {
        Binding(
            get: { viewModel.titles[pack.id] ?? pack.title },
            set: { viewModel.titles[pack.id] = $0 }
        )
    }
}

@MainActor
@Observable
final class CustomPacksViewModel {
    private let service: CustomWordPackService
    private let onClose: () -> Void

    var prompt = ""
    var count = 10
    var packs: [CustomWordPack] = []
    var isGenerating = false
    var isBusy = false
    var statusMessage: String?
    var samplePairs: [CustomWordPair] = []
    var pendingTitle: String?
    var pendingPairs: [CustomWordPair] = []
    var pendingRequestID: String?
    var replacementTitle = ""
    var titles: [String: String] = [:]
    var packPendingArchive: CustomWordPack?
    var editingPairID: String?
    var editInsider = ""
    var editMismatch = ""
    var editCategory = ""
    var revealedPackIDs: Set<String> = []
    var samplesVisible = false
    var pendingWordsVisible = false

    init(service: CustomWordPackService, onClose: @escaping () -> Void) {
        self.service = service
        self.onClose = onClose
    }

    var isConfigured: Bool { service.isConfigured }
    var canGenerate: Bool {
        !isGenerating && isConfigured && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func onAppear() async {
        await service.sync()
        refresh()
    }

    func dismiss() {
        onClose()
    }

    func generateTapped() {
        guard canGenerate else { return }
        isGenerating = true
        statusMessage = nil
        samplePairs = []
        samplesVisible = false
        pendingWordsVisible = false
        let theme = prompt
        let pairCount = count
        Task {
            let result = await service.generate(prompt: theme, count: pairCount)
            isGenerating = false
            switch result {
            case .pack(_, let samples):
                pendingTitle = nil
                pendingRequestID = nil
                statusMessage = nil
                samplePairs = samples
            case .titleTaken(let title, let pairs, let samples, let requestID):
                pendingTitle = title
                pendingPairs = pairs
                pendingRequestID = requestID
                replacementTitle = title
                samplePairs = samples
                statusMessage = "You already have a pack named \(title)."
            case .failed(let message):
                statusMessage = message
            case nil:
                statusMessage = service.lastError
            }
            refresh()
        }
    }

    func savePendingTitle() {
        guard let requestID = pendingRequestID else { return }
        let title = replacementTitle
        isBusy = true
        Task {
            let saved = await service.save(title: title, requestID: requestID)
            isBusy = false
            if saved {
                pendingTitle = nil
                pendingRequestID = nil
                pendingPairs = []
                statusMessage = nil
            } else {
                statusMessage = service.lastError
            }
            refresh()
        }
    }

    func rename(_ pack: CustomWordPack) {
        let title = titles[pack.id] ?? pack.title
        isBusy = true
        Task {
            let saved = await service.rename(packID: pack.id, title: title)
            isBusy = false
            statusMessage = saved ? nil : service.lastError
            refresh()
        }
    }

    func archive(_ pack: CustomWordPack) {
        packPendingArchive = nil
        isBusy = true
        Task {
            await service.archive(packID: pack.id)
            isBusy = false
            statusMessage = service.lastError
            refresh()
        }
    }

    func toggleWords(for pack: CustomWordPack) {
        if revealedPackIDs.contains(pack.id) {
            revealedPackIDs.remove(pack.id)
            if pack.pairs.contains(where: { $0.id == editingPairID }) {
                editingPairID = nil
            }
        } else {
            revealedPackIDs.insert(pack.id)
        }
    }

    func beginEdit(_ pair: CustomWordPair) {
        editingPairID = pair.id
        editInsider = pair.insiderWord
        editMismatch = pair.mismatchWord
        editCategory = pair.category
    }

    func saveEdit(pack: CustomWordPack, pair: CustomWordPair) {
        var updated = pair
        updated.insiderWord = editInsider
        updated.mismatchWord = editMismatch
        updated.category = editCategory
        updated.insiderCanonical = editInsider
        updated.mismatchCanonical = editMismatch
        isBusy = true
        Task {
            let saved = await service.edit(packID: pack.id, pair: updated)
            isBusy = false
            editingPairID = saved ? nil : editingPairID
            statusMessage = saved ? nil : service.lastError
            refresh()
        }
    }

    func remove(pack: CustomWordPack, pair: CustomWordPair) {
        isBusy = true
        Task {
            let saved = await service.remove(packID: pack.id, pairID: pair.id)
            isBusy = false
            statusMessage = saved ? nil : service.lastError
            refresh()
        }
    }

    func replace(pack: CustomWordPack, pair: CustomWordPair) {
        isBusy = true
        Task {
            let saved = await service.replace(packID: pack.id, pairID: pair.id)
            isBusy = false
            statusMessage = saved ? nil : service.lastError
            refresh()
        }
    }

    private func refresh() {
        packs = service.packs
        for pack in packs where titles[pack.id] == nil {
            titles[pack.id] = pack.title
        }
    }
}
