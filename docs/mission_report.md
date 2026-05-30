# 리눅스 프로세스 및 시스템 리소스 트러블슈팅

## 1. 기본 환경 구축

### 1-1. Docker 컨테이너

#### 1-1-1. Docker 컨테이너 생성하기

```bash
docker run -it --name b1-2 -v /home/jongmin006/codyssey/B1-2:/workspace ubuntu:22.04 bash
```

#### 1-1-2. 컨테이너 내부에 기본 패키지 설치

* 업데이트 

 ```bash
 apt update
 ```

* 패키지 설치

 ```bash
 apt install -y \
 git
 tree\
 curl\
 vim\
 nano\
 file\
 procps\
 psmisc\
 net-tools\
 iproute2
 ```

* 패키지 설명

| 패키지 | 용도 | 설명 |
| :--- | :--- | :--- |
| tree | 폴더 구조 확인 | 디렉토리 구조를 트리 형태로 시각화해서 출력 |
| curl | 데이터 전송 / API 테스트 | 서버와 데이터를 주고받거나, API 엔드포인트를 테스트할 때 필수 |
| file | 파일 형식 확인 | 파일의 종류(텍스트,바이너리,실행파일 등)를 판별 |
| procps | 프로세스 모니터링 | ```ps```, ```top``` 등 현재 실행 중인 프로세스를 확인하는 도구 세트 |
| psmisc | 프로세스 관리 | ```killall```, ```fuser``` 등 프로세스를 정밀하게 관리하는 유틸리티 |
| net-tools | 네트워크 진단(구형) | ```ifconfig```, ```netstat``` 등으로 네트워크 인터페이스 확인 |
| iproute2 | 네트워크 진단(신형) | ```ip```, ```ss``` 등 최신 리눅스 표준 네트워크 관리 도구 모음 |

### 1-2. Git

#### 1-2-1. Git 저장소 초기화

```bash
git init
```

#### 1-2-2. Git 사용자 설정

* 기본 설정

 ```bash
 git config --global user.name "name"
 git config --global user.email "email@email.com"
 ```

 | 구성 요소 | 의미 | 설명 |
 | :--- | :--- | :--- |
 | config | 서브 명령어 | Git의 설정을 조회하거나 변경 |
 | --global | 옵션 | 설정을 이 컴퓨터의 모든 프로젝트에 공통으로 적용하겠다는 옵션 |
 | user.name | 설정 키 | Git이 관리하는 설정 항목 중 "사용자 이름" |
 | "name" | 설정 값 | ```user.name```에 저장할 데이터 |

* safe.directory 설정

 ```bash
 git config --global --add safe.directory /workspace
 ```

* 추가 설명

 : ```safe.directory``` 설정을 하는 이유는 Git의 보안 기능인 '디렉토리 소유권 확인' 때문. 현재 ```-v``` 으로 호스트와 컨테이너가 연결되어 있다. 그래서 현재 Git 명령을 실행하는 사용자(UID 0)와 해당 Git 저장소의 소유자(UID 1000)가 다르기 때문에 Git은 이 설정을 하지 않으면 명령을 거부한다.

 |  | 사용자 | 소유자 |
 | :---: | :----: | :---: |
 | 명령어 | ```id u``` | ```ls -nd /workspace``` |
 | 해석 | 사용자의 UID 출력 | /workspace의 소유자를 UID로 출력 |
 | 결과 | 0 | 1000 |

#### 1-2-3. .gitignore 작성

* .gitignore 생성 및 편집기 열기

```bash
nano .gitignore
```

* 작성할 내용

```
*.log
logs/
__pycache__/
*.pyc
```

### 1-3. 디렉토리 & 파일

#### 1-3-1. 디렉토리 구조 생성

```bash
mkdir app
mkdir reports
mkdir -p doc/screenshots
mkdir scripts
mkdir logs
mkdir runtime
```

#### 1-3-2. 기본 파일 생성

```bash
touch README.md
touch reports/oom-report.md
touch reports/cpu-report.md
touch reports/deadlock-report.md
touch doc/mission_report.md
```

#### 1-3-3. 구조 확인하기

```bash
tree
```

```
/workspace
|-- README.md
|-- app
|-- docs
|   |-- mission_report.md
|   `-- screenshots
|-- logs
|-- reports
|   |-- cpu-report.md
|   |-- deadlock-report.md
|   `-- oom-report.md
|-- runtime
`-- scripts
```