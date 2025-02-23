# 문제 3

## 여러 단계의 승인 및 반려가 가능한 결재 시스템을 구축하는 시나리오
  
테이블과 속성 최소한으로 필요한 것만 작성했습니다.  
     
    
### 필요한 테이블을 최소한으로 정의해 주세요.

1. 사용자 테이블 (users)  

|키|속성명|타입|설명|필수|기본값|
|---|---|---|---|---|---|
|PK|id|SMALLSERIAL|사용자 고유번호|자동 증분| |
| |name|varchar(30)|사용자 이름|O| |
| |role|('교장', '교감', '부장교사', '교사') 중 택 1|직급|O|'교사'|

2. 문서 테이블 (documents)

|키|속성명|타입|설명|필수|기본값|  
|---|---|---|---|---|---|  
|PK|id|SERIAL|문서 고유번호|자동 증분| |  
| |title|varchar(50)|문서 제목|O| |
| |content|TEXT|문서 내용|O| |
|FK|user_id|SMALLSERIAL|작성자 고유번호|O| |
| |created_at|TIMESTAMPTZ|작성 일시|O|현재 일시|

3. 결재 테이블 (approvals)

|키|속성명|타입|설명|필수|기본값|  
|---|---|---|---|---|---|  
|PK|id|SERIAL|결재 고유번호|자동 증분| | 
|FK|document_id|SERIAL|문서 고유번호|O| |
|FK|user_id|SMALLSERIAL|결재자 고유번호|O| |
| |approval_order|SMALLINT|결재 순서|O| |
| |status|('대기', '검토 중', '반려', '승인') 택 1|결재 상태|O|'대기'|
| |content|TEXT|사유|X| |
| |updated_at|TIMESTAMPTZ|결재 일시(승인/반려만 해당)|X|현재 일시|


|결재 상태|설명| 
|---|---| 
|대기|아직 결재 순서가 아닐 때| 
|검토 중|현재 결재할 순서일 때| 
|승인/반려|결재가 완료되었을 때| 


- 문서 삭제할 때 관련된 모든 결재 삭제
- TIMESTAMPTZ은 서울 시간대 기준
- 사용자 고유번호는 SMALLSERIAL 2바이트(1~32,767)
- 문서, 결재 고유번호는 SERIAL 4바이트(1~2,147,483,647)
- 결재 순서가 첫 번째일 때 결재 상태를 자동으로 '검토 중'으로 설정
- 이전 결재자가 '승인'할 때 다음 결재자의 결재 상태를 자동으로 '검토 중'으로 설정
- 결재 승인/반려시 결재 테이블의 결재일시(updated_at)를 자동으로 현재 일시로 업데이트

---

### 다음 문제를 풀기 전, 정보를 입력하겠습니다.

- 교사 정보 입력
    ```
    INSERT INTO "users"("name","role") VALUES('장교장','교장');
    INSERT INTO "users"("name","role") VALUES('황교감','교감');
    INSERT INTO "users"("name","role") VALUES('장부장','부장교사');
    INSERT INTO "users"("name") VALUES('김교사');
    ```

- 문서 정보 입력
    ```
    INSERT INTO "documents"("title","content","user_id") VALUES('현장 학습 계획 승인 요청합니다.','25년 4월 15일 현장학습 경복궁으로 가려 합니다.',4);
    INSERT INTO "documents"("title","content","user_id") VALUES('방과후 수업 프로그램 제안합니다.','아이들을 위해 코딩 방과후 수업을 여는 것이 좋겠습니다.',4);
    ```

- 결재 정보 입력(실제 서비스는 문서를 결재 올리면 바로 생성됩니다.)
    ```
    INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,3,1);
    INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,2,2);
    INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,1,3);
    INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(2,3,1);
    ```

- 장부장(3)의 현장 학습 문서 결재 승인
    ```
    UPDATE approvals SET status = '승인' WHERE id = 1;
    ```

- 황교감(2)의 현장 학습 문서 결재 반려
    ```
    UPDATE approvals SET status = '반려', content = '63빌딩을 더 좋아할 것 같습니다.' WHERE id = 2;
    ```

---

### 특정 사용자가 처리해야 할 결재 건을 나열하는 query를 작성해주세요.

특정 사용자가 결재자 고유번호 속성에 존재하고 결재 상태가 '검토 중'이라면 해당하는 문서를 찾아 문서의 고유번호, 제목, 내용, 작성자 이름, 작성 일시를 찾아내는 쿼리문입니다. 

- 특정 사용자를 장부장(<b>ar.user_id=3</b>)이라고 가정한다면,

    ```
    SELECT d.id, d.title, d.content, u.name AS author_name, d.created_at
    FROM documents d
    JOIN approvals ar ON d.id = ar.document_id
    JOIN users u ON d.user_id = u.id
    WHERE ar.user_id = 3 AND ar.status = '검토 중';
    ```
    현장 학습 문서는 결재를 완료했고 방과후 수업 문서는 첫 번째 결재 순서지만 결재를 완료하지 않았으므로 '검토 중'에 해당하여, 방과후 수업 문서만 결과로 나옵니다.
