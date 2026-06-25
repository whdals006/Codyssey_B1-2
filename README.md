# B1-2 리눅스 프로세스 및 시스템 리소스 트러블슈팅

## 1. 프로젝트 개요

 본 프로젝트는 Linux 환경에서 실행되는 'agent-leak-app' 바이너리를 대상으로 대표적인 시스템 장애 3가지인 **OOM Crash (Memory Leak)**, **CPU Latency (CPU Spike)**, **Deadlock**을 분석하는 트러블슈팅 미션이다.

 단순히 프로글매이 종료되거나 멈추는 현상을 관찰하는 것에서 끝나는 것이 아니라, Linux 시스템 도구와 애플리케이션 로그를 활용하여 장애의 원인을 추적하고 분석하였다.

## 2. 개발 환경

* OS : Ubuntu

* Shall : Bash

* Docker version 29.5.3, build d1c06ef

* git version 2.34.1

## 3. 수행 항목 체크리스트

### 사전 준비
- [x] 일반 사용자(`student`) 계정으로 실행
- [x] 필수 환경변수 설정 완료
- [x] `secret.key` 파일 구성 완료
- [x] 로그 디렉터리 생성 및 권한 설정 완료
- [x] `agent-leak-app-x86` 정상 실행 확인

### OOM Crash 분석
- [x] Memory Leak 재현
- [x] `monitor.sh`로 메모리 증가 추적
- [x] MemoryGuard 종료 로그 확보
- [x] `MEMORY_LIMIT` 변경 전후 비교
- [x] `oom-report.md` 작성 완료

### Deadlock 분석
- [x] Deadlock 재현
- [x] PID 존재 확인
- [x] 스레드 정체 상태 분석
- [x] BLOCKED 로그 확보
- [x] `MULTI_THREAD_ENABLE` 변경 전후 비교
- [x] `deadlock-report.md` 작성 완료

### CPU Latency 분석
- [x] CPU Spike 재현
- [x] CPU 사용률 급상승 구간 수집
- [x] Watchdog 종료 로그 확보
- [x] `CPU_MAX_OCCUPY` 변경 전후 비교
- [x] `cpu-report.md` 작성 완료

## 4. 요약

| 항목 | OOM Crash | CPU Latency | Deadlock |
|---|---|---|---|
| 장애 유형 | 메모리 누수 | CPU 과점유 | 교착 상태 |
| 발생 조건 | `MEMORY_LIMIT` 낮음 | `CPU_MAX_OCCUPY` 높게 설정 | `MULTI_THREAD_ENABLE=true` |
| 주요 증상 | 메모리 지속 증가 후 강제 종료 | CPU 급상승 후 SIGTERM 종료 | 프로세스는 살아있지만 응답 없음 |
| PID 상태 | 종료됨 | 종료됨 | 살아있음 |
| CPU 변화 | 낮음 | 매우 높음 | 0 |
| Memory 변화 | 지속 상승 | 큰 변화 없음 | 정체 |
| 로그 특징 | `Memory limit exceeded` | `WATCHDOG... SIGTERM` | `WAITING... BLOCKED` |
| 원인 | Heap 객체 누적 | Busy Loop / 과도한 연산 | Lock 순환 대기 |
| OS 관점 | MemoryGuard가 SIGKILL | Watchdog가 SIGTERM | Thread starvation |
| 임시 조치 | `MEMORY_LIMIT` 증가 | `CPU_MAX_OCCUPY` 조정 | 멀티스레드 비활성화 |
| 근본 해결 | 메모리 해제 로직 추가 | 연산 최적화 | Lock 순서 통일 |

## 5. 트러블슈팅

### 5-1. 첫번째 트러블슈팅

* 오류

    student 계정에 환경변수를 저장하기 위해

     ```bash
    source ~/.bashrc
    ```

     를 입력하면

    ```bash
    -sh: 3: source: not found
    ```

     오류가 발생.


* 원인

    이 에러는 현재 shell이 bash가 아니라 sh/dash일 때 나온다.

    ```source``` 명령어는 bash 나 zsh 에서만 사용 가능.

    왜 student 계정이 sh로 들어왔을까?

    ```bash
    useradd -m student
    ```

    이 명령어 때문이다.
    
    Ubuntu에서 ```useradd```는 shell을 명시하지 않으면 기본 shell이 

    ```
    /bin/sh
    ```

    로 설정된다.

* 해결

    * 방법① : student 계정의 기본 shell을 bash로 바꾸기

         root계정에서

         ```bash
         chsh -s /bin/bash student
         ```

         student 계정으로 다시 접속해서

         ```bash
         echo $SHELL
         ```

         또는

         ```bash
         echo $0
         ```

         으로 현재 shell 확인하기.

    * 방법② : sh 명령어 쓰기 

        * sh 에서는 ```source``` 대신에 ```점(.)```을 사용

        * ```bash
          . ~/.bashrc
          ```


### 5-2. 두번째 트러블슈팅

* 오류

    app을 실행하면 앱 실행 기록에는 메모리가 25MB 씩 계속 증가하는데, monitor.log 의 기록에는 MEM:0.0% 로 계속 찍힘.

    ```bash
    # app 기록

    2026-06-17 09:33:23,560 [INFO] [MemoryWorker] Current Heap: 25MB
    2026-06-17 09:33:26,601 [INFO] [MemoryWorker] Current Heap: 50MB
    2026-06-17 09:33:29,651 [INFO] [MemoryWorker] Current Heap: 75MB
    2026-06-17 09:33:32,703 [INFO] [MemoryWorker] Current Heap: 100MB
    2026-06-17 09:33:35,753 [INFO] [MemoryWorker] Current Heap: 125MB
    2026-06-17 09:33:38,804 [INFO] [MemoryWorker] Current Heap: 150MB
    2026-06-17 09:33:38,804 [CRITICAL] [MemoryGuard] Memory limit exceeded (150MB >= 128MB) / (Recommend Over 256MB)
    2026-06-17 09:33:38,805 [CRITICAL] [MemoryGuard] Self-terminating process 40024 to prevent system instability.

    >>> [SYSTEM] SELF-TERMINATED (Memory Limit Exceeded) <<<

    Killed
    ```


    ```bash
    # monitor.log 기록

    === Monitoring PID: 40023 ===
    [2026-06-17 09:33:26] PID:40023 CPU:1.8% MEM:0.0%
    [2026-06-17 09:33:28] PID:40023 CPU:1.1% MEM:0.0%
    [2026-06-17 09:33:30] PID:40023 CPU:0.9% MEM:0.0%
    [2026-06-17 09:33:32] PID:40023 CPU:0.7% MEM:0.0%
    [2026-06-17 09:33:34] PID:40023 CPU:0.6% MEM:0.0%
    [2026-06-17 09:33:36] PID:40023 CPU:0.5% MEM:0.0%
    [2026-06-17 09:33:38] PID:40023 CPU:0.5% MEM:0.0%
    [2026-06-17 09:33:40] Process ended.
    ```

* 원인

    메모리 누수는 부모 프로세스가 아니라 자식 프로세스에서 발생하고 있는데, 부모 프로세스의 PID로 monitor.log를 기록하고 있었음.

    app을 실행하면 PID가 2개(부모프로세스, 자식프로세스)가 잡히는데, 

    현재 monitor.sh의 코드는

    ```bash
    ps -p %PID -o %cpu,%mem --no-headers
    ```

    여기서 ```%MEM```은 시스템 전체 RAM 대비 비율이다. 즉, "전체 시스템의 몇%인가"을 나타낸다. 


* 해결

    * 방법① : 자식 프로세스의 PID 로 monitor.log 에 기록.

        ```bash
        /workspace/scripts/monitor.sh PID
        ```

        PID에 자식 프로세스 PID를 입력.

    * 방법② : 부모프로세스 PID를 넣으면 자식프로세스 PID 까지 합산되게 monitor.sh 개선

        ```bash
        /workspace/scripts/monitor.sh PID
        ```

        여기에 부모프로세스 PID를 넣으면 monitor.sh 에서 자동으로

            1. 부모프로세스 PID 확인
            2. 자식프로세스 PID 검색
            3. 부모 + 자식 프로세스 MEM 합산
            4. 로그 기록

        을 수행하게 변경.

        ```부모프로세스 PID == 자식프로세스 PPID``` 을 이용.

        monitor.sh 코드를 아래로 변경.

            step1. parent resource 읽기

            ```bash
            ps -p $PID -o rss,%cpu
            ```

            step2. child PID 찾기

            ```bash
            CHILD_PID=$(ps --ppid $PID -o pid=)
            ```

            step3. child 있으면 resource 읽기

            ```bash
            ps -p $CHILD_PID -o rss,%cpu
            ```

            step4. 합산하기

            ```bash
            

## 6. 추가 설명

### 6-1. monitor.sh에서 메모리 증가 패턴을 추적하기 위해 사용한 명령어와 데이터 추출 방법


### 6-2. 프로세스의 CPU 사용률을 확인하기 위해 선택한 도구와 적용한 옵션

```bash
ps -o pid,ppid,%cpu,rss,cmd -C agent-leak-app-x86
```

* ps 명령어

| 명령어 | 의미 | 설명 |
| :--- | :--- | :--- |
| ps | process state | 현재 리눅스 시스템에서 실행 중인 프로세스의 상태와 정보를 스냅샷 형태로 출력 |
| -o | Output format | 출력 포맷을 지정. 원하는 항목만을 보여주는 옵션 |
| -C | Command name filter | 명령어 이름 필터. 뒤에 적은 '실행 파일 이름'과 일치하는 프로세스만 필터링해서 보여주는 옵션 | 

```bash
top -p <PID>
```

* top 명령어

| 명령어 | 의미 | 설명 |
| :--- | :--- | :--- |
| top | top | 시스템의 전체적인 자원 상태와 프로세스 순위를 실시간으로 출력 |
| -p | pid filter | 뒤에 적은 특정 프로세스를 지정하는 옵션 |

### 6-3. 프로세스가 "살아있지만 멈춰있는 상태"를 진단하기 위해 어떤 도구를 어떤 순서로 사용했는지 설명

* 프로세스가 살아있는지 먼저 확인

 ```bash
 ps -ef | grep agent
 ```

* CPU/MEM 사용량 확인

 ```bash
 ps -o pid,ppid,%cpu,rss,cmd -C agent-leak-app-x86
 ```

* thread 확인

```bash
ps -L -p <PID>
```

또는

```bash
top -H
```

### 6-4. 메모리 누수가 발생했을 때 애플리케이션의 메모리 보호 정책이 해당 프로세스를 강제 종료하는 이유

OOM Killer가 발동하는 상황까지 가기 전에 애플리케이션 자체적으로 임계치를 정해서 안전하게 프로그램을 종료시키기 위해서이다. 

1. 메모리 누수는 시간이 갈수록 heap 메모리를 계속 점유한다.

    - 메모리 누수는 프로그램이 사용이 끝난 메모리를 반납하지 않고, heap에 데이터가 계속 쌓이는 현상.
    - heap : 프로그램이 실행되는 도중에 필요에 따라 크기를 자유롭게 결정하고 할당받아서 쓰는 '동적 메모리 공간'.
    - stack : 프로그램이 실행될 때 컴파일러에 의해 크기가 미리 결정되며, 함수 호출과 함께 자동으로 생성되고 종료 시 알아서 소멸되는 '정적 메모리 공간'.

2. 메모리가 부족해지면 해당 프로세스만 느려지는 게 아니다.

    - 메모리(RAM)는 모든 프로세스가 나누어 쓰는 공공재이다.
    - 하나의 프로세스가 RAM을 독점하게 되면, 시스템 유지에 필수적인 OS커널조차 메모리가 부족하게 된다.
    - 전체 시스템 응답 속도 저하가 발생, 심하면 시스템 자체가 멈춤.

3. MemoryGuard와 OOM Killer

    |  | MemoryGuard | OOM Killer |
    | :--- | :--- | :--- |
    | 관리 주체 | 애플리케이션 | 리눅스 OS 커널 |
    | 작동 시점 | 정해둔 임계치를 넘었을 때 | 전체 메모리가 꽉 차서 시스템 전체가 멈추기 직전 |
    | 목적 | 프로그램이 설정한 임계치를 넘는 것을 예방 | 시스템 전체가 다운되는 것을 방어 |
    | 비유 | 1차 방어선 | 2차 방어선 |

### 6-5. CPU 과점유 시 단일 프로세스를 종료하는 것이 시스템 보호에 왜 필요한지 근거를 제시

CPU를 과점유 하고 있는 프로세스 하나가 CPU 자원을 독점하여 시스템 전체 응답성을 저하시킬 수 있기 때문이다.

1. CPU는 한정된 공유 자원이다.
    - CPU는 실시간으로 여러 프로세스가 나눠 쓰는 자원이다.

2. 단일 프로세스의 CPU 과점유는 전체 시스템 지연을 만든다.

### 6-6. 교착 상태(Deadlock)가 발생하는 원리를 "상호 배제"와 "순환 대기" 개념으로 설명

교착 상태(Deadlock)는 두 개 이상의 스레드가 서로가 가진 자원을 내놓기만을 기다리면서 아무 작업을 진행하지 못하는 상태를 의미한다.

1. 상호 배제 (Mutual Exclusion)

    - 정의 : 한 번에 하나의 스레드만 특정 자원을 사용할 수 있다.
    - 원리 : 하나의 자원을 여러 스레드가 동시에 수정하면 데이터가 꼬이게 된다. 따라서 하나의 스레드가 그 자원을 쓰고 있다면, 다른 스레드들은 접근하지 못하도록 문을 걸어 잠그는(Lock) 보호 조치를 취한다.
    - 상황 : thread-1이 A자원을 점유하면 다른 스레드는 해당 자원을 사용할 수 없다.

2. 순환 대기 (Circular Wait)

    - 정의 : 스레드들이 서로가 가진 자원을 꼬리에 꼬리를 물고 기다리는 상태
    - 원리
        - thread-1 은 thread-2가 가진 B를 기다림
        - thread-2 은 thread-1이 가진 A를 기다림

결론 : 교착상태(Deadlock)는 여러 스레드가 서로가 점유한 자원을 기다리면서 무한 대기 상태에 빠지는 현상이다. 먼저 상호 배제(Mutual Exclusion)는 특정 자원을 한 번에 하나의 스레드만 사용할 수 있도록 제한하는 특성이다. 이후 순환 대기 (Circular Wait)가 발생하면 교착 상태가 만들어진다.

### 6-7. 로그에서 스레드 간 순환 의존 관계(A→B, B→A)를 어떻게 파악했는지 추적 과정을 설명

```bash
2026-06-17 13:55:27,288 [INFO] [AgentWorker][Worker-Thread-2] LOCK ACQUIRED: [Socket_Pool_B]. (Holding...)
2026-06-17 13:55:27,288 [INFO] [AgentWorker][Worker-Thread-1] LOCK ACQUIRED: [Shared_Memory_A]. (Holding...)
```

Thread-1 이 Shared_Memory_A 의 lock을 획득
Thread-2 가 Socket_Pool_B 의 lock을 획득


```bash
2026-06-17 13:55:29,297 [INFO] [AgentWorker][Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
2026-06-17 13:55:29,297 [INFO] [AgentWorker][Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)
2026-06-17 13:55:29,300 [INFO] [AgentWorker][Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
2026-06-17 13:55:29,301 [INFO] [AgentWorker][Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
```

Thread-1 이 Socket_Pool_B 를 기다림
Thread-2 가 Shared_Memory_A 를 기다림

### 6-8. 만약 이번 미션의 agent-leak-app이 실제 운영 서버에서 동작하고 있었다면, 메모리 누수를 장애 발생 전에 탐지하기 위해 현재의 monitor.sh를 어떻게 개선하겠는가?

현재 monitor.sh는 실시간 상태 확인용 도구로는 충분하지만, 메모리 누수를 사전에 탐지하기에는 한계가 있다. 
이를 개선하려면 단순 수치 출력이 아니라 메모리 증가 추세 분석, 임계치 기반 경고, 자동 알림, 증거 수집 기능이 필요하다.

1. 로그 파일 자동 저장 및 그래프화

    - 현재 방식 : 터미널 출력 중심
    - 개선
        - CSV 저장 (글자와 쉼표만으로 이루어진 초경량 텍스트 파일로 데이터를 저장)
        - Grafana 로 그래프 생성

2. Threshold 기반 Alert 추가

    - 현재 방식 : MEMORY_LIMIT 초과 시 앱 내부 MemoryGuard 가 강제 종료
    - 문제점 : 대응하기에 이미 늦음
    - 개선 : 위험 구간을 미리 경고
        - 임계치의 70% → INFO
        - 임계치의 85% → WARNING
        - 임계치의 95% → CRITICAL

3. Alert Notification

    - 개선 : 경고 발생 시 자동 알림
        - Slack (기업용 협업 메신저 프로그램)
        - Email

### 6-9. 이번 미션에서 겪은 3가지 장애(OOM, CPU Spike, Deadlock) 중 실제 서비스 환경에서 가장 치명적인 것은 무엇이라고 생각하는가? 그 이유와 함께, 해당 장애를 근본적으로 예방하는 방법을 제안

가장 치명적인 장애 : **Deadlock**

1. 이유
    - (1) 장애 감지가 가장 어렵다
        - OOM
            - 메모리가 계속 증가
            - 로그에 명확한 메시지가 존재
        - CPU Spike
            - CPU 사용률이 급상승
            - ```top```, ```ps```로 바로 확인 가능
        - Deadlock
            - 프로세스가 죽지 않음
            - CPU 사용률이 0%, 메모리 변화 없음
            - 겉으로 보기에 "정상 실행 중" 인것처럼 보일 수 있다.
        
    - (2) 자동 복구가 어렵다
        - OOM : MemoryGuard 가 강제 종료
        - CPU Spike : Watchdog 가 강제 종료
        - Deadlock : 계속 대기

    - (3) 시스템 전체로 장애가 전파될 수 있다
        - 하나의 핵심 기능에서 deadlock이 발생하면, 그 기능을 호출하려는 다른 서비스들의 스레드까지 줄줄이 대기 상태로 묶이게 된다.

2. 근본적인 예방 방법

    - (1) Lock 순서 통일

        Deadlock은 보통 lock 획득 순서가 다를 때 발생한다. 락 획득 순서를 통일하면 순환 대기가 사라진다.

        (ex) 모든 스레드가 A를 먼저 획득하고 B를 획득하게 만든다. 

    - (2) Timeout Lock 사용

        lock을 요청할 때 최대 대기 시간(lock timeout)을 설정한다.

        (ex) 3초 동안 자원B를 얻지 못하면, 내가 쥐고 있던 자원A를 내려놓고(unlock) 잠시 후에 다시 시도한다.

정리하자면, OOM과 CPU Spike는 시스템이 "죽여서" 보호할 수 있지만, Deadlock은 프로세스가 살아있는 채로 서비스 전체를 멈출 수 있기 때문에 가장 위험하다.

### 6-10. 만약 동일한 서버에서 OOM과 Deadlock이 동시에 발생했다면, 어떤 순서로 트러블슈팅을 진행하겠는가? 우선순위 판단의 근거를 설명

1단계 : OOM 즉각 조치 (서비스 생존) 
2단계 : Deadlock 분석 및 해결 (재발 방지)

* 1단계 : OOM 즉각 조치 및 서비스 소생

    - 판단 근거
        - 시스템 전체 안정성에 직접적인 영향을 주기 때문
        - Deadlock은 특정 프로세스의 무응답이 문제지만, OOM은 시스템 전체 장애로 확대될 가능성이 크기 때문

* 2단계 : Deadlock 현상 분석 및 원인 파악


결론적으로, 동시에 발생했다면 먼저 OOM을 해결해야한다.
이유는 Deadlock은 서비스 일부를 멈추게 하지만, OOM은 서버 전체를 다운시킬 수 있기 때문이다.

### 6-11. 이번 미션의 환경변수 조정은 임시 조치였다. 만약 소스 코드를 직접 수정할 수 있다면, 각 장애 유형별로 어떤 코드 레벨의 개선을 하겠는가?

1. OOM (Memory Leak)

    - 문제 : 메모리가 25MB → 50MB → 75MB 처럼 선형으로 증가
    
    - 원인

        - cache 리스트에 데이터를 추가(append)만 함.

            ```bash
            # cache : 데이터나 값을 미리 복사해 놓는 임시 저장소

            cache = []

            while True:
                data = load_data()  # 주기적으로 데이터를 가져옴
                cache.append(data)  # 리스트에 계속 추가만 함
            ```

       
    - 코드 개선

        - (1) pop 메서드로 cache에 쌓인 오래된 데이터 제거

            ```bash
            if len(cache) > 100:    # 만약 cache에 저장된 데이터 개수가 100개를 넘어가면
            cache.pop(0)            # 가장 앞에 있는(가장 오래된) 데이터 1개를 삭제

            # pop() : list의 특정 위치 값을 제거하면서, 그 값을 return해준다.
            ```

        - (2) deque 사용

            ```bash
            # deque : (Double_Ended Queue) 양쪽 끝에서 데이터를 넣고 뺄수 있는 자료구조

            from collections import deque

            cache = deque(maxlen=100)

            # 데이터가 100개를 넘으면 자동으로 가장 오래도니 데이터를 삭제하고 우측에 새 데이터를 넣는다.
            ```

        - (3) lru_cache 를 사용

            ```bash
            # LRU = (Least Recently Used) 가장 오랫동안 안 쓴 데이터를 지우는 캐시 알고리즘

            from functools import lru_cache
            import time

            @Lru_cache(maxsize=100)     # 최대 100개의 결과만 메모리에 보관하는 캐시 설정
            ```  

2. CPU Spike

    - 문제 : CPU usage가 58% 까지 상승 후 watchdog 종료

    - 원인

        - 무한 루프

            ```bash
            while True:
              check_status() # 상태를 체크하는 함수
            ```

        위 코드처럼 조건문 탈출도 없고 sleep 없는 ```while True```문을 실행하면, cpu는 쉬지 않고 ```check_status()```를 무한 반복 호출하게 된다.

    - 코드 개선

        - (1) 대기 시간 집어넣기

            ```bash
            time.sleep(1)
            ```

3. Deadlock

    - 문제

        ```bash
        Thread-1 locked Shared_Memory_A
        Thread-1 waiting Socket_Pool_B

        Thread-2 locked Socket_Pool_B
        Thread-2 waiting Shared_Memory_A
        ```

    - 원인

        - (1) 상호 배제 (Mutual Exclusion)
        - (2) 점유 대기 (Hold and Wait)
        - (3) 비선점 (No Preemption)
        - (4) 순환 대기 (Circular Wait)

    - 코드 개선

        - (1) Lock 획득 순서 통일 : 모든 thread가 A 획득 후 B 획득 하도록 변경

            ```bash
            # 모든 thread가 동일 순서

            lockA.acquire()
            lockB.acquire()
            ```

        - (2) Timeout Lock 사용 : 특정 자원을 얻기 위해 대기하는 시간에 제한 시간을 설정

            ```bash
            if lock.acquire(timeout=3):

            else:
                recover()
            ```

        - (3) Lock Free 구조 : 잠금장치(lock)를 사용하지 않음

            - Queue 사용
            - Actor model 사용
            - Message passing 사용

### 6-12. 다시 이 미션을 처음부터 수행한다면, 트러블슈팅 과정에서 어떤 점을 다르게 접근하겠는가?

처음 미션을 수행할때는 OOM, CPU Spike, Deadlock이 뭔지 모르는 상태에서,
환경변수를 하나씩 바꿔가면서 실행 로그를 보고 장애의 원인이 뭔지 파악했다.

만약 다시 미션을 수행한다면 무작정 실행하지 않고, '환경변수를 이렇게 수정을 하면 이런 장애가 발생할 것이다' 라는 가설부터 세우고 그 가설을 로그와 관제 데이터를 통해 검증하는 방식으로 접근할 것이다.

현상을 보고 사후에 원인을 찾는 방식은 많은 시간과 비용이 낭비된다.
가설 검증 기반의 디버깅은 장애 원인의 범위를 좁히고 복구 시간을 단축시킬 수 있음.
