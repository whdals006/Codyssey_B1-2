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
./agent-leak-app-x86
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

### 3-2. monitor.sh 작성 (초기버전)

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

### 3-4. monitor.sh (초기버전) 코드 분석

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


### 3-5. monitor.sh (수정버전)

```bash
#!/bin/bash

PARENT_PID=$1
LOG_FILE=/workspace/logs/monitor.log

if [ -z "$PARENT_PID" ]; then
    echo "Usage: ./monitor.sh <parent_pid>"
    exit 1
fi

echo "=== Monitoring Parent PID: $PARENT_PID ===" >> $LOG_FILE

while true
do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # parent 살아있는지 확인
    if ! ps -p $PARENT_PID > /dev/null 2>&1; then
        echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
        break
    fi

    # parent 정보
    PARENT_STATS=$(ps -p $PARENT_PID -o %cpu,rss --no-headers)

    PARENT_CPU=$(echo $PARENT_STATS | awk '{print $1}')
    PARENT_RSS=$(echo $PARENT_STATS | awk '{print $2}')

    # child PID 찾기
    CHILD_PID=$(ps --ppid $PARENT_PID -o pid= | xargs)

    CHILD_CPU=0
    CHILD_RSS=0

    if [ ! -z "$CHILD_PID" ]; then
        CHILD_STATS=$(ps -p $CHILD_PID -o %cpu,rss --no-headers)

        if [ ! -z "$CHILD_STATS" ]; then
            CHILD_CPU=$(echo $CHILD_STATS | awk '{print $1}')
            CHILD_RSS=$(echo $CHILD_STATS | awk '{print $2}')
        fi
    fi

    TOTAL_CPU=$(awk "BEGIN {print $PARENT_CPU + $CHILD_CPU}")
    TOTAL_RSS_KB=$((PARENT_RSS + CHILD_RSS))
    TOTAL_RSS_MB=$((TOTAL_RSS_KB / 1024))

    echo "[$TIMESTAMP] Parent:$PARENT_PID Child:${CHILD_PID:-None} CPU:${TOTAL_CPU}% MEM:${TOTAL_RSS_MB}MB" >> $LOG_FILE

    sleep 2
done
```

### 3-6. monitor.sh (수정버전) 코드 분석

1. 초기화 및 예외 처리 (Initialization)

    ```bash
    #!/bin/bash

    PARENT_PID=$1
    LOG_FILE=/workspace/logs/monitor.log
    ```

    * ```PARENT_PID=$1``` : 스크립트를 실행할 때 입력한 첫 번째 인자값(parent PID)을 저장.

    * ```LOG_FILE=...``` : 관제 데이터를 기록할 경로

    ```bash
    if [ -z "$PARENT_PID" ]; then
        echo "Usage: ./monitor.sh <parent_pid>"
        exit 1
    fi
    ```

    * 인자값이 비어있으면 사용법을 안내하고 즉시 종료(exit 1)


2. 무한 루프 및 부모 상태 확인

    ```bash
    while true
    do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

        # parent 살아있는지 확인
        if ! ps -p $PARENT_PID > /dev/null 2>&1; then
            echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
            break
        fi
    ```

    * ```if ! ps -p $PARENT_PID ...``` : 부모 프로세스가 살아있는지 확인

        * ```-p``` (Process ID) : 전체 프로세스 목록 중에 내가 확인하고 싶은 특정 PID만 조회

        * ```> /dev/null 2>&1``` 은 ps 명령어가 화면에 출력하는 메시지를 쓰레기통(```/dev/null```)으로 버려서 화면을 깔끔하게 유지하라는 뜻.

            * ```>``` (Redirection) : 명령어의 실행 결과를 화면이 아니라 ```파일```이나 ```장치```로 방향을 틀어서 집어넣을 때 사용. 앞에 숫자가 생략되면 기본값인 ```1```이 적용.

            * ```/dev/null``` : 리눅스 시스템에 존재하는 특별한 가상 장치 파일. 이 파일로 보내진 모든 데이터는 흔적도 없이 사라짐.

            * 리눅스의 3가지 표준 스트림

                | 숫자 | 의미 | 설명
                | :--- | :--- | :--- |
                | 0 | 표준 입력 | 키보드로부터 들어오는 입력
                | 1 | 표준 출력 | 명령어가 성공했을 때 나오는 정상적인 결과 메시지 |
                | 2 | 표준 에러 | 명령어가 실패했을 때 나오는 에러 메시지 |

            * ```2>``` : 2(표준 에러)의 방향을 바꾼다.

            * ```&1``` : 파일이 아니라 1번 통로(표준 출력)를 의미한다고 알려주기 위해 ```&```기호를 붙임.

        * 부모 프로세스가 죽어서 ```ps```명령이 실패(```!```)하면, 로그 남기고 루프 탈출.

    ```bash
    # parent 정보
    PARENT_STATS=$(ps -p $PARENT_PID -o %cpu,rss --no-headers)

    PARENT_CPU=$(echo $PARENT_STATS | awk '{print $1}')
    PARENT_RSS=$(echo $PARENT_STATS | awk '{print $2}')
    ```

    * 부모의 CPU 사용률과 RSS(Resident Set Size, 물리 메모리 실제 사용량)를 추출.

    * ```awk``` : 텍스트(데이터) 처리 및 분석 명령어. 텍스트 파일이나 로그 데이터가 들어왔을 때, 이를 표(table) 형태로 인식해서 원하는 대로 자르고, 붙이고, 계산하는 역할을 한다.

3. 자식 프로세스 탐색 및 데이터 추출

    ```bash
    # child PID 찾기

    CHILD_PID=$(ps --ppid $PARENT_PID -o pid= | xargs)
    ```

    * ```ps --ppid $PARENT_PID``` : 특정 부모PID(--ppid)를 가진 자식 프로세스들을 다 찾아라

        * ```--ppid``` (Parent Process ID) : 특정 부모 프로세스가 낳은 자식 프로세스들을 전부 찾는 옵션. 

    * ```-o pid=``` : 제목(Header)없이 순수하게 자식의 PID 숫자만 출력.

        * ```-o``` (Output Format): ps 명령어가 기본으로 보여주는 항목들 중에서 내가 보고 싶은 항목만 골라서 화면에 출력하는 옵션. 항목 뒤에 등호(```=```)를 붙이면 출력 결과 맨 위에 나오는 제목(Header) 텍스트를 지우고 순수한 데이터 값만 출력.

    * ```| xargs``` : 만약 자식이 여러 개라면 줄바꿈으로 출력되는데, 이를 한 줄로 이어 붙인다.

        * ```xargs``` (eXtended ARGuments) : 앞 명령어의 출력 결과를 받아와서 뒤에오는 명령어의 '인자'로 넘겨서 실행해 주는 명령어.

            * 파이프(```|```)가 던져주는 데이터를 못받아먹는 명령어(```rm```,```cp```,```ps```) 앞에 씀.

            * ```xargs``` 뒤에 아무 명령어도 안적으면, 들어온 문자열에서 줄바꿈(enter), 탭(tab), 공백(space)들을 전부 하나의 깔끔한 공백 기호로 합쳐서 한 줄로 길게 펴주는 역할을 한다.

    ```bash
    CHILD_CPU=0
    CHILD_RSS=0

    if [ ! -z "$CHILD_PID" ]; then
        CHILD_STATS=$(ps -p $CHILD_PID -o %cpu,rss --no-headers)

        if [ ! -z "$CHILD_STATS" ]; then
            CHILD_CPU=$(echo $CHILD_STATS | awk '{print $1}')
            CHILD_RSS=$(echo $CHILD_STATS | awk '{print $2}')
        fi
    fi
    ```

    * 기본적으로 자식의 자원 사용량 변수를 ```0```으로 초기화 (자식이 없을 수도 있기 때문)

    * 만약 자식 PID(```CHILD_PID```)가 존재하면(```! -Z```), 부모와 같은 방식으로 자식 프로세스의 CPU 사용률과 물리 메모리(RSS) 용량을 뽑아낸다.


4. 부모와 자식의 데이터 합산 및 기록 (Data Aggregation)

    ```bash
    TOTAL_CPU=$(awk "BEGIN {print $PARENT_CPU + $CHILD_CPU}")
    ```

    * shell 스크립트 내부의 기본적인 산술 연산은 소수점 계산을 못한다. 그래서 소수점 연산이 가능한 ```awk "BEGIN {print ...}``` 툴을 빌려서 계산.

    * ```BEGIN``` 블록 : "뒤에 파일이 있든 없든 상관 말고, 프로그램이 시작(begin)되자마자 괄호 안에 있는 코드를 무조건 먼저 한 번 실행해라" 라는 특수 명령어. 

    ```bash
    TOTAL_RSS_KB=$((PARENT_RSS + CHILD_RSS))
    TOTAL_RSS_MB=$((TOTAL_RSS_KB / 1024))
    ```

    * 부모의 메모리 용량(KB)과 자식의 메모리 용량(KB)을 더해 총 용량 구한다.

    * KB 단위를 1024로 나눠서 MB 단위로 환산.

    ```bash
        echo "[$TIMESTAMP] Parent:$PARENT_PID Child:${CHILD_PID:-None} CPU:${TOTAL_CPU}% MEM:${TOTAL_RSS_MB}MB" >> $LOG_FILE

        sleep 2
    done
    ```

    * ```${CHILD_PID:-None}``` : 만약 자식 PID가 비어있으면 화면에 ```None```이라고 출력하고, 있으면 자식 PID를 출력.


## 4. OOM 분석

### 4-1. OOM (Out of Memory) 란?

* 정의

 : 운영체제(OS)나 프로그램이 사용할 수 있는 메모리(RAM) 공간이 완전히 바닥났을 때 시스템을 보호하기 위해 발생시키는 '비상 정지 장치'.

* 나타나는 현상 

 : 프로그램이 메모리 부족으로 터질 때, 시스템 전체가 뻗는 것을 막기 위해 ```oom killer``` 가 메모리를 가장 많이 먹고 있는 프로세스를 강제로 kill 한다.

* 발생하는 원인

    * 메모리 누수 (Memory Leak) : 프로그램이 작업을 수행하기 위해 메모리를 할당받아 쓴 뒤, 일이 끝났으면 다시 메모리를 반납 해야하는데 반납하지 않고 계속 붙자고 있는 현상.

    * 순간적인 트래픽 폭주 (Traffic Spike) : 웹 서버에 평소보다 많은 사용자가 동시에 접속하여 수많은 요청을 처리하다 보면, 각 요청을 담당하는 스레드나 객체들이 일시적으로 늘어나는데, 이때 순간적으로 필요한 총 메모리 용량이 물리 RAM 크기를 넘어서면 OOM이 발생.

    * 잘못된 메모리 제한(Limit) 설정 : 특정 컨테이너의 설정 파일에 memory limit 한계선을 너무 작게 잡으면, 앱이 조금만 무거운 연산을 해도 컨테이너 내부에서 OOM killer가 발동해 앱을 죽인다.

* 추가 설명

    * 힙(Heap) : 프로그램이 실행되는 도중에 필요할 때마다 실시간으로 원하는 크기만큼 메모리를 빌려서 사용하는 자유 메모리 공간.

### 4-2. 주어진 app 분석

* app 실행

 ```bash
 ./agent-leak-app-x86
 ```

* PID 찾기

 ```bash
 ps -ef | grep agent
 ```

* monitor.log 실행

 ```bash
 /workspace/scripts/monitor.sh PID
 ```

* monitor.log 확인하기

 ```bash
 cat /workspace/logs/monitor.log
 ```

* monitor.log 내용만 다 지우기

 ```bash
 > /workspace/logs/monitor.log
 ```

### 4-3. MEMORY_LIMIT=128 일 때

```bash
>>> Starting Agent Boot Sequence...
[1/6] Checking User Account          [OK]
... Running as service user 'student' (uid=1000)
[2/6] Verifying Environment Variables [OK]
... All required Envs correct
[3/6] Checking Required Files        [OK]
... Verified 'secret.key' with correct key string.
[4/6] Checking Port Availability     [OK]
... Port 15034 is available.
[5/6] Verifying Log Permission       [OK]
... Log directory is writable: /workspace/runtime/logs
[6/6] Verifying Mission Environment  [OK]
... MEMORY_LIMIT=128MB, CPU_MAX_OCCUPY=30%, MULTI_THREAD_ENABLE=True
------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-17 13:29:08,529 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-17 13:29:08,529 [INFO] Agent listening at port 15034

======================================================
 [ Agent Initiate ] Resource Check
======================================================
 [ MEMORY ] Limit: 128MB             [ WARNING: Recommend Over 256MB ]
 [ CPU    ] Limit: 30%               [ OK ]
 [ THREAD ] Concurrency: True        [ WARNING ]
------------------------------------------------------
>>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
======================================================

2026-06-17 13:29:10,564 [INFO] [MemoryWorker] Current Heap: 25MB
2026-06-17 13:29:13,621 [INFO] [MemoryWorker] Current Heap: 50MB
2026-06-17 13:29:16,685 [INFO] [MemoryWorker] Current Heap: 75MB
2026-06-17 13:29:19,735 [INFO] [MemoryWorker] Current Heap: 100MB
2026-06-17 13:29:22,776 [INFO] [MemoryWorker] Current Heap: 125MB
2026-06-17 13:29:25,820 [INFO] [MemoryWorker] Current Heap: 150MB
2026-06-17 13:29:25,820 [CRITICAL] [MemoryGuard] Memory limit exceeded (150MB >= 128MB) / (Recommend Over 256MB)
2026-06-17 13:29:25,823 [CRITICAL] [MemoryGuard] Self-terminating process 169723 to prevent system instability.


>>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<

Killed
```

### 4-4. MEMORY_LIMIT=512 일 때

* MEMORY_LIMIT 변경

    ```student 계정```에서

    ```bash
    nano ~/.bashrc
    ```

    ```bash
    # 기존 128 에서 512로 변경

    export MEMORY_LIMIT=512
    ```

* 적용

    ```bash
    source ~/.bashrc
    ```

* 확인

    ```bash
    echo $MEMORY_LIMIT
    ```

### 4-5. MEMORY_LIMIT=512로 바꾸고 난 후 나타난 증상

```bash
student@3cf32eabbc31:/workspace/app$ ./agent-leak-app-x86
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
   ... MEMORY_LIMIT=512MB, CPU_MAX_OCCUPY=30%, MULTI_THREAD_ENABLE=True
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-17 13:55:20,249 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-17 13:55:20,249 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 512MB                [ OK ]
 [ CPU    ] Limit: 30%                  [ OK ]
 [ THREAD ] Concurrency: True           [ WARNING ]
--------------------------------------------------
 >>> SYSTEM WARNING: POTENTIAL DEADLOCK IN CONCURRENT MODE.
==================================================

2026-06-17 13:55:22,257 [WARNING] [AgentWorker] Initializing concurrent transaction processors...
2026-06-17 13:55:22,259 [WARNING] [System] CAUTION: Strict resource locking is enabled.
2026-06-17 13:55:27,286 [INFO] [Worker-Thread-1] Process Started. Attempting to lock [Shared_Memory_A]...
2026-06-17 13:55:27,287 [INFO] [AgentWorker][Worker-Thread-2] Process Started. Attempting to lock [Socket_Pool_B]...
2026-06-17 13:55:27,288 [INFO] [AgentWorker] Waiting for worker threads to complete transactions...
2026-06-17 13:55:27,288 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-06-17 13:55:27,288 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
2026-06-17 13:55:27,289 [INFO] [AgentWorker][Worker-Thread-2] Establishing network connections in Pool B...
2026-06-17 13:55:27,290 [INFO] [AgentWorker][Worker-Thread-1] Processing critical data in Memory A...
2026-06-17 13:55:29,297 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-06-17 13:55:29,297 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
2026-06-17 13:55:29,300 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-06-17 13:55:29,301 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
```

### 4-6. 로그 분석

* Thread 1 

    * ```Shared_Memory_A``` 를 lock 함.
    * ```Socket_Pool_B``` 를 기다리는 중.

* Thread 2

    * ```Socket_Pool_B``` 를 lock 함.
    * ```Shared_Memory_A``` 를 기다리는 중.

* Deadlock 현상이 발생

### 4-7. Deadlock 증거 수집

* 프로세스 죽었는지 확인

```bash
ps -ef | grep agent | grep -v grep
```

```bash
# 결과

student   184713  163493  0 13:55 pts/1    00:00:00 ./agent-leak-app-x86
student   184714  184713  0 13:55 pts/1    00:00:00 ./agent-leak-app-x86
```

* CPU , RSS 확인

```bash
ps -o pid,ppid,%cpu,rss,cmd -C agent-leak-app-x86
```

```bash
# 결과

   PID    PPID %CPU   RSS CMD
184713  163493  0.0  2092 ./agent-leak-app-x86
184714  184713  0.0 17960 ./agent-leak-app-x86
```

* Thread 확인하기

```bash
ps -L -p 184714
```

| 옵션 | 의미 | 설명 |
| :--- | :--- | :--- |
| -p | Process | 대상 프로세스를 지정하는 옵션 |
| -L | Light-weight process | 스레드의 정보를 출력하는 옵션 <br> (리눅스 커널 내부에서는 스레드를 LWP라고 부른다) |

```bash
# 결과

    PID     LWP TTY          TIME CMD
 184714  184714 pts/1    00:00:00 agent-leak-app-
 184714  184895 pts/1    00:00:00 agent-leak-app-
 184714  184896 pts/1    00:00:00 agent-leak-app-

 # LWP : 운영체제가 각각의 스레드들에게 부여한 고유번호.
 # TTY : (Teletypewriter) 사용자와 컴퓨터가 서로 글자를 주고받는 단말기 통로.
 # TIME : 해당 스레드가 CPU를 써서 실제로 연산을 한 누적 시간.
 ```


## 5. Deadlock 분석

### 5-1. Deadlock 이란?

* 정의

 : 데드락(Deadlock, 교착 상태)은 멀티스레드나 멀티프로세스 환경에서 두 개 이상의 작업이 서로 상대방이 가진 자원(lock)을 무한히 기다리며 그 자리에 딱 멈춰버리는 현상.

* 나타나는 현상

    * 프로세스 무응답 : 사용자의 입력이나 시스템 요청에 전혀 반응하지 않는 frozen 상태가 된다.

    * 리소스 정체 : CPU 사용률이 0%로 고정되어 있고, MEM 사용률도 고정.

* 발생 원인 (발생 메커니즘)

 : 데드락은 시스템 내부에서 공유 자원에 여러 프로세스가 동시에 접근할 때 데이터가 꼬이는 것을 막기 위해 사용하는 Lock 메커니즘 때문에 발생한다.

 예를 들어, 스레드A와 스레드B가 자원1과 자원2 모두 필요한 상황에서
    
    1. 스레드A가 먼저 자원1의 락을 점유
    2. 동시에 스레드B가 자원2의 락을 점유
    3. 스레드A는 다음 작업을 위해 자원2의 락을 요청하며 대기.
    4. 스레드B는 다음 작업을 위해 자원1의 락을 요청하며 대기.

 두 스레드 모두 자신이 가진 자원을 절대 먼저 내려놓지 않고 상대방이 자원을 풀어주기만을 기다리기 때문에, 이 시점웁터 프로그램은 영원히 멈추게 된다.

* Deadlock 발생의 4대 필수 조건

    * 상호 배제 (Mutual Exclusion) : 자원은 한 번에 한 프로세스만 사용할 수 있어야 한다.
    * 점유 대기 (Hold and Wait) : 최소한 하나의 자원을 쥔 상태(hold)에서, 다른 프로세스가 쓰고 있는 자원을 얻기 위해 대기(wati)해야 한다.
    * 비선점 (No Preemption) : 다른 프로세스가 쥐고 있는 자원을 강제로 빼앗아 올 수 없어야 한다.
    * 순환 대기 (Circular Wait) : 대기하고 있는 프로세스들의 관계가 꼬리를 물고 원형(circle)을 이루어야 한다. (A가 B를 기다리고, B는 A를 기다리는 구조)

* 추가 설명

    * 스레드(thread) : 프로세스(process)가 메모리에 올라와 실행 중인 '프로그램 전체'를 의미한다면, 스레드(thread)는 그 프로그램 내부에서 실제로 코드를 한 줄씩 읽으며 일하는 실질적인 '일꾼'이다.

    * 락(lock) : 여러 개의 스레드가 동시에 일할 때 치명적인 문제가 있는데, 바로 프로세스 내부의 메모리 공간을 모든 스레드가 공유한다는 점이다. 그래서 여러 스레드가 똑같은 데이터(공유 자원)를 동시에 점유하는 것을 막기 위한 안전장치를 lock이라고 한다.
 

### 5-2. 환경변수 변경

* student 계정에서 환경변수 변경

```bash
nano ~/.bashrc
```

* MULTI_THREAD_ENABLE 옵션 변경하기

```bash
# 기존 설정

export MULTI_THREAD_ENABLE=true
```

```bash
# 변경 후 옵션

export MULTI_THREAD_ENABLE=false
```

* 변경된 환경변수 적용하기

```bash
source ~/.bashrc
```

* 변경됬는지 확인

```bash
echo $MULTI_THREAD_ENABLE
```

```bash
# 결과

false
```

### 5-3. 앱 실행하기

```bash
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
   ... MEMORY_LIMIT=512MB, CPU_MAX_OCCUPY=30%, MULTI_THREAD_ENABLE=False
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-21 12:05:40,729 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-21 12:05:40,732 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 512MB                [ OK ]
 [ CPU    ] Limit: 30%                  [ OK ]
 [ THREAD ] Concurrency: False          [ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-06-21 12:05:42,743 [INFO] >>> Scenario Selected: [Healthy System Monitoring]

>>> [SYSTEM] ALL CONFIGURATIONS OPTIMAL. RUNNING STABILITY TEST... <<<

2026-06-21 12:05:42,743 [INFO] [Scheduler] Task Scheduler Initialized.
2026-06-21 12:05:42,744 [INFO] [Scheduler] Registered Tasks: ['Thread-A', 'Thread-B', 'Thread-C']
2026-06-21 12:05:42,744 [INFO] [Scheduler] Starting task execution...
2026-06-21 12:05:42,744 [INFO] [Thread-B] Task Started. Calculating... (20%)
2026-06-21 12:05:42,795 [INFO] [Thread-B] Calculating... (40%)
2026-06-21 12:05:42,846 [INFO] [Thread-B] Calculating... (60%)
2026-06-21 12:05:42,896 [INFO] [Thread-B] Calculating... (80%)
2026-06-21 12:05:42,947 [INFO] [Thread-B] Task Completed. (100%)
2026-06-21 12:05:42,998 [INFO] [Thread-C] Task Started. Calculating... (20%)
2026-06-21 12:05:43,049 [INFO] [Thread-C] Calculating... (40%)
2026-06-21 12:05:43,099 [INFO] [Thread-C] Calculating... (60%)
2026-06-21 12:05:43,150 [INFO] [Thread-C] Calculating... (80%)
2026-06-21 12:05:43,201 [INFO] [Thread-C] Task Completed. (100%)
2026-06-21 12:05:43,252 [INFO] [Thread-A] Task Started. Calculating... (20%)
2026-06-21 12:05:43,303 [INFO] [Thread-A] Calculating... (40%)
2026-06-21 12:05:43,353 [INFO] [Thread-A] Calculating... (60%)
2026-06-21 12:05:43,404 [INFO] [Thread-A] Calculating... (80%)
2026-06-21 12:05:43,455 [INFO] [Thread-A] Task Completed. (100%)
2026-06-21 12:05:43,506 [INFO] [Scheduler] All tasks completed.
2026-06-21 12:05:43,527 [INFO] [CpuWorker] Started. Maximum CPU Limit: 30%
2026-06-21 12:05:43,528 [INFO] [MemoryWorker] Current Heap: 25MB
2026-06-21 12:05:43,528 [INFO] [CpuWorker] Current Load: 5.00%
2026-06-21 12:05:46,577 [INFO] [MemoryWorker] Current Heap: 50MB
2026-06-21 12:05:46,644 [INFO] [CpuWorker] Current Load: 10.60%
2026-06-21 12:05:49,624 [INFO] [MemoryWorker] Current Heap: 75MB
2026-06-21 12:05:49,762 [INFO] [CpuWorker] Current Load: 16.13%
2026-06-21 12:05:52,676 [INFO] [MemoryWorker] Current Heap: 100MB
2026-06-21 12:05:52,880 [INFO] [CpuWorker] Current Load: 25.03%
2026-06-21 12:05:54,992 [INFO] [CpuWorker] Peak reached (30.00%). Starting cooldown...
2026-06-21 12:05:55,721 [INFO] [MemoryWorker] Current Heap: 125MB
2026-06-21 12:05:55,999 [INFO] [CpuWorker] Current Load: 30.00%
2026-06-21 12:05:58,777 [INFO] [MemoryWorker] Current Heap: 150MB
2026-06-21 12:05:59,111 [INFO] [CpuWorker] Current Load: 28.07%
2026-06-21 12:06:01,828 [INFO] [MemoryWorker] Current Heap: 175MB
2026-06-21 12:06:02,228 [INFO] [CpuWorker] Current Load: 27.71%
2026-06-21 12:06:04,869 [INFO] [MemoryWorker] Current Heap: 200MB
2026-06-21 12:06:05,345 [INFO] [CpuWorker] Current Load: 25.35%
2026-06-21 12:06:07,934 [INFO] [MemoryWorker] Current Heap: 225MB
2026-06-21 12:06:08,462 [INFO] [CpuWorker] Current Load: 19.06%
2026-06-21 12:06:10,989 [INFO] [MemoryWorker] Current Heap: 250MB
2026-06-21 12:06:11,576 [INFO] [CpuWorker] Current Load: 15.48%
2026-06-21 12:06:14,053 [INFO] [MemoryWorker] Current Heap: 275MB
2026-06-21 12:06:14,693 [INFO] [CpuWorker] Current Load: 12.44%
2026-06-21 12:06:16,802 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
2026-06-21 12:06:17,098 [INFO] [MemoryWorker] Current Heap: 300MB
2026-06-21 12:06:17,808 [INFO] [CpuWorker] Current Load: 5.00%
2026-06-21 12:06:20,134 [INFO] [MemoryWorker] Current Heap: 325MB
2026-06-21 12:06:20,925 [INFO] [CpuWorker] Current Load: 12.48%
2026-06-21 12:06:23,172 [INFO] [MemoryWorker] Current Heap: 350MB
2026-06-21 12:06:24,044 [INFO] [CpuWorker] Current Load: 12.57%
2026-06-21 12:06:26,229 [INFO] [MemoryWorker] Current Heap: 375MB
2026-06-21 12:06:27,162 [INFO] [CpuWorker] Current Load: 16.97%
2026-06-21 12:06:29,255 [INFO] [MemoryWorker] Current Heap: 400MB
2026-06-21 12:06:30,260 [INFO] [CpuWorker] Current Load: 20.32%
2026-06-21 12:06:32,281 [INFO] [MemoryWorker] Current Heap: 425MB
2026-06-21 12:06:33,373 [INFO] [CpuWorker] Current Load: 28.37%
2026-06-21 12:06:35,345 [INFO] [MemoryWorker] Current Heap: 450MB
2026-06-21 12:06:35,485 [INFO] [CpuWorker] Peak reached (30.00%). Starting cooldown...
2026-06-21 12:06:36,491 [INFO] [CpuWorker] Current Load: 30.00%
2026-06-21 12:06:38,387 [INFO] [MemoryWorker] Current Heap: 475MB
2026-06-21 12:06:39,609 [INFO] [CpuWorker] Current Load: 24.54%
2026-06-21 12:06:41,431 [INFO] [MemoryWorker] Current Heap: 500MB
2026-06-21 12:06:42,721 [INFO] [CpuWorker] Current Load: 14.86%
2026-06-21 12:06:44,471 [INFO] [MemoryWorker] Current Heap: 525MB
2026-06-21 12:06:44,472 [WARNING] [MemoryWorker] Memory Usage Reached Limit (525MB). Starting cleanup...
2026-06-21 12:06:44,513 [INFO] [System] Memory Cache Flushed. Process Stabilized.

>>> [SYSTEM] MEMORY RECOVERED (Cache Cleared) <<<
```

## 6. CPU Spike 분석

### 6-1. CPU Spike 란?

* 정의

 : 평소 일정한 범위를 유지하며 안정적으로 작동하던 CPU 사용률이, 특정 시점에서 가파르게 한계치에 도달하는 현상.

* 나타나는 현상

    * CPU Latency 증가 : 작업 대기 시간이 급증
    * Throttling(버벅임) 및 Freeze(무응답)
    * 시스템 Load Average 상승

* 발생 원인

    * 코드 내부의 무한 루프 및 연산 오류 : 조건문 탈출 조건이 잘못되서 무한히 도는 경우
    * 순간적인 트래픽 폭주 : 순간적으로 많은 사용자가 시스템에 접속하는 경우
    * 대규모 데이터 처리 : 행렬 연산 같은 복잡도가 높은 알고리즘을 사용하는 경우
    * 과도한 가비지 컬렉션 : 자바, 파이썬 환경에서 힙 메모리가 가득 찬 경우

### 6-2. 환경변수 수정

* 현재 환경에서는 CPU Spike가 발생하지 않아서 CPU limit을 낮춰야 한다.

```bash
echo $CPU_MAX_OCCUPY
```

```bash
# 결과

30
```

* student 계정에서 환경변수 변경

```bash
nano ~/.bashrc
```

```bash
# 기존 30에서 80으로 변경

export CPU_MAX_OCCUPY=80
```

* 수정 된 환경변수 저장

```bash
source ~/.bashrc
```

### 6-3. 앱 실행

```bash
cd /workspace/app

./agent-leak-app-x86
```

```bash
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
   ... MEMORY_LIMIT=512MB, CPU_MAX_OCCUPY=80%, MULTI_THREAD_ENABLE=False
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-22 10:54:37,557 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-22 10:54:37,558 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 512MB                [ OK ]
 [ CPU    ] Limit: 80%                  [ WARNING: Recommend Under 50% ]
 [ THREAD ] Concurrency: False          [ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-06-22 10:54:39,569 [INFO] [CpuWorker] Started. Maximum CPU Limit: 80%
2026-06-22 10:54:39,570 [INFO] [CpuWorker] Current Load: 5.00%
2026-06-22 10:54:42,678 [INFO] [CpuWorker] Current Load: 8.91%
2026-06-22 10:54:45,795 [INFO] [CpuWorker] Current Load: 9.00%
2026-06-22 10:54:48,913 [INFO] [CpuWorker] Current Load: 18.29%
2026-06-22 10:54:52,031 [INFO] [CpuWorker] Current Load: 18.85%
2026-06-22 10:54:55,149 [INFO] [CpuWorker] Current Load: 21.22%
2026-06-22 10:54:58,263 [INFO] [CpuWorker] Current Load: 26.87%
2026-06-22 10:55:01,381 [INFO] [CpuWorker] Current Load: 29.11%
2026-06-22 10:55:04,497 [INFO] [CpuWorker] Current Load: 30.62%
2026-06-22 10:55:07,613 [INFO] [CpuWorker] Current Load: 35.15%
2026-06-22 10:55:10,723 [INFO] [CpuWorker] Current Load: 35.79%
2026-06-22 10:55:13,837 [INFO] [CpuWorker] Current Load: 43.26%
2026-06-22 10:55:16,951 [INFO] [CpuWorker] Current Load: 44.70%
2026-06-22 10:55:20,070 [INFO] [CpuWorker] Current Load: 49.62%
2026-06-22 10:55:23,187 [INFO] [CpuWorker] Current Load: 58.86%
2026-06-22 10:55:23,288 [CRITICAL] [CpuWorker] CPU Threshold Violated! (58.86%).

>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<

Terminated
```

## 7. 최종 설정값

### 7-1. 문제 / 원인 / 해결

 | 문제 | 원인 | 해결 |
 | :--- | :--- | :--- |
 | Memory Leak | 메모리 제한 너무 낮음 | 512MB 이상 | 
 | Deadlock | 멀티스레드 lock 경쟁 | 멀티스레드 비활성화 |
 | CPU Spike | CPU limit 너무 높음 | 50% 이하 |

### 7-2. 최종 설정값

```bash
export MEMORY_LIMIT=512
export CPU_MAX_OCCUPY=30
export MULTI_THREAD_ENABLE=false
```

### 7-3. 변경 된 설정값 확인

```bash
env | grep -E 'MEMORY_LIMIT|CPU_MAX_OCCUPY|MULTI_THREAD_ENABLE'
```

```bash
# 결과

CPU_MAX_OCCUPY=30
MULTI_THREAD_ENABLE=false
MEMORY_LIMIT=512
```

### 7-4. 최종 앱 실행 테스트

```bash
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
   ... MEMORY_LIMIT=512MB, CPU_MAX_OCCUPY=30%, MULTI_THREAD_ENABLE=False
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-06-23 08:24:26,290 [INFO] [SafetyGuard] Process priority lowered (nice=10).
2026-06-23 08:24:26,292 [INFO] Agent listening at port 15034

==================================================
 [ Agent Initiate ] Resource Check 
==================================================
 [ MEMORY ] Limit: 512MB                [ OK ]
 [ CPU    ] Limit: 30%                  [ OK ]
 [ THREAD ] Concurrency: False          [ OK ]
--------------------------------------------------
 >>> SYSTEM STATUS: STABLE. STARTING WORKLOAD MONITORING...
==================================================

2026-06-23 08:24:28,307 [INFO] >>> Scenario Selected: [Healthy System Monitoring]

>>> [SYSTEM] ALL CONFIGURATIONS OPTIMAL. RUNNING STABILITY TEST... <<<

2026-06-23 08:24:28,309 [INFO] [Scheduler] Task Scheduler Initialized.
2026-06-23 08:24:28,310 [INFO] [Scheduler] Registered Tasks: ['Thread-A', 'Thread-B', 'Thread-C']
2026-06-23 08:24:28,311 [INFO] [Scheduler] Starting task execution...
2026-06-23 08:24:28,312 [INFO] [Thread-B] Task Started. Calculating... (20%)
2026-06-23 08:24:28,365 [INFO] [Thread-B] Calculating... (40%)
2026-06-23 08:24:28,417 [INFO] [Thread-B] Calculating... (60%)
2026-06-23 08:24:28,468 [INFO] [Thread-B] Calculating... (80%)
2026-06-23 08:24:28,519 [INFO] [Thread-B] Task Completed. (100%)
2026-06-23 08:24:28,571 [INFO] [Thread-C] Task Started. Calculating... (20%)
2026-06-23 08:24:28,623 [INFO] [Thread-C] Calculating... (40%)
2026-06-23 08:24:28,674 [INFO] [Thread-C] Calculating... (60%)
2026-06-23 08:24:28,727 [INFO] [Thread-C] Calculating... (80%)
2026-06-23 08:24:28,780 [INFO] [Thread-C] Task Completed. (100%)
2026-06-23 08:24:28,833 [INFO] [Thread-A] Task Started. Calculating... (20%)
2026-06-23 08:24:28,885 [INFO] [Thread-A] Calculating... (40%)
2026-06-23 08:24:28,938 [INFO] [Thread-A] Calculating... (60%)
2026-06-23 08:24:28,990 [INFO] [Thread-A] Calculating... (80%)
2026-06-23 08:24:29,044 [INFO] [Thread-A] Task Completed. (100%)
2026-06-23 08:24:29,097 [INFO] [Scheduler] All tasks completed.
2026-06-23 08:24:29,116 [INFO] [MemoryWorker] Current Heap: 25MB
2026-06-23 08:24:29,116 [INFO] [CpuWorker] Started. Maximum CPU Limit: 30%
2026-06-23 08:24:29,117 [INFO] [CpuWorker] Current Load: 5.00%
2026-06-23 08:24:32,182 [INFO] [MemoryWorker] Current Heap: 50MB
2026-06-23 08:24:32,246 [INFO] [CpuWorker] Current Load: 10.67%
2026-06-23 08:24:35,252 [INFO] [MemoryWorker] Current Heap: 75MB
2026-06-23 08:24:35,360 [INFO] [CpuWorker] Current Load: 12.46%
2026-06-23 08:24:38,319 [INFO] [MemoryWorker] Current Heap: 100MB
2026-06-23 08:24:38,478 [INFO] [CpuWorker] Current Load: 17.24%
2026-06-23 08:24:41,376 [INFO] [MemoryWorker] Current Heap: 125MB
2026-06-23 08:24:41,612 [INFO] [CpuWorker] Current Load: 26.21%
2026-06-23 08:24:43,722 [INFO] [CpuWorker] Peak reached (30.00%). Starting cooldown...
2026-06-23 08:24:44,437 [INFO] [MemoryWorker] Current Heap: 150MB
2026-06-23 08:24:44,726 [INFO] [CpuWorker] Current Load: 30.00%
2026-06-23 08:24:47,502 [INFO] [MemoryWorker] Current Heap: 175MB
2026-06-23 08:24:47,845 [INFO] [CpuWorker] Current Load: 29.79%
2026-06-23 08:24:50,553 [INFO] [MemoryWorker] Current Heap: 200MB
2026-06-23 08:24:50,968 [INFO] [CpuWorker] Current Load: 25.81%
2026-06-23 08:24:51,723 [INFO] [MemoryWorker] Current Heap: 225MB
2026-06-23 08:24:52,181 [INFO] [CpuWorker] Current Load: 25.53%
2026-06-23 08:24:54,780 [INFO] [MemoryWorker] Current Heap: 250MB
2026-06-23 08:24:55,301 [INFO] [CpuWorker] Current Load: 18.57%
2026-06-23 08:24:57,824 [INFO] [MemoryWorker] Current Heap: 275MB
2026-06-23 08:24:58,416 [INFO] [CpuWorker] Current Load: 13.12%
2026-06-23 08:25:00,879 [INFO] [MemoryWorker] Current Heap: 300MB
2026-06-23 08:25:01,554 [INFO] [CpuWorker] Current Load: 7.29%
2026-06-23 08:25:03,665 [INFO] [CpuWorker] Cooldown complete (5.00%). Resuming load increase...
2026-06-23 08:25:03,940 [INFO] [MemoryWorker] Current Heap: 325MB
2026-06-23 08:25:04,676 [INFO] [CpuWorker] Current Load: 5.00%
2026-06-23 08:25:07,045 [INFO] [MemoryWorker] Current Heap: 350MB
2026-06-23 08:25:07,808 [INFO] [CpuWorker] Current Load: 7.38%
2026-06-23 08:25:10,093 [INFO] [MemoryWorker] Current Heap: 375MB
2026-06-23 08:25:10,931 [INFO] [CpuWorker] Current Load: 10.20%
2026-06-23 08:25:13,144 [INFO] [MemoryWorker] Current Heap: 400MB
2026-06-23 08:25:14,051 [INFO] [CpuWorker] Current Load: 17.66%
2026-06-23 08:25:16,210 [INFO] [MemoryWorker] Current Heap: 425MB
2026-06-23 08:25:17,222 [INFO] [CpuWorker] Current Load: 21.27%
2026-06-23 08:25:19,251 [INFO] [MemoryWorker] Current Heap: 450MB
2026-06-23 08:25:20,337 [INFO] [CpuWorker] Current Load: 22.79%
2026-06-23 08:25:20,426 [INFO] [MemoryWorker] Current Heap: 475MB
2026-06-23 08:25:21,554 [INFO] [CpuWorker] Current Load: 24.03%
2026-06-23 08:25:23,491 [INFO] [MemoryWorker] Current Heap: 500MB
2026-06-23 08:25:23,671 [INFO] [CpuWorker] Peak reached (30.00%). Starting cooldown...
2026-06-23 08:25:24,677 [INFO] [CpuWorker] Current Load: 30.00%
2026-06-23 08:25:26,537 [INFO] [MemoryWorker] Current Heap: 525MB
2026-06-23 08:25:26,538 [WARNING] [MemoryWorker] Memory Usage Reached Limit (525MB). Starting cleanup...
2026-06-23 08:25:26,582 [INFO] [System] Memory Cache Flushed. Process Stabilized.

>>> [SYSTEM] MEMORY RECOVERED (Cache Cleared) <<<

2026-06-23 08:25:27,797 [INFO] [CpuWorker] Current Load: 22.86%
2026-06-23 08:25:30,917 [INFO] [CpuWorker] Current Load: 15.29%
2026-06-23 08:25:31,635 [INFO] [MemoryWorker] Current Heap: 25MB
2026-06-23 08:25:34,041 [INFO] [CpuWorker] Current Load: 12.71%
2026-06-23 08:25:34,671 [INFO] [MemoryWorker] Current Heap: 50MB
2026-06-23 08:25:37,153 [INFO] [CpuWorker] Current Load: 9.00%
2026-06-23 08:25:37,699 [INFO] [MemoryWorker] Current Heap: 75MB
```