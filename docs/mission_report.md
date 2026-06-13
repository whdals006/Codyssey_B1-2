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


## 2. 앱 실행 환경 구성 및 최초 실행

### 2-1. runtime 디렉토리 구조 생성

```bash
mkdir -p runtime/upload_files
mkdir -p runtime/api_keys
mkdir -p runtime/logs
```

### 2-2. secret.key 파일 생성

```bash
echo "agent_api_key_test" > runtime/api_keys/secret.key
```

### 2-3. 일반 사용자 생성

```bash
useradd -m student
```

| 옵션 | 뜻 |
| :--- | :--- |
| ```-m``` | /home 경로에 새로 만들 계정의 전용 폴더 생성 |

* 비밀번호 설정

```bash
passwd student
```
```bash
1234
```

### 2-4. 작업 폴더 권한 변경

```bash
chown -R student:student /workspace/runtime
```

| 코드 | 의미 | 설명 |
| :--- | :--- | :--- |
| chown | Change Owner | 소유자와 소유 그룹을 변경 |
| -R | Recursive | 재귀적 적용 옵션. 하위 디렉토리 및 파일까지 변경 |
| student:student | User:Group | 변경할 소유자와 소유 그룹 |

### 2-5. student 계정으로 전환

```bash
su - student
```

### 2-6. 환경변수 설정


* 환경변수 작성하기

```bash
nano ~/.bashrc
```

* 환경변수

```bash
export AGENT_HOME=/workspace/runtime
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys
export AGENT_LOG_DIR=$AGENT_HOME/logs
export MEMORY_LIMIT=128
export CPU_MAX_OCCUPY=30
export MULTI_THREAD_ENABLE=true
```

* 환경변수 반영하기

```bash
source ~/.bashrc
```

| 명령어 | 설명 |
| :--- | :--- |
| source | 텍스트 파일에 적힌 리눅스 명령어들을 현재 실행 중인 터미널 쉘(Shell)에 즉시 실행(적용)시키는 명령어 |


* 추가 설명
 
    * ```.bashrc``` 파일

        | 구조 | 설명 |
        | :--- | :--- |
        | 앞의 점(```.```) | 리눅스에서 파일명 앞에 붙는 점은 '숨김 파일(Hidden File)'을 의미 |
        | 뒤의 ```rc``` | Run Commands (또는 Run Control)의 약자. "프로그램이 시작될 때 자동으로 실행할 명령어들을 모아둔 파일"이라는 뜻 |

    * ```source```명령어를 쓰는 이유

        ```nano```로 파일을 수정하고 저장했다고 해서 지금 열려 있는 터미널 창이 그 사실을 자동으로 알지는 못한다. 원래는 터미널 창을 껐다가 완전히 새로 켜야 변경된 설정이 반영되지만, source 명령어를 쓰면 창을 끄지 않고도 방금 수정된 내용을 현재 터미널에 즉시 동기화(새로고침)할 수 있다.
 
* 환경변수 확인하기

 ```bash
 env | grep AGENT
 ```

 | 명령어 | 의미 | 설명 |
 | :--- | :--- | :--- |
 | env | Environment | 현재 로그인된 쉘 세션에 설정되어 있는 모든 환경변수의 목록을 출력하는 리눅스 표준 명령어 |
 | \| | Pipe | 앞 명령어의 출력 결과(Output)를 뒤 명령어의 입력 데이터(Input)로 바로 넘겨주는 통로 역할 |
 | grep| Global Regular Expression Print | 입력받은 텍스트 데이터 중에서 정해진 패턴(여기서는 AGENT라는 글자)이 포함된 줄(Line)만 찾아서 화면에 출력하는 검색 명령어 |

### 2-7. 실행 파일 권한 확인

* 현재 실행 파일 권한

```bash
ls -l /workspace/app
```

```
-rw-r--r-- 1 root root 6502016 Jun 12 13:13 agent-leak-app-x86
```

* 실행 권한 부여하기

```bash
chmod +x /workspace/app/agent-leak-app-x86
```

```
-rwxr-xr-x 1 root root 6502016 Jun 12 13:13 agent-leak-app-x86
```

### 2-8. 바이너리(Binary) 정보 확인

```bash
file /workspace/app/agent-leak-app-x86
```
```
/workspace/app/agent-leak-app-x86: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=d3d060968c2b8c41aa17bbc6e127f0d462c98025, stripped
```

* 추가 설명

    * 바이너리(Binary)란?
    
        : 사람이 작성한 소스 코드를 컴퓨터가 알아들을 수 있도록 0과 1로 이루어진 이진수(Binary number) 데이터로 완전히 번역해 놓은 실행 파일

    * 결과 해석

        | 코드 | 의미 | 설명 |
        | :--- | :--- | :--- |
        | ELF | Executable and Linkable Format | 리눅스의 표준 실행 파일 형식 |
        | LSB | Least Significant Bit | 컴퓨터가 메모리에 숫자를 저장할 때, 작은 단위의 숫자(하위 바이트)부터 차례대로 저장하는 방식 |
        | executable |  | 문서나 사진 파일이 아니라, 터미널에서 명령어를 입력해 직접 실행할 수 있는 프로그램이라는 뜻 |

### 2-9. 앱 최초 실행

```bash
.agent-leak-app-x86
```

* 실행 결과

```
>>> Starting Agent Boot Sequence...
[1/6] Checking User Account               [OK]
   ... Running as service user 'student' (uid=1000)
[2/6] Verifying Environment Variables     [OK]
   ... All required Envs correct
[3/6] Checking Required Files             [OK]
   ... Verified 'secret.key' with correct key string.
[4/6] Checking Port Availability          [OK]
   ... Port 15034 is available.
[5/6] Verifying Log Permission            [OK]
   ... Log directory is writable: /workspace/runtime/logs
[6/6] Verifying Mission Environment       [OK]
   ... MEMORY_LIMIT=128MB, CPU_MAX_OCCUPY=30%, MULTI_THREAD_ENABLE=True
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-12 13:32:35,738 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-12 13:32:35,739 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 128MB                [ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 30%                  [ OK ]
 [ THREAD ] Concurrency: True           [ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-06-12 13:32:37,786 [INFO] [MemoryWorker] Current Heap: 25MB
2026-06-12 13:32:40,903 [INFO] [MemoryWorker] Current Heap: 50MB
2026-06-12 13:32:43,951 [INFO] [MemoryWorker] Current Heap: 75MB
2026-06-12 13:32:47,008 [INFO] [MemoryWorker] Current Heap: 100MB
2026-06-12 13:32:50,035 [INFO] [MemoryWorker] Current Heap: 125MB
2026-06-12 13:32:53,079 [INFO] [MemoryWorker] Current Heap: 150MB
2026-06-12 13:32:53,080 [CRITICAL] [MemoryGuard] Memory limit exceeded (150MB >= 128MB) / (Recommend Over 256MB)
2026-06-12 13:32:53,080 [CRITICAL] [MemoryGuard] Self-terminating process 85856 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<

Killed
```


## 3. monitor.sh 작성

### 3-1. monitor.sh 생성

```bash
nano /workspace/scripts/monitor.sh
```

### 3-2. monitor.sh 작성

```
#!/bin/bash

PID=$1
LOG_FILE=/workspace/logs/monitor.log

if [ -z "$PID" ]; then
    echo "Usage: ./monitor.sh <PID>"
    exit 1
fi

echo "=== Monitoring PID: $PID ===" >> $LOG_FILE

while true
do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    STATS=$(ps -p $PID -o %cpu,%mem --no-headers)

    if [ -z "$STATS" ]; then
        echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
        break
    fi

    CPU=$(echo $STATS | awk '{print $1}')
    MEM=$(echo $STATS | awk '{print $2}')

    echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}%" >> $LOG_FILE

    sleep 2
done
```

### 3-3. 실행 권한 부여하기

```bash
chmod +x monitor.sh
```

### 3-4. monitor.sh 코드 분석

1. 초기 설정 및 예외 처리 (Initialization)

    ```bash
    #!/bin/bash
    ```
    
    : bash 쉘을 사용해서 스크립트를 해석하고 실행해라.

    | 코드 | 의미 | 설명 |
    | :--- | :--- | :--- |
    | #! | Shebang | 운영체제에게 "이 스크립트를 어떤 프로그램으로 실행해야 하는지" 알려준다. |

2. 무한 루프와 상태 수집 (Monitoring Loop)

    ```bash
    PID=$1
    LOG_FILE=/workspace/logs/monitor.log
    ```

    * ```PID=$1``` : 스크립트를 실행할 때 뒤에 붙이는 첫 번째 인자를 PID 라는 변수에 저장한다.

    * ```LOG_FILE=...``` : 모니터링한 데이터를 기록할 로그 파일의 절대 경로를 변수로 지정한다.

    ```bash
    if [ -z "$PID" ]; then
        echo "Usage: ./monitor.sh <PID>"
        exit 1
    fi
    ```

    * ```-z "$PID``` : 변수 PID가 비어있는지(zero) 확인.

    * ```exit 1``` 

        | 코드 | 의미 | 설명 |
        | :--- | :--- | :--- |
        | exit 0 | 정상 종료 | "아무 문제 없이 성공적으로 작업을 끝마쳤다" |
        | exit 1 | 비정상 종료 | "작업 도중 어떤 문제가 생겨서 비정상적으로 종료되었다" |

    ```bash
    while true
    do
    ```

    * ```while true``` : 조건이 항상 참이므로 내부 블록을 무한히 반복 실행.

    ```bash
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    ```

    * ```date '+%Y-%m-%d %H:%M:%S'``` : 현재 시간을 ```년-월-일 시:분:초``` 형식으로 출력

    ```bash
    STATS=$(ps -p $PID -o %cpu,%mem --no-headers)
    ```

    | 코드 | 의미 | 설명 |
    | :--- | :--- | :--- |
    | ```ps``` | Process Status | 현재 시스템에서 실행 중인 프로세스의 상태를 보여주는 명령어. 윈도우의 '작업 관리자'와 유사한 역할. |
    | ```-p``` | Process | 특정 PID를 지정하여 정보를 조회 |
    | ```-o``` | Output | 원하는 출력 항목을 사용자가 직접 지정 |
    | ```--no-headers``` | 옵션 | 기본적으로 ```ps``` 명령어를 실행하면 첫 번째 줄에 ID, %CPU 같은 열 이름(header)가 표시되는데, 이 옵션을 사용하면 첫 줄을 생략하고 순수하게 데이터만 출력한다. |

3. 프로세스 종료 감지 및 데이터 가공 (Data Parsing)

    ```bash
    if [ -z "$STATS" ]; then
        echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
        break
    fi
    ```

    : ```STATS``` 변수가 비어있으면 로그 파일에 "Process ended." 기록을 남기고 무한 루프 탈출

    ```bash
    CPU=$(echo $STATS | awk '{print $1}')
    MEM=$(echo $STATS | awk '{print $2}')
    ``` 

    : ```STATS``` 변수에 들어있던 첫번째 덩어리($1)는 ```CPU```에 담고,
    두번째 덩어리($2)는 ```MEM```에 담는다.

4. 로그 기록 및 대기 (Logging & Sleep)

    ```bash
    echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}%" >> $LOG_FILE
    ```

    : 출력 예시 ```[2026-06-12 14:00:02] PID:1234 CPU:1.5% MEM:5.1%```

    ```bash
    sleep 2
    ```

    : 2초 대기