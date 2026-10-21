//
//  BluxUser.swift
//  BluxClient
//
//  Copyright © 2026 Blux. All rights reserved.
//

import Foundation

/// SDK가 저장하고 있는 현재 유저의 식별자.
///
/// `initialize`·`signIn`·`signOut`은 서버 응답을 받은 뒤에 값을 갱신하므로, 여기서 읽는 값은
/// 진행 중인 요청의 결과가 아니라 마지막으로 저장된 값이다. 첫 설치에서 `initialize`가 끝나기 전에는 `nil`이다.
///
/// Android SDK의 `BluxUser`와 이름을 맞춰 wrapper SDK가 두 플랫폼을 같은 이름으로 부른다.
public enum BluxUser {
    /// 블럭스 유저 ID(`blux_user_id`).
    public static func getId() -> String? {
        SdkConfig.bluxIdInUserDefaults
    }

    /// 디바이스 ID(`device_id`).
    public static func getDeviceId() -> String? {
        SdkConfig.deviceIdInUserDefaults
    }
}
