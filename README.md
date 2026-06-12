# B1-2 리눅스 프로세스 및 시스템 리소스 트러블슈팅

## 1.

## 2.

## 3.

## 4.

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
