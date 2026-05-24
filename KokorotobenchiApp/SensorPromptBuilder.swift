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

        ユーザーの話をよく聞き、気持ちに寄り添って応答してください。
        - アドバイスや答えを出さず、まず気持ちを受け止める
        - 詳細を聞く前に決めつけたり評価したりしない
        - 毎回同じ言葉にならないよう、会話の流れに沿って自然に応答する
        - ユーザーのメッセージを先頭で繰り返さない
        - 同じ問いかけを繰り返さない（ユーザーが答えたら次の話題へ進む）
        - 短い発話には短く返す。問いかけは1回したら次は別の応答にする
        - 「大丈夫だよ」「そんなことはないよ」「すべき」は使わない
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
