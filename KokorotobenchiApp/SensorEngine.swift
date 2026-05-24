// SensorEngine.swift
// こころとベンチ
// 警告センサー：①事実と推測の混同 / ②他者の課題の抱え込み 判定エンジン

import Foundation

enum SensorPattern: String {
    case factVsAssumption  = "事実と推測の混同"
    case taskOverload      = "他者の課題の抱え込み"
    case none
}

struct SensorResult {
    let pattern: SensorPattern
    let confidence: SensorConfidence
    let matchedSignals: [String]
    let requiresCooccurrence: Bool
}

enum SensorConfidence { case high, medium, pending }

private enum FactAssumptionSignals {
    static let presumptiveMarkers: [String] = [
        "に違いない", "に決まってる", "はずだ", "証拠だ", "ってことだ",
        "きっと", "絶対", "内心", "どうせ",
        "からして", "ってことは", "だろう", "だろうな", "んだろう", "んだろうな",
        "気がする", "気がして仕方ない"
    ]
    static let otherInnerStateMarkers: [String] = [
        "嫌ってる", "避けてる", "避けられる", "無視", "除外", "拒絶",
        "バカに", "見下し", "軽蔑", "除け者",
        "呆れてる", "迷惑", "うざい", "ウザ", "失望",
        "興味ない", "冷たく", "嫌われ",
        "笑ってる", "楽しんでる", "待ってる", "悪口", "笑い者",
        "責めてる", "責めている", "責める", "見捨て", "軽く見",
        "負担に", "負担だ"
    ]
    static let selfReferenceMarkers: [String] = ["私が悪い", "私のせい", "私が疲れ", "私がダメ", "自分が悪い", "自分のせい"]
    static let questionMarkers: [String] = ["だと思う？", "じゃないかな", "かな？", "でしょうか"]
    static let negationPrefixes: [String] = ["してるわけじゃないけど", "とかじゃないんだけど"]
}

private enum TaskOverloadSignals {
    static let otherNouns: [String] = ["後輩", "同僚", "上司", "家族", "親", "父", "母", "友達", "友人", "パートナー", "チーム", "みんな", "あいつ", "こいつ", "彼", "彼女"]
    static let obligationMarkers: [String] = [
        "私が全部", "私がすべて", "私が一人で",
        "しないと", "なきゃ", "なければ", "するしかない",
        "私がフォロー", "私がカバー", "私が背負", "私が引き受け",
        "私が解決", "私が支え", "私が埋め", "私が残る",
        "私が代わる", "私が励ます", "私が調整", "私が手伝",
        "私が残業", "私が我慢", "私が謝", "私が対応", "私が全部やる"
    ]
    static let roleInternalizationMarkers: [String] = ["私の役割", "私の仕事みたい", "私が背負ってる", "私が全部聴く"]
    static let emotionalObligationMarkers: [String] = ["申し訳ない", "放っておけない", "気が済まない"]
    static let clearResponsibilityMarkers: [String] = ["私の担当", "私の仕事だから", "担当者として"]
}

struct SensorEngine {
    static func analyze(_ utterance: String) -> SensorResult {
        let factResult = detectFactVsAssumption(utterance)
        if factResult.pattern != .none { return factResult }
        return detectTaskOverload(utterance)
    }

    private static func detectFactVsAssumption(_ text: String) -> SensorResult {
        var matched: [String] = []
        if FactAssumptionSignals.selfReferenceMarkers.contains(where: { text.contains($0) }) { return noResult() }
        if FactAssumptionSignals.questionMarkers.contains(where: { text.contains($0) }) { return noResult() }
        var hasPresumptive = false
        for m in FactAssumptionSignals.presumptiveMarkers {
            if text.contains(m) { hasPresumptive = true; matched.append("推量語: \(m)"); break }
        }
        guard hasPresumptive else { return noResult() }
        var hasOtherInner = false
        for m in FactAssumptionSignals.otherInnerStateMarkers {
            if text.contains(m) { hasOtherInner = true; matched.append("他者評価: \(m)"); break }
        }
        guard hasOtherInner else { return noResult() }
        for p in FactAssumptionSignals.negationPrefixes {
            if text.contains(p) { return SensorResult(pattern: .factVsAssumption, confidence: .medium, matchedSignals: matched, requiresCooccurrence: true) }
        }
        return SensorResult(pattern: .factVsAssumption, confidence: matched.count >= 2 ? .high : .medium, matchedSignals: matched, requiresCooccurrence: false)
    }

    private static func detectTaskOverload(_ text: String) -> SensorResult {
        var matched: [String] = []
        if TaskOverloadSignals.clearResponsibilityMarkers.contains(where: { text.contains($0) }) { return noResult() }
        var hasNoun = false
        for n in TaskOverloadSignals.otherNouns {
            if text.contains(n) { hasNoun = true; matched.append("他者名詞: \(n)"); break }
        }
        guard hasNoun else { return noResult() }
        var score = 0
        for m in TaskOverloadSignals.obligationMarkers { if text.contains(m) { score += 1; matched.append("義務形: \(m)") } }
        for m in TaskOverloadSignals.roleInternalizationMarkers { if text.contains(m) { score += 1; matched.append("役割: \(m)") } }
        for m in TaskOverloadSignals.emotionalObligationMarkers { if text.contains(m) { score += 1; matched.append("感情義務: \(m)") } }
        guard score >= 1 else { return noResult() }
        return SensorResult(pattern: .taskOverload, confidence: score >= 2 ? .medium : .pending, matchedSignals: matched, requiresCooccurrence: true)
    }

    private static func noResult() -> SensorResult {
        SensorResult(pattern: .none, confidence: .medium, matchedSignals: [], requiresCooccurrence: false)
    }
}

class SensorSession {
    private var taskOverloadCount = 0
    private var hasNegativeGroup = false

    func evaluate(utterance: String, currentGroup: Int) -> SensorPattern? {
        if currentGroup == 2 || currentGroup == 3 { hasNegativeGroup = true }
        let result = SensorEngine.analyze(utterance)
        switch result.pattern {
        case .factVsAssumption:
            if result.requiresCooccurrence { return nil }
            return .factVsAssumption
        case .taskOverload:
            taskOverloadCount += 1
            if hasNegativeGroup { return .taskOverload }
            if taskOverloadCount >= 2 { return .taskOverload }
            return nil
        case .none: return nil
        }
    }

    func reset() { taskOverloadCount = 0; hasNegativeGroup = false }
}
