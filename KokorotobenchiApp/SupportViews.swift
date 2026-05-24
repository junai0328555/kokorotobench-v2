// SupportViews.swift
// こころとベンチ
// オンボーディング・診断・設定・記録

import SwiftUI

// MARK: - A-1: AppRootView (スプラッシュ + 遷移管理)

struct AppRootView: View {
    @State private var appState = AppState()
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
                        }
                    }
            } else if !appState.isOnboardingComplete {
                OnboardingView().environment(appState)
            } else if !appState.isDiagnosisComplete {
                DiagnosisView().environment(appState)
            } else {
                HomeView().environment(appState)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboardingComplete)
        .animation(.easeInOut(duration: 0.3), value: appState.isDiagnosisComplete)
    }
}

// MARK: - A-1: SplashView

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🌱")
                    .font(.system(size: 72))
                Text("こころとベンチ")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - A-2〜A-4: OnboardingView

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @State private var step = 0
    @State private var selectedCharacter: CharacterType = .master

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch step {
            case 0: plantExplanationStep
            case 1: characterSelectStep
            case 2: disclaimerStep
            default: EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var plantExplanationStep: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("🌱")
                .font(.system(size: 80))
            Text("あなたの植物を育てよう")
                .font(.title2.weight(.semibold))
            Text("話しかけるたびに、心の植物が少しずつ育ちます。\nまずは話し相手を選んでください。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("次へ") { step = 1 }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            Spacer(minLength: 32)
        }
    }

    private var characterSelectStep: some View {
        VStack(spacing: 24) {
            Text("話し相手を選ぶ")
                .font(.title2.weight(.semibold))
                .padding(.top, 48)

            VStack(spacing: 12) {
                characterButton(.master)
                characterButton(.senpai)
                characterButton(.friend)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("次へ") { step = 2 }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            Spacer(minLength: 32)
        }
    }

    private var disclaimerStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "info.circle").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("ご利用にあたって")
                .font(.title2.weight(.semibold))
            Text("このアプリはAIとの対話を通じて自己理解を深めるためのツールです。医療的な診断やアドバイスを行うものではありません。\n\n心理的なサポートが必要な場合は、専門家にご相談ください。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("同意してはじめる") {
                state.selectedCharacter = selectedCharacter
                state.isOnboardingComplete = true
                state.save()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            Spacer(minLength: 32)
        }
    }

    private func characterDesc(_ c: CharacterType) -> String {
        switch c {
        case .master: return "落ち着いた大人。言葉少なだが一言が刺さる。"
        case .senpai: return "少しぶっきらぼうだけど温かい。"
        case .friend: return "率直で明るく、共感しつつズバッと言う。"
        }
    }

    private func characterButton(_ character: CharacterType) -> some View {
        Button {
            selectedCharacter = character
        } label: {
            HStack(spacing: 16) {
                Text(character.emoji).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.displayName).font(.body.weight(.medium)).foregroundStyle(.primary)
                    Text(characterDesc(character)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if selectedCharacter == character {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedCharacter == character
                        ? Color.accentColor.opacity(0.08)
                        : Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - C-1: DiagnosisView (スキーマ診断 5問)

struct DiagnosisView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private let questions: [(text: String, domain: Int)] = [
        ("人から見捨てられたり、裏切られたりすることをよく心配する", 1),
        ("一人では物事をうまくやり遂げられないと感じることが多い", 2),
        ("他人の気持ちや期待に応えることを優先しすぎてしまう", 3),
        ("自分に厳しく、感情を表に出すことが難しいと感じる", 4),
        ("ルールや制限に縛られることが苦手で、衝動的になりやすい", 5)
    ]

    @State private var answers: [Int: Int] = [:]
    @State private var currentQ = 0
    @State private var showResult = false
    @State private var resultPlant: PlantType = .nogruse

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                if showResult {
                    resultView
                } else {
                    questionView
                }
            }
            .navigationTitle(showResult ? "診断結果" : "スキーマ診断")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showResult {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("スキップ") {
                            state.isDiagnosisComplete = true
                            state.save()
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var questionView: some View {
        VStack(spacing: 32) {
            ProgressView(value: Double(currentQ), total: Double(questions.count))
                .padding(.horizontal, 32).padding(.top, 16)

            Text("Q\(currentQ + 1) / \(questions.count)")
                .font(.caption).foregroundStyle(.tertiary)

            Text(questions[currentQ].text)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        answers[questions[currentQ].domain] = (answers[questions[currentQ].domain] ?? 0) + score
                        if currentQ < questions.count - 1 {
                            withAnimation { currentQ += 1 }
                        } else {
                            computeResult()
                        }
                    } label: {
                        Text(scoreLabel(score))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 32)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(resultPlant.emoji).font(.system(size: 80))
            Text(resultPlant.displayName)
                .font(.title2.weight(.semibold))
            Text(plantDescription(resultPlant))
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("はじめる") {
                state.completeDiagnosis(plantType: resultPlant)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            Spacer(minLength: 32)
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 1: return "1 — 全くあてはまらない"
        case 2: return "2 — あまりあてはまらない"
        case 3: return "3 — どちらでもない"
        case 4: return "4 — ややあてはまる"
        case 5: return "5 — とてもあてはまる"
        default: return "\(score)"
        }
    }

    private func computeResult() {
        guard let maxDomain = answers.max(by: { $0.value < $1.value })?.key else {
            resultPlant = .nogruse
            showResult = true
            return
        }
        switch maxDomain {
        case 1: resultPlant = .sumire
        case 2: resultPlant = .tanpopo
        case 3: resultPlant = .chamomile
        case 4: resultPlant = .saboten
        case 5: resultPlant = .himawari
        default: resultPlant = .nogruse
        }
        withAnimation { showResult = true }
    }

    private func plantDescription(_ plant: PlantType) -> String {
        switch plant {
        case .sumire:    return "人とのつながりやぬくもりを大切にする、繊細な心の持ち主。"
        case .tanpopo:   return "自分の力を信じることが難しくなりやすいが、どんな場所でも根を張る強さがある。"
        case .chamomile: return "他者に優しく寄り添うことが得意な、思いやりの深い人。"
        case .saboten:   return "自分に厳しく、感情を内に秘めながらも、強く生きている。"
        case .himawari:  return "エネルギーに満ち、自由を求める。衝動的な面もあるが活力がある。"
        case .nogruse:   return "複数の傾向が混じり合っている、ユニークな心の持ち主。"
        }
    }
}

// MARK: - G-1: SettingsView

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("植物") {
                    HStack {
                        Text("現在の植物")
                        Spacer()
                        Text("\(state.plantType.emoji) \(state.plantType.displayName)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("成長段階")
                        Spacer()
                        Text("Stage \(state.plantStage.rawValue) · \(state.plantStage.displayName)")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("利用状況") {
                    HStack {
                        Text("セッション数")
                        Spacer()
                        Text("\(state.sessionCount)回").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("気づき記録")
                        Spacer()
                        Text("\(state.insightEntries.count)件").foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("スキーマ診断をやり直す") {
                        state.isDiagnosisComplete = false
                        state.plantType = .nogruse
                        state.save()
                        dismiss()
                    }
                    Button("データをリセット", role: .destructive) {
                        showResetConfirm = true
                    }
                }
                Section("情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    NavigationLink("免責事項") { DisclaimerView() }
                }
            }
            .navigationTitle("設定").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
            .alert("データをリセット", isPresented: $showResetConfirm) {
                Button("リセット", role: .destructive) {
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
                    state.isOnboardingComplete = false
                    state.isDiagnosisComplete = false
                    state.plantType = .nogruse
                    state.plantStage = .seed
                    state.sessionCount = 0
                    state.insightEntries = []
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべてのデータが削除されます。この操作は元に戻せません。")
            }
        }
    }
}

// MARK: - E-1: InsightsView + InsightEntryCard

struct InsightsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if state.insightEntries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "book.closed").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text("まだ気づきの記録がありません").foregroundStyle(.secondary)
                        Text("会話の中で深い問いかけが生まれると、\nここに記録されます。")
                            .font(.caption).foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    List(state.insightEntries) { entry in
                        InsightEntryCard(entry: entry)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("気づきの記録").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }
    }
}

struct InsightEntryCard: View {
    let entry: InsightEntry

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.character.emoji).font(.caption)
                Text(entry.character.displayName).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Text("「\(entry.userQuote)」")
                .font(.subheadline).italic()
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(entry.characterQuote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - DisclaimerView

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("このアプリについて")
                    .font(.title3.weight(.semibold))
                Text("「こころとベンチ」は、AIとの対話を通じて自己理解を深めるためのアプリです。")
                Text("医療行為・心理療法・カウンセリングではありません。診断・治療を目的とするものではなく、専門的なサポートの代替にはなりません。")
                    .foregroundStyle(.secondary)
                Text("心理的なサポートが必要な場合は、医療機関や専門家にご相談ください。")
                Divider()
                Text("相談窓口")
                    .font(.subheadline.weight(.semibold))
                Link("よりそいホットライン: 0120-279-338（24時間）", destination: URL(string: "tel://0120279338")!)
                Link("いのちの電話: 0570-783-556", destination: URL(string: "tel://0570783556")!)
            }
            .padding(24)
        }
        .navigationTitle("免責事項").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0)))
    }
}
