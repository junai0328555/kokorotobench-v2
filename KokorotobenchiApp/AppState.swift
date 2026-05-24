// AppState.swift
// こころとベンチ
// アプリ全体の状態管理・データモデル

import Foundation

// MARK: - キャラクター

enum CharacterType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case master = "master"
    case senpai = "senpai"
    case friend = "friend"

    var displayName: String {
        switch self {
        case .master: return "バーのマスター"
        case .senpai: return "年上の先輩"
        case .friend: return "ゲイの友人"
        }
    }

    var emoji: String {
        switch self {
        case .master: return "🥃"
        case .senpai: return "🤝"
        case .friend: return "✨"
        }
    }

    var firstMessage: String {
        switch self {
        case .master: return "やあ。どうした？"
        case .senpai: return "おう、久しぶり。最近どうだ？"
        case .friend: return "きたきた！今日どんな感じ？"
        }
    }
}

// MARK: - 植物

enum PlantType: String, Codable {
    case sumire    // すみれ（切断と拒絶）
    case tanpopo   // たんぽぽ（自律性の障害）
    case chamomile // カモミール（他者への方向づけ）
    case saboten   // サボテン（過度の警戒と抑制）
    case himawari  // ひまわり（制限の障害）
    case nogruse   // 名もなき野草（未診断・複合）

    var displayName: String {
        switch self {
        case .sumire:    return "すみれ"
        case .tanpopo:   return "たんぽぽ"
        case .chamomile: return "カモミール"
        case .saboten:   return "サボテン"
        case .himawari:  return "ひまわり"
        case .nogruse:   return "名もなき野草"
        }
    }

    var emoji: String {
        switch self {
        case .sumire:    return "🌸"
        case .tanpopo:   return "🌼"
        case .chamomile: return "🌿"
        case .saboten:   return "🌵"
        case .himawari:  return "🌻"
        case .nogruse:   return "🌱"
        }
    }
}

enum PlantStage: Int, Codable {
    case seed    = 0  // 種
    case sprout  = 1  // 芽吹き
    case leaf    = 2  // 小さな葉
    case stem    = 3  // 茎が伸びる
    case bud     = 4  // つぼみ
    case bloom   = 5  // 開花
    case fruit   = 6  // 実り・種を飛ばす

    var displayName: String {
        switch self {
        case .seed:   return "種"
        case .sprout: return "芽吹き"
        case .leaf:   return "小さな葉"
        case .stem:   return "茎が伸びる"
        case .bud:    return "つぼみ"
        case .bloom:  return "開花"
        case .fruit:  return "実り"
        }
    }
}

enum PlantCondition {
    case normal
    case justWatered
    case insightLight
    case resting
    case afterStorm
}

// MARK: - チャットメッセージ

enum MessageSender: Codable {
    case user
    case character
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let sender: MessageSender
    let text: String
    let timestamp: Date
    var hasDeepQuestion: Bool

    init(sender: MessageSender, text: String, hasDeepQuestion: Bool = false) {
        self.id = UUID()
        self.sender = sender
        self.text = text
        self.timestamp = Date()
        self.hasDeepQuestion = hasDeepQuestion
    }
}

// MARK: - 記録エントリ

struct InsightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let character: CharacterType
    let userQuote: String
    let characterQuote: String
    let plantStage: PlantStage

    init(character: CharacterType, userQuote: String, characterQuote: String, stage: PlantStage) {
        self.id = UUID()
        self.date = Date()
        self.character = character
        self.userQuote = userQuote
        self.characterQuote = characterQuote
        self.plantStage = stage
    }
}

// MARK: - アプリ全体の状態

@Observable
class AppState {
    var isOnboardingComplete: Bool = false
    var isDiagnosisComplete: Bool = false
    var selectedCharacter: CharacterType = .master
    var plantType: PlantType = .nogruse
    var plantStage: PlantStage = .seed
    var plantCondition: PlantCondition = .normal
    var currentMessages: [ChatMessage] = []
    var isResponding: Bool = false
    var insightEntries: [InsightEntry] = []
    var sessionCount: Int = 0
    var lastSessionDate: Date?

    init() { load() }

    func waterPlant() { plantCondition = .justWatered }
    func addInsightLight() { plantCondition = .insightLight }

    func checkRestingState() {
        guard let last = lastSessionDate else { return }
        if Date().timeIntervalSince(last) > 60 * 60 * 24 * 7 {
            plantCondition = .resting
        }
    }

    func startNewSession() {
        currentMessages = []
        sessionCount += 1
        lastSessionDate = Date()
        plantCondition = .normal
    }

    func endSession(hadDeepQuestion: Bool) {
        if hadDeepQuestion { addInsightLight(); advancePlantStageIfNeeded() }
        save()
    }

    private func advancePlantStageIfNeeded() {
        let thresholds: [PlantStage: Int] = [
            .seed: 0, .sprout: 1, .leaf: 5, .stem: 10, .bud: 20, .bloom: 30, .fruit: 50
        ]
        let deepQuestionCount = insightEntries.count
        for stage in PlantStage.allCases.reversed() {
            if deepQuestionCount >= (thresholds[stage] ?? 0) {
                if stage.rawValue > plantStage.rawValue { plantStage = stage }
                break
            }
        }
    }

    func addInsight(userQuote: String, characterQuote: String) {
        let entry = InsightEntry(character: selectedCharacter, userQuote: userQuote, characterQuote: characterQuote, stage: plantStage)
        insightEntries.insert(entry, at: 0)
        save()
    }

    func completeDiagnosis(plantType: PlantType) {
        self.plantType = plantType
        self.plantStage = .sprout
        self.isDiagnosisComplete = true
        save()
    }

    private let defaults = UserDefaults.standard

    func save() {
        defaults.set(isOnboardingComplete, forKey: "onboardingComplete")
        defaults.set(isDiagnosisComplete, forKey: "diagnosisComplete")
        defaults.set(selectedCharacter.rawValue, forKey: "character")
        defaults.set(plantType.rawValue, forKey: "plantType")
        defaults.set(plantStage.rawValue, forKey: "plantStage")
        defaults.set(sessionCount, forKey: "sessionCount")
        defaults.set(lastSessionDate, forKey: "lastSessionDate")
        if let data = try? JSONEncoder().encode(insightEntries) { defaults.set(data, forKey: "insightEntries") }
    }

    func load() {
        isOnboardingComplete = defaults.bool(forKey: "onboardingComplete")
        isDiagnosisComplete  = defaults.bool(forKey: "diagnosisComplete")
        if let c = defaults.string(forKey: "character"), let char = CharacterType(rawValue: c) { selectedCharacter = char }
        if let p = defaults.string(forKey: "plantType"), let plant = PlantType(rawValue: p) { plantType = plant }
        if let s = defaults.integer(forKey: "plantStage") as Int?, let stage = PlantStage(rawValue: s) { plantStage = stage }
        sessionCount = defaults.integer(forKey: "sessionCount")
        lastSessionDate = defaults.object(forKey: "lastSessionDate") as? Date
        if let data = defaults.data(forKey: "insightEntries"), let entries = try? JSONDecoder().decode([InsightEntry].self, from: data) { insightEntries = entries }
    }
}

extension PlantStage: CaseIterable {
    static var allCases: [PlantStage] = [.seed, .sprout, .leaf, .stem, .bud, .bloom, .fruit]
}
