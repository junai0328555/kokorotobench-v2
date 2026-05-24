// PlantView.swift
// こころとベンチ
// ホーム画面の植物表示・アニメーション

import SwiftUI

struct PlantView: View {
    let plantType: PlantType
    let stage: PlantStage
    let condition: PlantCondition
    let character: CharacterType
    var onTap: () -> Void = {}

    @State private var isWiggling = false
    @State private var showMessage = false
    @State private var tapMessage = ""
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            if condition == .insightLight {
                Circle()
                    .fill(RadialGradient(colors: [Color.yellow.opacity(0.3), Color.clear], center: .center, startRadius: 20, endRadius: 120))
                    .frame(width: 240, height: 240)
                    .opacity(glowOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { glowOpacity = 1 }
                    }
            }

            VStack(spacing: 8) {
                Text(plantEmoji)
                    .font(.system(size: plantSize))
                    .rotationEffect(.degrees(isWiggling ? -5 : 5))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isWiggling)
                    .onAppear { isWiggling = true }

                if condition == .justWatered {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Text("✦")
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.7))
                                .offset(y: isWiggling ? -4 : 4)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: isWiggling)
                        }
                    }
                }
            }
            .onTapGesture { handleTap(); onTap() }

            if showMessage {
                VStack {
                    Spacer()
                    HStack {
                        Text(character.emoji).font(.caption)
                        Text(tapMessage)
                            .font(.caption).foregroundStyle(.secondary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    }
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(height: 200)
    }

    private var plantEmoji: String {
        switch stage {
        case .seed: return "🫘"
        case .sprout: return "🌱"
        case .leaf, .stem, .bud, .bloom: return plantType.emoji
        case .fruit: return plantType == .tanpopo ? "🌬️" : plantType.emoji
        }
    }

    private var plantSize: CGFloat {
        switch stage {
        case .seed: return 48; case .sprout: return 64; case .leaf: return 80
        case .stem: return 96; case .bud: return 100; case .bloom: return 112; case .fruit: return 120
        }
    }

    private func handleTap() {
        tapMessage = tapMessageText
        withAnimation(.spring(duration: 0.3)) { showMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) { showMessage = false }
        }
    }

    private var tapMessageText: String {
        switch (character, stage, condition) {
        case (.master, .seed, _): return "まだ何も見えないな。それでいい。"
        case (.master, .sprout, _): return "ちゃんと育ってる。あんたが話しかけてくれてるから。"
        case (.master, .leaf, _): return "この子、ちゃんと根を張ってるよ。"
        case (.master, .stem, _): return "方向性が出てきた感じがする。"
        case (.master, .bud, _): return "つぼみじゃん。すごいよ。"
        case (.master, .bloom, _): return "咲いたな。あんたが話し続けてくれたから。"
        case (.master, .fruit, _): return "実ったよ。次の自分へ。"
        case (.senpai, .seed, _): return "まあ、ここからだよな。"
        case (.senpai, .sprout, _): return "芽が出た。よかった。"
        case (.senpai, .leaf, _): return "葉っぱ増えてきたじゃないか。"
        case (.senpai, .stem, _): return "しっかりしてきたな。"
        case (.senpai, .bud, _): return "もうすぐ咲くぞ、これ。"
        case (.senpai, .bloom, _): return "咲いたか。お前がよく頑張った。"
        case (.senpai, .fruit, _): return "実まで育てた。立派なもんだ。"
        case (.friend, .seed, _): return "まだ土の中だけど、絶対出てくるよ！"
        case (.friend, .sprout, _): return "芽が出た〜！かわいいじゃん！"
        case (.friend, .leaf, _): return "葉っぱ出た！あなたのおかげだよ。"
        case (.friend, .stem, _): return "大きくなってきてる！"
        case (.friend, .bud, _): return "つぼみじゃん！もうすぐだよ！"
        case (.friend, .bloom, _): return "咲いた！きれい！すごいじゃん！"
        case (.friend, .fruit, _): return "実まで！感動した！次の自分へGO！"
        default: return "\(character.emoji) ここにいるよ。"
        }
    }
}
