// SensorPromptBuilder.swift — Foundation Models プロンプトビルダー

import Foundation

struct SensorPromptRequest {
    let utterance: String
    let preSensorResult: SensorPattern
    let engagementMode: EngagementMode
    let sessionContext: String?
}

enum EngagementMode {
    case dialogue   // 問いかけ可
    case monologue  // 問いかけ保留
}

struct SensorPromptBuilder {
    static func build(for request: SensorPromptRequest, character: CharacterType) -> (system: String, user: String) {
        let system = buildSystemPrompt(character: character, pattern: request.preSensorResult)
        let user = buildUserPrompt(request: request)
        return (system, user)
    }

    private static func buildSystemPrompt(character: CharacterType, pattern: SensorPattern) -> String {
        """
        \(characterPersona(character))

        【重要】あなたはキャラクターとしてユーザーに話しかけています。ユーザーの代わりに話したり、ユーザーの気持ちを代弁するのではありません。
        - 必ず1〜2文で返す。長くならない
        - アドバイスや解決策を出さない。まず相手の気持ちを受け止める
        - 同じ言葉・同じ問いかけを繰り返さない
        - 「大丈夫だよ」「そんなことはないよ」は使わない
        - 感情的な発言には短く温かく受け止める
        """
    }

    private static func buildUserPrompt(request: SensorPromptRequest) -> String {
        var prompt = request.utterance
        if request.engagementMode == .monologue {
            prompt += "\n（注：短い独り言のような発話です。深掘りより受容を優先してください）"
        }
        return prompt
    }

    private static func characterPersona(_ character: CharacterType) -> String {
        switch character {
        case .master:
            return "あなたはバーのマスターです。落ち着いた大人の口調で、言葉少なく、でも一言が刺さるような返し方をします。「〜だな」「〜じゃないか」のような語尾を使います。"
        case .senpai:
            return "あなたは年上の先輩です。少しぶっきらぼうだけど温かく、「〜だよ」「〜じゃないか」「まあ〜」のような語尾を使います。"
        case .friend:
            return "あなたはゲイの友人です。率直で明るく、共感しつつズバッと言います。「〜じゃん」「〜だよ！」のような語尾を使います。"
        }
    }
}
