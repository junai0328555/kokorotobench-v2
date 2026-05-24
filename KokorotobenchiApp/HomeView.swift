// HomeView.swift
// こころとベンチ — B-1：ホーム画面

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @State private var showChat = false
    @State private var showDiagnosis = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showCharacterPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    plantArea
                    Spacer()
                    stageLabel
                    Spacer(minLength: 24)
                    actionArea
                    Spacer(minLength: 36)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showChat)      { ChatView().environment(state) }
        .sheet(isPresented: $showDiagnosis)           { DiagnosisView().environment(state) }
        .sheet(isPresented: $showSettings)            { SettingsView().environment(state) }
        .sheet(isPresented: $showInsights)            { InsightsView().environment(state) }
        .sheet(isPresented: $showCharacterPicker)     { CharacterPickerView().environment(state) }
        .onAppear { state.checkRestingState() }
    }

    // MARK: - 背景

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.95),
                Color(red: 0.94, green: 0.97, blue: 0.93),
                Color(red: 0.98, green: 0.97, blue: 0.95)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - トップバー

    private var topBar: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Button { showInsights = true } label: {
                Image(systemName: "book.closed")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16).padding(.top, 4)
    }

    // MARK: - 植物エリア

    private var plantArea: some View {
        PlantView(
            plantType: state.plantType, stage: state.plantStage,
            condition: state.plantCondition, character: state.selectedCharacter
        ) { state.waterPlant() }
        .padding(.horizontal, 24)
    }

    // MARK: - ステージラベル

    private var stageLabel: some View {
        Text("Stage \(state.plantStage.rawValue) · \(state.plantStage.displayName)")
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
    }

    // MARK: - アクションエリア

    private var actionArea: some View {
        VStack(spacing: 16) {
            // 話しかけるボタン（大）
            Button {
                state.startNewSession(); showChat = true
            } label: {
                Text("話しかける")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(state.selectedCharacter.themeColor)
                    )
            }
            .padding(.horizontal, 32)

            // サブボタン行
            HStack(spacing: 12) {
                Button { showDiagnosis = true } label: {
                    Text(state.isDiagnosisComplete ? "診断を確認" : "スキーマ診断")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                }

                // キャラ変更ボタン：アバター表示
                Button { showCharacterPicker = true } label: {
                    HStack(spacing: 8) {
                        CharacterAvatarView(character: state.selectedCharacter, size: 28)
                        Text("キャラ変更")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
    }
}

// MARK: - キャラクター選択シート（カード型）

struct CharacterPickerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    characterCard(.master)
                    characterCard(.senpai)
                    characterCard(.friend)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color(red: 0.982, green: 0.973, blue: 0.957))
            .navigationTitle("話し相手を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .font(.system(size: 15, design: .rounded))
                }
            }
        }
    }

    private func characterCard(_ character: CharacterType) -> some View {
        let isSelected = state.selectedCharacter == character
        return Button {
            state.selectedCharacter = character
            state.save()
            dismiss()
        } label: {
            HStack(spacing: 18) {
                // 線画アバター（大）
                CharacterAvatarView(character: character, size: 76)

                VStack(alignment: .leading, spacing: 6) {
                    Text(character.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.12))
                    Text(desc(character))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(character.themeColor)
                        .font(.system(size: 22))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                    .shadow(
                        color: isSelected
                            ? character.themeColor.opacity(0.20)
                            : Color.black.opacity(0.06),
                        radius: isSelected ? 12 : 5,
                        x: 0, y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? character.themeColor.opacity(0.45) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func desc(_ c: CharacterType) -> String {
        switch c {
        case .master: return "落ち着いた大人。\n言葉少なだが、一言が刺さる。"
        case .senpai: return "少しぶっきらぼうだけど温かい。\n焦らず話を聞いてくれる。"
        case .friend: return "率直で明るく、ズバッと共感する。\nちゃんと聞いてるよ！"
        }
    }
}
