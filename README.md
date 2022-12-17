# 속 입력기

<img src="https://github.com/kiding/SokIM/blob/main/SokIM/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x%402x.png">

빠르고 매끄러운 한영 전환을 위한 새로운 macOS 입력기

## 개발 환경

### 설치

1. 빌드 후 `SokIM.app`을 `/Library/Input Methods/`로 복사
1. `SokIM.app`을 시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링에 드래그 앤 드롭  
1. `SokIM.app`을 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에 드래그 앤 드롭  
1. `killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM`
1. `log stream --predicate 'process == "SokIM"' --debug --style compact`
1. 시스템 설정 > 키보드 > 입력 소스 "편집..." 버튼 > "+" 버튼 > 영어 > "속" > "추가" 버튼
1. 메뉴 막대에서 입력 메뉴를 클릭한 다음 입력기 "속" 선택

### 삭제

1. 시스템 설정 > 키보드 > 입력 소스 "편집..." 버튼 > "속" > "-" 버튼
1. `killall KeyboardSettings keyboardservicesd TextInputMenuAgent TextInputSwitcher imklaunchagent SokIM`
1. 시스템 설정 > 개인정보 보호 및 보안 > 입력 모니터링 > "속 입력기" > "-" 버튼  
1. 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > "속 입력기" > "-" 버튼  
1. `/Library/Input Methods/SokIM.app` 삭제
