---
description: "PR(Pull Request) 관련 모든 요청을 처리한다. PR 생성, 수정, 올리기 등."
---

# PR 생성기

현재 브랜치의 변경사항을 분석하여 PR을 작성한다.

## 실행 단계

1. Base 브랜치 확인

   - 사용자가 요청에서 Base 브랜치를 지정하면 해당 브랜치를 Base로 사용하고 아니면 main을 브랜치로 사용

2. 원격 브랜치 확인 및 push

   - 원격에 현재 브랜치가 없으면: `git push -u origin 현재브랜치명` 실행

3. git diff로 변경사항 분석 (원격에 push된 커밋만 포함)

   ```bash
   git diff origin/{base브랜치}...origin/현재브랜치명 --stat
   git diff origin/{base브랜치}...origin/현재브랜치명
   git log origin/{base브랜치}..origin/현재브랜치명 --oneline
   ```

4. 분석 결과를 바탕으로 PR 제목과 본문 생성

   - 여러 변경이 섞여 있을 때:
     - 사소한 변경(chore, 주석, 포맷팅 등)이 섞여 있으면: 주요 변경만 제목에, 사소한 것은 본문에 언급
     - 중요한 변경이 여러 개면: 둘 다 제목에 명시하거나, 공통점으로 뭉뚱그려서 제목 작성

   ### PR 제목 형식

   ```text
   타입: 간결한 설명
   ```

   Example 앱 관련 변경인 경우:

   ```text
   타입(example): 간결한 설명
   ```

   **타입:**

   - `feat` - 새로운 기능
   - `fix` - 버그 수정
   - `refactor` - 코드 리팩토링
   - `style` - 스타일 변경 (코드 포맷팅 등)
   - `chore` - 기타 작업
   - `build` - 빌드/배포 관련
   - `test` - 테스트코드 관련

   ### PR 본문

   **반드시 `.github/pull_request_template.md` 파일을 먼저 읽고 그 형식을 정확히 따를 것.**

   **Changes 섹션:**

   - 변경의 목적/배경을 먼저 설명
   - 주요 변경사항을 불릿 포인트로 나열

   **Tests you conducted 섹션:**

   - 테스트 안 했으면 `- x`

   **QA Test Cases 섹션:**

   - QA 필요 없으면: `- [x] 테스트가 필요 없습니다` 체크하고 아래에 `-` 만 남기기
   - QA 필요하면: 체크박스 체크하지 않고 테스트 시나리오 작성

   ### 예시

   #### 새 기능

   **제목:** `feat: Custom HTML 인앱 triggerAction + dismissInApp 지원`

   ```markdown
   # 📝 Changes

   - Custom HTML 인앱 메시지에서 JavaScript로 네이티브 액션을 호출할 수 있도록 `addInAppCustomActionHandler` 추가
   - 프로그래매틱하게 인앱 메시지를 닫을 수 있는 `dismissInApp()` 메서드 추가

   # Tests you conducted

   - Example 앱에서 Custom HTML 인앱 메시지 동작 확인

   # ⛑ QA Test Cases

   - [ ] 테스트가 필요 없습니다 (체크하면 QA 라벨이 자동으로 추가되지 않습니다.)

   - Custom HTML 인앱에서 버튼 클릭 시 네이티브 핸들러가 호출되는지 확인
   - dismissInApp() 호출 시 인앱 메시지가 정상적으로 닫히는지 확인
   ```

   #### 버그 수정

   **제목:** `fix: SPM 빌드 에러 수정`

   ```markdown
   # 📝 Changes

   - Swift Package Manager로 빌드 시 발생하던 에러를 수정했습니다.

   # Tests you conducted

   - SPM으로 빌드 성공 확인

   # ⛑ QA Test Cases

   - [x] 테스트가 필요 없습니다 (체크하면 QA 라벨이 자동으로 추가되지 않습니다.)

   -
   ```

5. PR 생성 또는 수정 (확인 없이 바로 실행)

   - `gh pr view --json state`로 현재 브랜치의 PR 상태 확인
   - state가 "OPEN"이면: `gh pr edit --title "제목" --body "본문" --base "{base브랜치}"`
   - PR이 없거나 state가 "CLOSED"/"MERGED"면: `gh pr create --title "제목" --body "본문" --base "{base브랜치}"`
