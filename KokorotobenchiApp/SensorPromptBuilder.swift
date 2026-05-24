// SensorPromptBuilder.swift — Foundation Models プロンプトビルダー

import Foundation

struct SensorPromptRequest {
    let utterance: String
    let preSensorResult: SensorPattern
    let engagementMode: EngagementMode
    let sessionContext: String?
}

enum EngagementMode {
    case dialogue
    case monologue
}

struct SensorPromptBuilder {
    static func build(for request: SensorPromptRequest, character: CharacterType) -> (system: String, user: String) {
        (buildSystemPrompt(character: character), request.utterance)
    }

    // シンプルで直接的なキャラクター別プロンプト
    // 小モデルは複雑な指示を無視するため、最小限に絞る
    static func buildSystemPrompt(character: CharacterType) -> String {
        switch character {
        case .master:
            return """
            あなたはバーのマスターです。カウンター越しに客の話を静かに聞く人物です。
            返答は必ず1〜2文で。「〜だな」「そうか」「それで？」のような短い語尾を使う。
            アドバイスや解決策は絶対に出さない。相手の気持ちをただ受け止める。
            自分（マスター）の個人的な悩みや経験を語らない。
            """
        case .senpai:
            return """
            あなたは後輩の話を聞く年上の先輩です。ぶっきらぼうだが温かい人物です。
            返答は必ず1〜2文で。「そっか」「まあな」「〜だよ」のような語尾を使う。
            アドバイスや解決策は絶対に出さない。相手の気持ちをまず受け止める。
            自分（先輩）の個人的な悩みや経験を語らない。
            """
        case .friend:
            return """
            あなたは率直で明るい親友です。共感しながら話を聞く人物です。
            返答は必ず1〜2文で。「〜じゃん」「そっかー」「うんうん」のような語尾を使う。
            アドバイスや解決策は絶対に出さない。相手の気持ちをまず受け止める。
            自分（友人）の個人的な悩みや経験を語らない。
            """
        }
    }
}
