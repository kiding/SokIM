# 속 입력기

<img src="https://github.com/kiding/SokIM/blob/main/SokIM/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x%402x.png">

빠르고 매끄러운 한영 전환을 위한 새로운 macOS 입력기

## 설치 방법

1. [GitHub Releases](https://github.com/kiding/SokIM/releases)에서 `SokIM.pkg` 다운로드 및 설치
1. 시스템 설정 → 키보드 → 입력 소스 "편집..." 버튼 → "+" 버튼 → 영어 → "속" → "추가" 버튼
1. 메뉴 막대에서 현재 입력기를 속 입력기로 변경
1. 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링에서 "속 입력기" 권한 허용
1. 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 "속 입력기" 권한 허용

## 삭제 방법

1. 시스템 설정 → 키보드 → 입력 소스 "편집..." 버튼 → "속" → "-" 버튼
1. 로그아웃 후 재로그인
1. 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링 → "속 입력기" → "-" 버튼  
1. 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용 → "속 입력기" → "-" 버튼  
1. `/Library/Input Methods/SokIM.app` 삭제

## 디버그 메시지 보기

1. 속 입력기 → 디버그 모드 활성화
1. 터미널에서 `log stream --predicate 'process == "SokIM"' --debug --style compact`
