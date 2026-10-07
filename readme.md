# Trip Wallet Flutter 화면

현재 Figma Make 화면을 Flutter 위젯으로 옮긴 소스 패키지입니다.
## 실행 방법

1. Flutter SDK가 설치된 환경에서 새 프로젝트를 만듭니다.

    '''bash
    flutter create trip_wallet_profile
    '''

2. 이 패키지의 'pubspec. yaml'과'lib/main.dart 를 새 프로젝트에 복사합니다.

3. 아래 명령을 실행합니다.
    '''bash
    flutter pub get 
    flutter run
    '''

## 포함 기능

- 반응형 내 정보 화면과 safearea
- 라이트/다크 모드
- 이름 터치 수정 및 바깥 영역 터치 저장
- 이메일, 카카오, 네이버, G00gLe 로그인 제공자 모델
- 카드와 계좌 분리 표시
- API 데이터 활용 동의 토글
- 비밀번호 변경 바텀시트
- 문의 등록, 답변 상태 확인, 문의 삭제
- 회원 탈퇴 확인 창

현재 데이터는 샘플 상태입니다. 실제 앱에서는 UserProfile'을 인증 API 결과로교체하고, 
문의• 카드 계좌 상태를 서버 API 또는 상태관리 레이어에 연결하면 됩니다.