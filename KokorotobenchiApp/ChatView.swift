// ChatView.swift
// こころとベンチ — D-1：チャット画面

import SwiftUI
import FoundationModels

// MARK: - メッセージカテゴリ分類

private enum MessageCategory {
    case crisis         // 危機的発言
    case heavyNegative  // 強い感情（嫌われてる・消えたい寸前）
    case negative       // ネガティブ（しんどい・つらい）
    case seeking        // 質問・相談（どうしたら）
    case shortReply     // 短い返答（そう・えっ・うん）
    case neutral        // 通常

    static func classify(_ text: String) -> MessageCategory {
        let crisisWords = ["消えたい", "死にたい", "いなくなりたい", "自殺", "死ぬかも",
                           "傷を増やし", "新しい傷", "生きてる意味", "生きてる価値"]
        if crisisWords.contains(where: { text.contains($0) }) { return .crisis }

        let heavyWords = [
            "嫌われてる", "嫌われている", "嫌っている", "嫌ってる",
            "みんな嫌い", "誰も好きじゃない", "誰にも必要とされない",
            "消えたほうがいい", "いない方がいい", "いなくなりたい",
            "生きてても意味", "何もしたくない", "全部嫌",
            "見捨てられ", "必要とされてない", "邪魔にされ",
            "消えた方がいい", "誰も気にしない"
        ]
        if heavyWords.contains(where: { text.contains($0) }) { return .heavyNegative }

        let negativeWords = [
            "つらい", "つらく",
            "しんどい", "しんどく",
            "きつい", "きつく",
            "嫌", "ダメ", "無理", "苦しい", "苦しく",
            "悲しい", "怖い", "不安", "落ち込", "疲れた", "最悪", "ひどい"
        ]
        if negativeWords.contains(where: { text.contains($0) }) { return .negative }

        let seekingWords = ["どうしたら", "どうすれば", "どうしよう", "どう思う",
                            "教えて", "アドバイス", "どうすること"]
        if seekingWords.contains(where: { text.contains($0) }) { return .seeking }

        // 5文字以下は質問符があってもshortReply（「え？」「そう？」「なんで？」等）
        if text.count <= 5 { return .shortReply }
        // 6文字以下で質問でない（「そっかな」「いやいや」等）
        if text.count <= 6 && !text.contains("？") && !text.contains("?") { return .shortReply }

        return .neutral
    }
}

// MARK: - 全体背景色

private let chatBg = Color(red: 0.982, green: 0.973, blue: 0.957)   // 温かい羊皮紙色

// MARK: - ChatView

struct ChatView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var showCrisis: Bool = false
    @FocusState private var isInputFocused: Bool

    @State private var session: LanguageModelSession? = nil
    @State private var isGenerating = false
    @State private var sessionHadDeepQuestion = false
    @State private var templateIndex = 0
    @State private var lastAIResponse = ""
    @State private var consecutiveFallbackCount = 0

    var body: some View {
        ZStack {
            chatBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navigationBar
                messageList
                inputBar
            }
            if showCrisis {
                CrisisOverlayView(isPresented: $showCrisis) {
                    let followUp = ChatMessage(sender: .character, text: crisisFollowUp)
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

    private var crisisFollowUp: String {
        switch state.selectedCharacter {
        case .master: return "話してくれてありがとう。\nよかったら、もう少し聞かせてくれるか。"
        case .senpai: return "話してくれてよかった。\nもう少し、聞かせてくれるか？"
        case .friend: return "話してくれてありがとう。\nもうちょっと、話せる？"
        }
    }

    // MARK: - ナビゲーションバー

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            HStack(spacing: 10) {
                CharacterAvatarView(character: state.selectedCharacter, size: 36)
                Text(state.selectedCharacter.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .background(
            Color.white
                .shadow(.drop(color: .black.opacity(0.07), radius: 1, y: 1))
        )
    }

    // MARK: - メッセージリスト

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    disclaimerNote
                    ForEach(state.currentMessages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if isGenerating { typingIndicator }
                }
                .padding(.horizontal, 16).padding(.vertical, 20)
            }
            .onChange(of: state.currentMessages.count) { _, _ in
                if let last = state.currentMessages.last {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isGenerating) { _, generating in
                if generating {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    private var disclaimerNote: some View {
        Text("この会話はアドバイスや診断ではありません\n心配なことは専門家へ")
            .font(.system(size: 11, design: .rounded))
            .foregroundStyle(Color.secondary.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32).padding(.bottom, 4)
    }

    // MARK: - メッセージバブル

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        if message.sender == .user {
            // ユーザー発言: 右寄せ、テーマカラー
            HStack(alignment: .bottom, spacing: 0) {
                Spacer(minLength: 64)
                Text(message.text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(state.selectedCharacter.themeColor)
                    )
            }
        } else {
            // キャラクター発言: 左寄せ、白バブル + アバター
            HStack(alignment: .bottom, spacing: 10) {
                CharacterAvatarView(character: state.selectedCharacter, size: 36)
                Text(message.text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.12))
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
                    )
                Spacer(minLength: 64)
            }
        }
    }

    // MARK: - タイピングインジケーター

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 10) {
            CharacterAvatarView(character: state.selectedCharacter, size: 36)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(state.selectedCharacter.themeColor.opacity(0.45))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isGenerating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.16),
                            value: isGenerating
                        )
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
            )
            Spacer(minLength: 64)
        }
        .id("typing")
    }

    // MARK: - 入力バー（大型・使いやすい）

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // テキストフィールド
            TextField("いまどんな気持ち？", text: $inputText, axis: .vertical)
                .font(.system(size: 17, design: .rounded))
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)          // ← 大きめパディング
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 1)
                )

            // 送信ボタン
            let canSend = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
            Button { sendMessage() } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)   // ← 大きめボタン
                    .background(
                        Circle()
                            .fill(canSend ? state.selectedCharacter.themeColor : Color.secondary.opacity(0.28))
                    )
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.white
                .shadow(.drop(color: .black.opacity(0.07), radius: 1, y: -1))
        )
    }

    // MARK: - セッションセットアップ

    private func setupSession() {
        let opening = ChatMessage(sender: .character, text: state.selectedCharacter.firstMessage)
        state.currentMessages.append(opening)
    }

    // MARK: - 送信

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false

        let category = MessageCategory.classify(text)
        let userMsg = ChatMessage(sender: .user, text: text)
        state.currentMessages.append(userMsg)

        if category == .crisis {
            withAnimation { showCrisis = true }
            return
        }

        Task { await generateResponse(for: text, category: category) }
    }

    // MARK: - 応答生成

    private func generateResponse(for userText: String, category: MessageCategory) async {
        isGenerating = true
        defer { isGenerating = false }

        // 短い返答（そう/え？/うん）はテンプレートで即返す
        if category == .shortReply {
            appendTemplate(category: .shortReply, userText: userText)
            return
        }

        // セッション作成（初回のみ）
        if session == nil {
            let systemPrompt = SensorPromptBuilder.buildSystemPrompt(character: state.selectedCharacter)
            session = LanguageModelSession(instructions: Instructions(systemPrompt))
        }

        guard let session else {
            appendTemplate(category: category, userText: userText)
            return
        }

        do {
            let raw = try await session.respond(to: userText)
            let cleaned = postProcess(raw.content, userText: userText)

            // P7: 空・意味のない応答
            guard cleaned.count >= 3 else {
                appendTemplate(category: category, userText: userText)
                return
            }
            // P3: アドバイス検出
            if detectsAdvice(cleaned) {
                appendTemplate(category: category, userText: userText)
                return
            }
            // P1: ロール逆転検出
            if detectsRoleConfusion(cleaned) {
                appendTemplate(category: category, userText: userText)
                return
            }
            // P10: キャラクター崩れ（敬語）
            if detectsWrongTone(cleaned) {
                appendTemplate(category: category, userText: userText)
                return
            }
            // P4: 直前応答との酷似
            if isSimilarToLast(cleaned) {
                appendTemplate(category: category, userText: userText)
                consecutiveFallbackCount += 1
                return
            }

            consecutiveFallbackCount = 0
            lastAIResponse = cleaned

            let hasDeepQ = cleaned.contains("？") || cleaned.contains("?")
            state.currentMessages.append(
                ChatMessage(sender: .character, text: cleaned, hasDeepQuestion: hasDeepQ)
            )

            if hasDeepQ && !sessionHadDeepQuestion {
                sessionHadDeepQuestion = true
                state.addInsight(userQuote: userText, characterQuote: cleaned)
            }
        } catch {
            appendTemplate(category: category, userText: userText)
        }
    }

    // MARK: - ポストプロセス

    private func postProcess(_ text: String, userText: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        result = removeEcho(result, userMessage: userText)
        result = removeRepeatWithinResponse(result)
        result = truncate(result)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // P2: エコー除去
    private func removeEcho(_ text: String, userMessage: String) -> String {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let first = lines.first, lines.count > 1 else { return text }

        let normalize: (String) -> String = {
            $0.replacingOccurrences(of: "？", with: "")
              .replacingOccurrences(of: "?", with: "")
              .replacingOccurrences(of: "。", with: "")
              .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let userNorm  = normalize(userMessage)
        let firstNorm = normalize(first)
        let prefixLen = min(8, min(userNorm.count, firstNorm.count))
        if prefixLen >= 4 &&
           (firstNorm == userNorm || firstNorm.prefix(prefixLen) == userNorm.prefix(prefixLen)) {
            return lines.dropFirst().joined(separator: "\n")
        }
        return text
    }

    // 応答内の繰り返し文削除
    private func removeRepeatWithinResponse(_ text: String) -> String {
        let sentences = splitSentences(text)
        guard sentences.count >= 2 else { return text }
        var deduped: [String] = [sentences[0]]
        for i in 1..<sentences.count {
            if sentences[i] != sentences[i-1] { deduped.append(sentences[i]) }
        }
        return deduped.joined()
    }

    // P6: 長すぎる応答を最初の2文に切り詰め
    private func truncate(_ text: String) -> String {
        let sentences = splitSentences(text)
        guard sentences.count > 3 else { return text }
        return sentences.prefix(2).joined()
    }

    private func splitSentences(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for char in text {
            current.append(char)
            if "。！？\n".contains(char) {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { result.append(trimmed) }
                current = ""
            }
        }
        let remainder = current.trimmingCharacters(in: .whitespaces)
        if !remainder.isEmpty { result.append(remainder) }
        return result
    }

    // P4: 直前応答との類似チェック
    private func isSimilarToLast(_ text: String) -> Bool {
        guard !lastAIResponse.isEmpty else { return false }
        let a = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = lastAIResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if a == b { return true }
        let prefixLen = min(25, min(a.count, b.count))
        if prefixLen >= 12 && a.prefix(prefixLen) == b.prefix(prefixLen) { return true }
        return false
    }

    // P3: アドバイス検出
    private func detectsAdvice(_ text: String) -> Bool {
        let patterns = [
            "することが大切", "しましょう", "するといい", "することをおすすめ",
            "まずは〜", "一番大切", "してみてください", "するとよいでしょう",
            "したらどうでしょう", "ためには", "見直すことが",
            "必要があります", "べきです", "しなければ", "がんばって",
            "大丈夫ですよ", "できますよ", "してみよう", "してみると"
        ]
        return patterns.contains { text.contains($0) }
    }

    // P1: ロール逆転検出
    private func detectsRoleConfusion(_ text: String) -> Bool {
        let patterns = [
            "よく悩むこともあるんだ", "私も悩む", "私もそう思う",
            "私自身も", "悩むこともあるんだよね", "自分もそういう",
            "私も同じ", "私の場合", "私だって", "自分もそう",
            "俺も悩む", "俺もそういう", "俺の場合"
        ]
        return patterns.contains { text.contains($0) }
    }

    // P10: キャラクター崩れ（敬語・丁寧語）
    private func detectsWrongTone(_ text: String) -> Bool {
        let patterns = ["ですね", "でしょう", "ますよ", "しています", "おります",
                        "いたします", "〜ですか", "ませんか", "しておく"]
        return patterns.contains { text.contains($0) }
    }

    // MARK: - テンプレート応答

    private func appendTemplate(category: MessageCategory, userText: String) {
        templateIndex += 1
        let idx = templateIndex
        let c   = state.selectedCharacter
        let text: String

        switch category {

        case .crisis:
            text = crisisFollowUp

        case .heavyNegative:
            let pool: [CharacterType: [String]] = [
                .master: ["そうか…。それはしんどかったな。",
                          "それは…きつかったな。少し聞かせてくれるか。",
                          "うん。よく話してくれた。",
                          "そうか。一人で抱えてきたんだな。"],
                .senpai: ["そっか、それはしんどかったな。",
                          "まあ…それはつらかったよ。",
                          "うん。よく話してくれた。",
                          "そうか。一人で抱えてたのか。"],
                .friend: ["え、それしんどいじゃん…。",
                          "それはつらいよ。話してくれてよかった。",
                          "うん、ちゃんと聞いてるよ。",
                          "そっか…。一人で抱えてたんだ。"]
            ]
            text = pool[c]![(idx - 1) % pool[c]!.count]

        case .negative:
            let pool: [CharacterType: [String]] = [
                .master: ["そうか。何があったんだ？",
                          "それはしんどいな。",
                          "うん、聞いてるよ。",
                          "そっか。もう少し話してくれるか。"],
                .senpai: ["そっか、それは大変だったな。",
                          "まあ、しんどかったよな。",
                          "うん、そうか。",
                          "それはきつかっただろ。"],
                .friend: ["え、それしんどいじゃん。",
                          "そっかー、つらかったんだね。",
                          "うんうん、話して。",
                          "それは大変だったね。"]
            ]
            text = pool[c]![(idx - 1) % pool[c]!.count]

        case .seeking:
            let pool: [CharacterType: [String]] = [
                .master: ["うん。今どんな気持ちだ？",
                          "そっか。まずどう感じてる？",
                          "答えより先に、何がいちばん気になってる？"],
                .senpai: ["まあ、どうしたいかより、今どんな気持ちだ？",
                          "うん。それで、今どう感じてる？",
                          "まず気持ちを聞かせてくれ。"],
                .friend: ["答えより、今どんな感じ？",
                          "うんうん。今いちばん気になってることって何？",
                          "まず気持ちを教えて。"]
            ]
            text = pool[c]![(idx - 1) % pool[c]!.count]

        case .shortReply:
            // P9: 短い相槌には短く返す
            let pool: [CharacterType: [String]] = [
                .master: ["ふむ。", "そうか。", "うん。", "ああ。", "なるほど。", "それで？"],
                .senpai: ["そっか。", "まあな。", "うん。", "ふーん。", "そうか。", "それで？"],
                .friend: ["うんうん。", "そっかー。", "へえ。", "なるほど！", "うん。", "それで？"]
            ]
            text = pool[c]![(idx - 1) % pool[c]!.count]

        case .neutral:
            let pool: [CharacterType: [String]] = [
                .master: ["なるほどな。", "そうか。", "ふむ。",
                          "もう少し聞かせてくれるか。", "それで、どうなった？", "ああ、そうか。"],
                .senpai: ["なるほどな。", "そっか。", "ふむ。",
                          "もう少し聞かせてくれ。", "それで？", "ああ、そうか。"],
                .friend: ["なるほど！", "そっかー。", "うんうん。",
                          "もうちょっと話して。", "へえ、それで？", "ああ、そうなんだ。"]
            ]
            text = pool[c]![(idx - 1) % pool[c]!.count]
        }

        state.currentMessages.append(ChatMessage(sender: .character, text: text))
    }
}

// MARK: - 危機オーバーレイ

struct CrisisOverlayView: View {
    @Binding var isPresented: Bool
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("大丈夫？")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("今、とてもしんどい気持ちがあるんだね。\n一人で抱えないでほしい。")
                    .font(.system(size: 15, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                VStack(spacing: 12) {
                    Link(destination: URL(string: "tel://0120279338")!) {
                        Label("よりそいホットライン（24時間）", systemImage: "phone.fill")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(red: 0.82, green: 0.25, blue: 0.25))
                            )
                    }
                    Link(destination: URL(string: "tel://0570783556")!) {
                        Label("いのちの電話", systemImage: "phone.fill")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(red: 0.80, green: 0.48, blue: 0.22))
                            )
                    }
                }
                Button {
                    isPresented = false
                    onContinue()
                } label: {
                    Text("話を続ける")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
        }
    }
}
