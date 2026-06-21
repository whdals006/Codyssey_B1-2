# B1-2 리눅스 프로세스 및 시스템 리소스 트러블슈팅

## 1.

## 2.

## 3.

## 4. 

| 장애 유형 | OOM Crash | CPU Latency | Deadlock |
| :--- | :--- | :--- | :--- |
| 프로세스 상태 | 죽음 | 느려짐 | 유지됨 |
| CPU 사용량 패턴 | 안정적 | 90% 이상으로 상승 | 0% (정체) |
| MEM 사용량 패턴 | 급상승 | 안정적 | 변화X (정체) |

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
            