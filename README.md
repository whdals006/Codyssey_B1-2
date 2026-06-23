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
            