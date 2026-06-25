# [Bug] OOM Crash - Memory Leak으로 인한 MemoryGuard 강제 종료

## 1. Description (현상 설명)

'agent-leak-app-x86' 실행 후 시간이 지날수록 메모리 사용량이 지속적으로 증가하다가, 일정 임계치에 도달하면 애플리케이션이 갑자기 종료되었습니다.

종료 직전 로그에는 MemoryGuard가 메모리 초과를 감지하고 프로세스를 강제 종료했다는 메시지가 출력되었습니다.

* 발생 조건

    * MEMORY_LIMIT=128
    * CPU_MAX_OCCUPY=30
    * MULTI_THREAD_ENABLE=true

## 2. Evidence & Logs (증거 자료)

### 2-1. 프로그램 로그 (MEMORY_LIMIT=128)

```log
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
Current Heap이 25MB 증가하다가, 
MemoryGuard가 임계치 초과를 감지한 즉시 프로그램을 종료했습니다.

### 2-2. monitor.sh 관제 로그

```log
=== Monitoring Parent PID: 169718 ===
[2026-06-17 13:29:14] Parent:169718 Child:169723 CPU:3.8% MEM:69MB
[2026-06-17 13:29:16] Parent:169718 Child:169723 CPU:2.8% MEM:69MB
[2026-06-17 13:29:18] Parent:169718 Child:169723 CPU:2.9% MEM:94MB
[2026-06-17 13:29:20] Parent:169718 Child:169723 CPU:2.6% MEM:119MB
[2026-06-17 13:29:22] Parent:169718 Child:169723 CPU:2.2% MEM:119MB
[2026-06-17 13:29:24] Parent:169718 Child:169723 CPU:2.1% MEM:144MB
[2026-06-17 13:29:26] Process ended.
```

## 3. Root Cause Analysis (원인 분석)

수집된 증거를 바탕으로 문제의 근본 원인은 ```Memory Leak```로 판단됩니다.

애플리케이션 내부 'MemoryWorker'가 지속적으로 heap 메모리를 할당하지만, 이미 사용이 끝난 객체를 해제하지 않는 것으로 보입니다.

결과적으로

 1. heap 메모리가 계속 증가
 2. Garbage Collection 또는 cleanup이 일어나지 않음
 3. Memory_Limit 초과
 4. MemoryGuard 작동
 5. 프로세스 강제 종료


## 4. Workaround & Verification (조치 및 검증)

환경변수 'MEMORY_LIMIT` 값을 상향 조정했습니다.

### 4-1. Before

* 환경변수

 ```bash
 export MEMORY_LIMIT=128
 ```

* 실행 결과

    * Heap 사용량이 25MB씩 지속 증가
    * 150MB에서 강제 종료
    * MemoryGuard가 보호 목적의 self-termination 수행

### 4-2. After

* 환경변수

 ```bash
 export MEMORY_LIMIT=512
 ```
* 로그 결과

 ```bash
 2026-06-21 12:06:44,471 [INFO] [MemoryWorker] Current Heap: 525MB
 2026-06-21 12:06:44,472 [WARNING] [MemoryWorker] Memory Usage Reached Limit (525MB). Starting cleanup...
 2026-06-21 12:06:44,513 [INFO] [System] Memory Cache Flushed. Process Stabilized.

 >>> [SYSTEM] MEMORY RECOVERED (Cache Cleared) <<<
 ```

* 실행 결과

    * 내부 cleaup 수행
    * 프로세스 생존 유지

### 4-3. 비교

| 항목 | Before (128MB) | After (512MB) |
|---|---:|---:|
| 초기 Heap | 25MB | 25MB |
| 종료 시점 | 150MB | 종료되지 않음 |
| 생존 시간 | 약 10초 | 장시간 유지 |
| 결과 | 강제 종료 | Cleanup 후 정상 유지 |

## 5. Conclusion (결론)

* 임시 해결

    * MEMORY_LIMIT 증가

* 근본 해결

    * 불필요한 객체 해제
    * 메모리 누수 코드 수정
