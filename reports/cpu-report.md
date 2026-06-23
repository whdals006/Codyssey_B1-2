# CPU Latency - CPU 과점유로 인한 Watchdog 강제 종료

## 1. Description (현상 설명)

애플리케이션 실행 후 CPU 사용률이 점진적으로 상승하다가 아래 메시지와 함께 강제 종료되었습니다.

```bash
>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<
Terminated
```

실행 로그 분석 결과 이는 오류가 아니라 내부 보호 시스템인 **Watchdog**가 CPU 과점유를 감지하여 의도적으로 종료시킨 것이었습니다.

* 발생 조건

    * MEMORY_LIMIT=512
    * CPU_MAX_OCCUPY=80
    * MULTI_THREAD_ENABLE=false

## 2. Evidence & Logs (증거 자료)

### 프로그램 로그

```bash
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
[CRITICAL] [CpuWorker] CPU Threshold Violated! (58.86%)

>>> [SYSTEM] WATCHDOG: INITIATING EMERGENCY ABORT (SIGTERM) <<<

Terminated
```

CPU 사용률이 지속적으로 상승하다가 58.86%에서 종료되었습니다.
마지막 로그에서 WATCHDOG에 의해 종료된 것을 확인하였습니다.

## 3. Root Cause Analysis (원인 분석)


애플리케이션 내부 'CpuWorker'가 반복 계산 작업을 수행하면서 CPU 사용량이 계속 증가했습니다.

 1. CpuWorker가 반복 계산 수행
 2. CPU usage 상승
 3. Watchdog 활성화
 4. SIGTERM 으로 프로세스 종료

운영체제 스케줄러는 cpu를 각 프로세스에 분배합니다.
특정 프로세스가 cpu를 과도하게 점유하면

    - 다른 프로세스 스케줄링 지연
    - latency 증가
    - 시스템 응답 저하

문제가 발생하게 됩니다.
이를 방지하기 위해 애플리케이션 내부 Watchdog이 CPU 과점유를 감지하면 강제 종료하도록 설계되어 있습니다.

## 4. Workaround & Verification (조치 및 검증)

CPU 임계값을 조정하여 동작을 비교했습니다.

### Before

```bash
export CPU_MAX_OCCUPY=80
```

### After

```bash
export CPU_MAX_OCCUPY=30
```

### 비교

| 항목 | Before (10%) | After (80%) |
|---|---|---|
| CPU 제한 | 낮음 | 높음 |
| CPU Spike 허용 범위 | 작음 | 큼 |
| 생존 시간 | 짧음 | 길어짐 |
| 종료 시점 | 빠름 | 늦음 |

## 5. Conclusion (결론)

* 임시 해결

    * CPU_MAX_OCCUPY 낮춤

* 근본 해결

    * busy loop 제거
    * sleep interval 추가
    * polling 최적화
    * CPU profiling 수행