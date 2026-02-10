#if ENABLE_STAGE_SWITCHING
    import Foundation

    /// 이 클래스는 ENABLE_STAGE_SWITCHING 플래그가 설정된 빌드(local/dev/stg)에만 포함됩니다.
    /// 외부 사용자에게 공개되지 않습니다.
    /// ObjC 런타임(NSClassFromString)을 통해 접근해야 합니다.
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
#endif
