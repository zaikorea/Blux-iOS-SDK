import Foundation

/// ObjC 런타임(NSClassFromString)을 통해 접근해야 합니다.
/// 빌드 시점 기본 스테이지가 prod인 경우 동작하지 않습니다.
@objc(BluxStageSwitcher)
class StageSwitcher: NSObject {
    @objc static func setStage(_ stageValue: String) {
        let stage = Stage.from(stageValue)
        Stage.setStage(stage)
    }

    @objc static func resetStage() {
        Stage.resetStage()
    }
}
