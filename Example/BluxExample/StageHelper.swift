import BluxClient

/// 공개되지 않은 `StageSwitcher` 클래스에 ObjC 런타임을 사용해 접근합니다.
enum StageHelper {
    /// 런타임에 스테이지를 변경합니다.
    /// StageSwitcher가 없는 빌드(prod)에서는 false를 반환합니다.
    @discardableResult
    static func setStage(_ stage: Stage) -> Bool {
        guard let switcherClass = NSClassFromString("BluxStageSwitcher") as? NSObject.Type else {
            print("[StageHelper] StageSwitcher not available (prod build)")
            return false
        }
        let selector = NSSelectorFromString("setStage:")
        guard switcherClass.responds(to: selector) else { return false }
        switcherClass.perform(selector, with: stage.rawValue)
        return true
    }

    /// 런타임에 변경된 스테이지를 빌드 시점의 스테이지로 되돌립니다.
    static func resetStage() {
        guard let switcherClass = NSClassFromString("BluxStageSwitcher") as? NSObject.Type else {
            return
        }
        let selector = NSSelectorFromString("resetStage")
        guard switcherClass.responds(to: selector) else { return }
        switcherClass.perform(selector)
    }

    static func getStage() -> Stage {
        Stage.current
    }
}
