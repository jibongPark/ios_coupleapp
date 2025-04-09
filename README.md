# 📦 MemoryBox

> **MemoryBox**는 사랑과 우정, 여행의 추억을 감성적으로 기록하고 공유할 수 있는  
> 일정 + 다이어리 + 지도 기반의 통합 기록 앱입니다.

---

## ✨ 주요 기능

📅 **데이트 & 여행 일정 관리**  
  캘린더를 통해 과거와 미래의 소중한 일정을 한눈에 확인할 수 있어요.

📖 **다이어리 기능**  
  하루의 감정, 추억, 사진을 기록하며 내 일상을 풍부하게 담아보세요.

🗺 **지도 기반 추억 저장**  
  함께한 장소를 지도 위에 남기고, 다시 찾고 싶은 장소로 기록할 수 있어요.

---

## 🚀 설치 및 실행

### iOS *(심사중)*
App Store에서 "MemoryBox"를 검색하거나, 아래 링크를 통해 설치하세요.  

### Android *(예정)*
Google Play 출시 예정입니다.

---


## 아키텍처

이 프로젝트는 **기능(feature)** 중심으로 모듈을 분리하고, 각 기능을 **Interface**, **Data**, **Domain** 레이어로 구분하여 유지보수성과 확장성을 높였습니다.

### 🔹 앱(App) 모듈
- `CalendarFeature_demo_app`: 캘린더 기능만 테스트하는 샘플 앱
- `MapFeature_demo_app`: 지도 기능만 테스트하는 샘플 앱
- `coupleapp`: 메인 앱, 모든 기능 통합

### 🔸 기능 모듈
- `CalendarFeature`: 캘린더 기능 UI 및 로직 ( TCA 기반 )
- `MapFeature`: 지도 기반 기능 UI 및 로직 ( TCA 기반 )

### 🔸 인터페이스 모듈
- `CalendarFeatureInterface`, `MapFeatureInterface`: Feature 모듈의 직접적인 의존성을 방지하고, **외부 모듈과의 의존성 방향을 역전시키기 위해 사용되는 추상화 계층**입니다.  
  이를 통해 Feature는 완전히 독립적인 모듈로 유지되며, 다양한 앱에서 안전하게 재사용 가능합니다.

### 🔸 데이터 모듈
- `CalendarData`, `MapData`: API / DB 연결, Repository 구현

### 🔸 공통 모듈
- `Core`: 공통 유틸, 상수, UI 컴포넌트 등
- `Domain`: 데이터 모델 및 도메인 로직
- `RealmKit`: 로컬 DB 관리 (Realm)

---

## ⚙️ 상태 관리 및 DI 아키텍처
MemoryBox는 전 화면과 로직을 [TCA (The Composable Architecture)] 기반으로 구현하여 다음의 구조를 따릅니다:

- State: 기능별로 구조체로 상태를 명시

- Action: 사용자 또는 시스템 이벤트를 열거형으로 정의

- Reducer: 순수 함수로 상태와 액션을 연결

- Effect: API 호출, 타이머, 위치 요청 등 외부 작업 처리

- Store: 상태 및 로직의 중심점

또한 Swift Dependencies를 활용해
모든 의존성을 @Dependency 기반으로 주입하며, 테스트 환경에서는 .mock, .unimplemented 등을 활용하여 유연한 DI를 지원합니다.

---

## 📦 사용한 주요 라이브러리

| 라이브러리 | 역할 |
|------------|------|
| [**The Composable Architecture (TCA)**](https://github.com/pointfreeco/swift-composable-architecture) | 앱의 상태, 액션, 비즈니스 로직을 구조화하고 모듈 단위로 기능을 나누는 **기반 아키텍처 프레임워크** |
| [**Swift Dependencies**](https://github.com/pointfreeco/swift-dependencies) | `@Dependency`, `DependencyKey` 기반의 **런타임 의존성 주입 및 테스트 지원** |
| [**Realm**](https://www.mongodb.com/docs/realm/sdk/swift/) | 로컬 데이터 저장을 위한 **경량 NoSQL 데이터베이스**, 사용자 일정/다이어리 정보 저장에 활용 |

---
