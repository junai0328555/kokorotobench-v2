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
                    Spacer(minLength: 32)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showChat) { ChatView().environment(state) }
        .sheet(isPresented: $showDiagnosis) { DiagnosisView().environment(state) }
        .sheet(isPresented: $showSettings) { SettingsView().environment(state) }
        .sheet(isPresented: $showInsights) { InsightsView().environment(state) }
        .sheet(isPresented: $showCharacterPicker) { CharacterPickerView().environment(state) }
        .onAppear { state.checkRestingState() }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGreen).opacity(0.04), Color(.systemBackground)],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.title3).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showInsights = true } label: {
                Image(systemName: "book.closed").font(.title3).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24).padding(.top, 8)
    }

    private var plantArea: some View {
        PlantView(
            plantType: state.plantType, stage: state.plantStage,
            condition: state.plantCondition, character: state.selectedCharacter
        ) { state.waterPlant() }
        .padding(.horizontal, 24)
    }

    private var stageLabel: some View {
        Text("Stage \(state.plantStage.rawValue) · \(state.plantStage.displayName)")
            .font(.caption).foregroundStyle(.tertiary).padding(.top, 8)
    }

    private var actionArea: some View {
        VStack(spacing: 16) {
            Button {
                state.startNewSession(); showChat = true
            } label: {
                Text("話しかける")
                    .font(.title3.weight(.medium)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor))
            }
            .padding(.horizontal, 32)

            HStack(spacing: 12) {
                Button { showDiagnosis = true } label: {
                    Text(state.isDiagnosisComplete ? "診断を確認" : "スキーマ診断")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
                Button { showCharacterPicker = true } label: {
                    HStack(spacing: 4) {
                        Text(state.selectedCharacter.emoji)
                        Text("キャラ変更").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
            }
        }
    }
}

struct CharacterPickerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    characterRow(.master)
                    Divider().padding(.leading, 72)
                    characterRow(.senpai)
                    Divider().padding(.leading, 72)
                    characterRow(.friend)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
            .navigationTitle("話し相手を選ぶ").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }
    }

    private func characterRow(_ character: CharacterType) -> some View {
        Button {
            state.selectedCharacter = character; state.save(); dismiss()
        } label: {
            HStack(spacing: 16) {
                Text(character.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.displayName).font(.body).foregroundStyle(.primary)
                    Text(desc(character)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if state.selectedCharacter == character {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
    }

    private func desc(_ c: CharacterType) -> String {
        switch c {
        case .master: return "落ち着いた大人。言葉少なだが一言が刺さる。"
        case .senpai: return "少しぶっきらぼうだけど温かい。"
        case .friend: return "率直で明るく、共感しつつズバッと言う。"
        }
    }
}
