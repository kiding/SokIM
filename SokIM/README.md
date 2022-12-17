// TODO
// https://www.slideshare.net/zonble/input-method-kit
// https://developer.apple.com/documentation/inputmethodkit

### 개발 환경

#### 설치

1. 빌드 후 `SokIM.app`을 `/Library/Input Methods/`로 복사
1. `SokIM.app`을 시스템 환경설정 > 보안 및 개인 정보 보호 > 개인 정보 보호 > 입력 모니터링에 드래그 앤 드롭  
1. `SokIM.app`을 시스템 환경설정 > 보안 및 개인 정보 보호 > 개인 정보 보호 > 손쉬운 사용에 드래그 앤 드롭  
1. `killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM`
1. `log stream --predicate 'process == "SokIM"' --debug --style compact`
1. 시스템 환경설정 > 키보드 > 입력 소스 > "+" 버튼 > 영어 > "속" > "추가" 버튼
1. 메뉴 막대에서 입력 메뉴를 클릭한 다음 입력기 "속" 선택

#### 삭제 (재설치)

1. 시스템 환경설정 > 키보드 > 입력 소스 > "속" > "-" 버튼
1. `killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM`
1. 시스템 환경설정 > 보안 및 개인 정보 보호 > 개인 정보 보호 > 입력 모니터링 > "속 입력기" > "-" 버튼  
1. 시스템 환경설정 > 보안 및 개인 정보 보호 > 개인 정보 보호 > 손쉬운 사용 > "속 입력기" > "-" 버튼  
1. `/Library/Input Methods/SokIM.app` 삭제
