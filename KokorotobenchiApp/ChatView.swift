// ChatView.swift
// こころとベンチ — D-1：チャット画面

import SwiftUI
import FoundationModels

struct ChatView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var showCrisis: Bool = false
    @State private var sensorSession = SensorSession()
    @FocusState private var isInputFocused: Bool

    private let crisisWords = [
        "消えたい", "死にたい", "いなくなりたい", "消えて楽に",
        "静かに終わらせ", "傷を増やし", "傷が増え", "新しい傷",
        "生きてる意味", "生きてる価値", "消えた方がいい",
        "自殺", "死ぬかも", "傷跡", "自分を傷"
    ]

    @State private var session: LanguageModelSession? = nil
    @State private var isGenerating = false
    @State private var sessionHadDeepQuestion = false
    @State private var lastUserQuote = ""
    @State private var lastCharacterQuote = ""
    @State private var fallbackIndex = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                messageList
                inputBar
            }

            if showCrisis {
                CrisisOverlayView(isPresented: $showCrisis) {
                    let followUp = ChatMessage(sender: .character, text: "話してくれてありがとう。\nよかったら、もう少し詳しく聞かせてもらえる？")
                    state.currentMessages.append(followUp)
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCrisis)
        .onAppear { setupSession() }
        .onDisappear { state.endSession(hadDeepQuestion: sessionHadDeepQuestion) }
    }

    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium))
                    Text("ホーム").font(.system(size: 15, design: .rounded))
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(state.selectedCharacter.emoji).font(.system(size: 20))
                Text(state.selectedCharacter.displayName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Color.clear.frame(width: 70)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Color(.systemBackground).shadow(.drop(color: .black.opacity(0.06), radius: 1, y: 1)))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    disclaimerNote
                    ForEach(state.currentMessages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if isGenerating { typingIndicator }
                }
                .padding(.horizontal, 16).padding(.vertical, 16)
            }
            .onChange(of: state.currentMessages.count) { _, _ in
                if let last = state.currentMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: isGenerating) { _, generating in
                if generating { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private var disclaimerNote: some View {
        Text("※この会話はアドバイスや診断ではありません。\n心配なことがあるときは専門家へ。")
            .font(.system(size: 11, design: .rounded))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24).padding(.bottom, 8)
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .user {
                Spacer(minLength: 60)
                Text(message.text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.accentColor))
            } else {
                Text(state.selectedCharacter.emoji).font(.system(size: 24)).offset(y: 4)
                Text(message.text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                    )
                Spacer(minLength: 60)
            }
        }
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(state.selectedCharacter.emoji).font(.system(size: 24)).offset(y: 4)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .opacity(isGenerating ? 0.4 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.18),
                            value: isGenerating
                        )
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
            Spacer(minLength: 60)
        }
        .id("typing")
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("話しかける...", text: $inputText, axis: .vertical)
                .font(.system(size: 15, design: .rounded))
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))

            Button { sendMessage() } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.secondary.opacity(0.4)
                            : Color.accentColor)
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private func setupSession() {
        sensorSession.reset()
        let opening = ChatMessage(sender: .character, text: state.selectedCharacter.firstMessage)
        state.currentMessages.append(opening)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false

        if crisisWords.contains(where: { text.contains($0) }) {
            let userMsg = ChatMessage(sender: .user, text: text)
            state.currentMessages.append(userMsg)
            withAnimation { showCrisis = true }
            return
        }

        let userMsg = ChatMessage(sender: .user, text: text)
        state.currentMessages.append(userMsg)

        Task {
            await generateResponse(for: text)
        }
    }

    private func generateResponse(for userText: String) async {
        isGenerating = true
        defer { isGenerating = false }

        let sensorResult = SensorEngine.analyze(userText)
        let engagementMode: EngagementMode = userText.count < 15 ? .monologue : .dialogue

        let request = SensorPromptRequest(
            utterance: userText,
            preSensorResult: sensorResult.pattern,
            engagementMode: engagementMode,
            sessionContext: nil
        )
        let prompts = SensorPromptBuilder.build(for: request, character: state.selectedCharacter)

        if session == nil {
            session = LanguageModelSession(instructions: Instructions(prompts.system))
        }

        guard let session else {
            appendFallback(pattern: sensorResult.pattern)
            return
        }

        do {
            let response = try await session.respond(to: prompts.user)
            let cleaned = postProcess(response.content, userText: userText)
            let hasDeepQ = cleaned.contains("？") || cleaned.contains("?")
            let msg = ChatMessage(sender: .character, text: cleaned, hasDeepQuestion: hasDeepQ)
            state.currentMessages.append(msg)

            if hasDeepQ && !sessionHadDeepQuestion {
                sessionHadDeepQuestion = true
                lastUserQuote = userText
                lastCharacterQuote = cleaned
                state.addInsight(userQuote: userText, characterQuote: cleaned)
            }
        } catch {
            appendFallback(pattern: sensorResult.pattern)
        }
    }

    private func postProcess(_ text: String, userText: String) -> String {
        deduplicated(removeEcho(text, userMessage: userText))
    }

    private func removeEcho(_ text: String, userMessage: String) -> String {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let first = lines.first, lines.count > 1 else { return text }
        let userCore = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "？", with: "").replacingOccurrences(of: "?", with: "")
        let firstCore = first.replacingOccurrences(of: "？", with: "").replacingOccurrences(of: "?", with: "")
        if firstCore == userCore || (!userCore.isEmpty && firstCore.hasPrefix(userCore.prefix(6))) {
            return lines.dropFirst().joined(separator: "\n")
        }
        return text
    }

    private func deduplicated(_ text: String) -> String {
        let parts = text.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if parts.count >= 2, parts.last == parts[parts.count - 2] {
            return parts.dropLast().joined(separator: "\n\n")
        }
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if lines.count >= 2, lines.last == lines[lines.count - 2] {
            return lines.dropLast().joined(separator: "\n")
        }
        return text
    }

    private func appendFallback(pattern: SensorPattern) {
        let response: String
        switch pattern {
        case .factVsAssumption:
            let opts = SensorResponseTemplates.reception(pattern: .factVsAssumption, character: state.selectedCharacter, type: .empathy)
            response = opts
        case .taskOverload:
            response = SensorResponseTemplates.reception(pattern: .taskOverload, character: state.selectedCharacter, type: .appreciation)
        case .none:
            fallbackIndex += 1
            let opts: [String]
            switch state.selectedCharacter {
            case .master: opts = ["なるほどな。", "そっか。", "うん。", "ふむ。"]
            case .senpai: opts = ["そっか。", "ふむ。", "まあな。", "うん。"]
            case .friend: opts = ["そっかー。", "うんうん。", "なるほど！", "へえ。"]
            }
            response = opts[fallbackIndex % opts.count]
        }
        state.currentMessages.append(ChatMessage(sender: .character, text: response))
    }
}

// MARK: - Crisis Overlay

struct CrisisOverlayView: View {
    @Binding var isPresented: Bool
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("大丈夫？")
                    .font(.title2.weight(.semibold))
                Text("今、とてもしんどい気持ちがあるんだね。\n一人で抱えないでほしい。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    Link(destination: URL(string: "tel://0120279338")!) {
                        Label("よりそいホットライン（24時間）", systemImage: "phone.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.8)))
                    }
                    Link(destination: URL(string: "tel://0570783556")!) {
                        Label("いのちの電話", systemImage: "phone.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.8)))
                    }
                }

                Button {
                    isPresented = false
                    onContinue()
                } label: {
                    Text("話を続ける")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
            .padding(.horizontal, 24)
        }
    }
}
