# Blux iOS SDK 행동데이터 연동 안내 문서

[![Version](https://img.shields.io/cocoapods/v/BluxClient.svg?style=flat)](https://cocoapods.org/pods/BluxClient)
[![License](https://img.shields.io/cocoapods/l/BluxClient.svg?style=flat)](https://cocoapods.org/pods/BluxClient)
[![Platform](https://img.shields.io/cocoapods/p/BluxClient.svg?style=flat)](https://cocoapods.org/pods/BluxClient)

### Installation

- Blux iOS SDK의 경우 cocoapods package manager를 통해 배포되어 있습니다. 

#### CocoaPods

- Podfile

```podfile
// 파일 최상단에 아래 줄을 추가하여 Dynamic Framework를 활성화합니다.
use_frameworks!

target 'YOUR_PROJECT_NAME' do
  // 아래 줄 추가
  pod 'BluxClient', '0.3.3'  
end

// 파일 최하단의 아래 줄 추가
// 앞서 입력한 Extension의 Product Name을 target 이름으로 설정합니다.
target 'BluxNotificationServiceExtenstion' do
  pod 'BluxClient', '0.3.3'
end
```



### **Initialize**

---

- 필요 변수 : `클라이언트 ID`, `API 키`
- setLogLevel 을 제외한 다른 모든 메소드는 `initialize`로 SDK가 초기화 된 이후에 호출해야 합니다.

```swift
BluxClient.setLogLevel()
BluxClient.initialize(launchOptions, bluxClientId: BLUX_CLIENT_ID, bluxAPIKey: BLUX_API_KEY) { error in
  if let error = error {
    print("BluxClient initialize error: \(error)")
  } else {
    BluxClient.signIn(userId: "USER_ID")
  }
}
```



### signIn

- 회원 유저에 대해서 부여하고 계시는 유저 ID를 넘겨주시면 됩니다.
- Blux 서비스에서 같은 `UserId`를 가지는 유저는 같은 유저로 식별됩니다.
- 비회원 유저에서 회원 유저로 식별되는 시점에 아래 함수를 호출해주세요.
- 회원 유저가 앱을 실행하는 시점 (자동 로그인이 되어 있는 경우)에도 `initialize` 메소드 호출 이후에 실행되어야 합니다.

```swift
BluxClient.signIn(userId: "USER_ID")
```



### signOut

- 유저가 서비스에서 로그아웃 한 경우 호출해주시면 됩니다.
- signIn 함수와 함께 유저들을 더 잘 식별하기 위해 사용됩니다.

```swift
BluxClient.signOut()
```



### sendEvent

#### 상품 상세 페이지 진입

: 유저가 제품 상세보기 페이지에 들어가거나, 영상을 시청하는 등 클릭을 통해 어떠한 아이템에 대해 관심을 보이는 행동을 보일 때 사용 가능한 이벤트입니다.

---

```swift
let eventRequest = try AddProductDetailViewEvent.Builder(itemId: "ITEM_ID").build()
BluxClient.sendRequest(eventRequest)
```



#### 상품 좋아요

: 유저가 제품이나 영상 등에 좋아요를 누르거나, 찜을 해두는 등 적극적인 관심을 보이는 행동을 할 때 사용 가능한 이벤트입니다.

---

```swift
let eventRequest = try AddLikeEvent.Builder(itemId: "ITEM_ID").build()
BluxClient.sendRequest(eventRequest)
```



#### 상품 장바구니 담기

: 이커머스에서 유저가 제품을 장바구니에 담는 행동을 할 때 사용 가능한 이벤트입니다.

---

```swift
let eventRequest = try AddCartaddEvent.Builder(itemId: "ITEM_ID").build()
BluxClient.sendRequest(eventRequest)
```



#### 상품 구매

: 유저가 제품을 구매했을 때 사용 가능한 이벤트입니다. 추가 인풋으로 `price`가 요구되며, 제품의 구매 당시 가격을 기록하면 됩니다.

---

- **_동일 상품 복수 구매_**
  - price 파라미터의 경우, 해당 상품 판매를 통한 총 매출을 계산할 때 활용됩니다. 추천에 의한 매출 기여액 지표를 보여드릴 때 사용되는 값으로 만약 5,000원짜리 상품을 5개 구매하였다면, 25,000 을 입력하시면 됩니다.
- **_복수 상품 구매_**
  - `AddPurchaseEvent` 객체를 각 상품 구매건에 맞춰서 생성한 후 list 형태로 넘겨주시면 됩니다.

```swift
let eventRequest = try AddPurchaseEvent.Builder().addPurchase("ITEM_ID", 2000.0, 1).build()
BluxClient.sendRequest(eventRequest)
```

```swift
// 복수 상품을 구매한 경우
let eventRequest = try AddPurchaseEvent.Builder().addPurchase("ITEM_ID_1", 2000.0, 1).addPurchase("ITEM_ID_2", 1000.0, 5).addPurchase("ITEM_ID_3", 10000.0, 2).build()
BluxClient.sendRequest(eventRequest)
```

