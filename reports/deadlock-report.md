# [Bug] Deadlock - 멀티스레드 환경에서 교착상태 발생으로 프로세스 무응답

## 1. Description (현상 설명)

애플리케이션 실행 후 프로세스가 종료되지 않았지만, 로그 출력이 멈추고 CPU,메모리 변화가 없는 상태가 지속되었습니다.

PID는 살아 있으나 작업이 진행되지 않는 전형적인 Deadlock 상태였습니다.

* 발생 조건

    * MEMORY_LIMIT=512
    * CPU_MAX_OCCUPY=30
    * MULTI_THREAD_ENABLE=true

## 2. Evidence & Logs (증거 자료)

### 프로그램 마지막 로그

```log
[Worker-Thread-1] Need resource [Socket_Pool_B] to finish job.
[Worker-Thread-1] WAITING for [Socket_Pool_B]... (Status: BLOCKED)

[Worker-Thread-2] Need resource [Shared_Memory_A] to write logs.
[Worker-Thread-2] WAITING for [Shared_Memory_A]... (Status: BLOCKED)
```

로그가 여기서 완전히 멈췄습니다.

### PID 존재 확인

```bash
ps -ef | grep agent | grep -v grep
```

```bash
# 결과

student 184713 163493 0 ./agent-leak-app-x86
student 184714 184713 0 ./agent-leak-app-x86
```

프로세스가 종료되지 않았습니다.

### Thread 상태 확인

```bash
ps -L -p 184714
```

```bash
# 결과

PID     LWP     TTY      TIME CMD
184714  184714  pts/1    00:00:00 agent-leak-app
184714  184895  pts/1    00:00:00 agent-leak-app
184714  184896  pts/1    00:00:00 agent-leak-app
```

main thread 1개와 work thread 2개의 존재를 확인하였습니다.
TIME 항목에서 모두 대기 상태인 것을 알 수 있습니다.

### CPU, MEM 확인

```bash
ps -o pid,ppid,%cpu,rss,cmd -C agent-leak-app-x86
```

```bash
# 결과

   PID    PPID %CPU   RSS CMD
184713  163493  0.0  2092 ./agent-leak-app-x86
184714  184713  0.0 17960 ./agent-leak-app-x86
```

프로세스는 살아 있지만, CPU 사용량이 없는 것을 확인하였습니다.


## 3. Root Cause Analysis (원인 분석)

### 현재 상태

* Thread-1

    * Shared_Memory_A 보유 (lock 획득)
    * Socket_Pool_B 대기

* Thread-2

    * Socket_Pool_B 보유 (lock 획득)
    * Shared_Memory_A 대기

Thread-1 은 B 자원을 기다리고 있고
Thread-2 는 A 자원을 기다리고 있는 상태

즉, 서로가 상대가 가진 자원을 기다리고 있습니다.

### Deadlock 4대 조건 분석

 1. Mutual Exclusion (상호 배제) : 자원은 동시에 하나의 스레드만 점유 가능.
 2. Hold and Wait (점유 대기) : 각 스레드가 자원을 하나 점유한 상태에서 추가 자원을 기다림.
 3. No Preemption (비선점) : 강제로 lock을 뺏을 수 없음.
 4. Circular Wait (순환 대기) : A는 B가 가진 걸 기다리고, B는 A가 가진 걸 기다리는 순환 구조.

위 조건을 모두 충족하고 있습니다.
 
## 4. Workaround & Verification (조치 및 검증)

### Before

```bash
export MULTI_THREAD_ENABLE=true
```

* 결과

    * Deadlock 발생
    * 로그 멈춤
    * CPU idle
    * PID 생존

### After

```bash
export MULTI_THREAD_ENABLE=false
```

* 결과

    * Scheduler 정상 수행
    * Memory/CPU worker 정상 동작

### 비교

| 항목 | Before (true) | After (false) |
|---|---|---|
| 멀티스레드 | 활성화 | 비활성화 |
| 프로세스 상태 | Hang | 정상 |
| CPU 사용 | 0% | 정상 변동 |
| 로그 출력 | 중단 | 지속 |
| Deadlock | 발생 | 없음 |

## 5. Conclusion (결론)

* 임시 해결

    * 멀티스레드 비활성화

* 근본 해결

    * Lock 획득 순서 통일
    * Timeout 기반 lock 사용
    * try-lock 도입

