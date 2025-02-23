DROP SCHEMA public CASCADE;
CREATE SCHEMA public;


SET timezone = 'Asia/Seoul';

CREATE TYPE roles AS ENUM ('교장', '교감', '부장교사', '교사'); 

CREATE TABLE users(                                                 -- 사용자 테이블
    id SMALLSERIAL PRIMARY KEY,                                     -- 사용자 고유번호
    name VARCHAR(30) NOT NULL,                                      -- 사용자 이름
    role roles NOT NULL DEFAULT '교사'                              -- 사용자 직급
);


CREATE TABLE documents(                                             -- 문서 테이블
    id SERIAL PRIMARY KEY,                                          -- 문서 고유번호
    title VARCHAR(50) NOT NULL,                                     -- 문서 제목
    content TEXT NOT NULL,                                          -- 문서 내용
    user_id SMALLSERIAL REFERENCES users(id),                       -- 작성자 고유번호
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP       -- 작성 일시
);


CREATE TYPE status AS ENUM ('대기', '검토 중', '반려', '승인');

CREATE TABLE approvals(                                             -- 결재 테이블
    id SERIAL PRIMARY KEY,                                          -- 결재 고유번호
    document_id SERIAL REFERENCES documents(id) ON DELETE CASCADE,  -- 문서 고유번호
    user_id SMALLSERIAL REFERENCES users(id),                       -- 결재자 고유번호
    approval_order SMALLINT NOT NULL,                               -- 결재 순서
    status status NOT NULL DEFAULT '대기',                          -- 결재 상태
    content TEXT,                                                   -- 사유 (선택)
    updated_at TIMESTAMPTZ                                          -- 결재 일시 (승인/반려만 해당)
);


-- approval_order가 1인 경우 status를 자동으로 '검토 중'으로 설정하는 트리거 함수 생성
CREATE OR REPLACE FUNCTION set_status_for_first_approver()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.approval_order = 1 AND NEW.status = '대기' THEN
        NEW.status = '검토 중';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 함수를 실행할 트리거 생성
CREATE TRIGGER set_status_trigger
BEFORE INSERT OR UPDATE ON approvals
FOR EACH ROW
EXECUTE FUNCTION set_status_for_first_approver();


-- 이전 approval_order의 status가 '승인'인 경우 다음 approval_order의 status를 자동으로 '검토 중'으로 설정
CREATE OR REPLACE FUNCTION update_approval_status()
RETURNS TRIGGER AS $$
DECLARE
    next_order INT;
    max_order INT;
BEGIN
    -- 현재 문서의 최대 approval_order 값을 가져옵니다.
    SELECT MAX(approval_order) INTO max_order
    FROM approvals
    WHERE document_id = NEW.document_id;

    -- 승인된 경우에만 다음 순서의 상태를 변경합니다.
    IF NEW.status = '승인' THEN
        next_order := NEW.approval_order + 1;
        
        -- 다음 순서가 존재하는 경우 상태를 '검토 중'으로 변경합니다.
        IF next_order <= max_order THEN
            UPDATE approvals
            SET status = '검토 중'
            WHERE document_id = NEW.document_id AND approval_order = next_order;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_approval_status_trigger
AFTER UPDATE OF status ON approvals
FOR EACH ROW
EXECUTE FUNCTION update_approval_status();


-- status가 승인/반려시 updated_at 컬럼을 자동으로 현재 시간으로 업데이트
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_approvals_modtime
BEFORE UPDATE ON approvals
FOR EACH ROW
WHEN (NEW.status IN ('승인', '반려'))
EXECUTE FUNCTION update_modified_column();


-- 교사 정보 입력
INSERT INTO "users"("name","role") VALUES('장교장','교장');
INSERT INTO "users"("name","role") VALUES('황교감','교감');
INSERT INTO "users"("name","role") VALUES('장부장','부장교사');
INSERT INTO "users"("name") VALUES('김교사');


-- 문서 정보 입력
INSERT INTO "documents"("title","content","user_id") VALUES('현장 학습 계획 승인 요청드립니다.','25년 4월 15일 현장학습 경복궁으로 가려합니다.',4);
INSERT INTO "documents"("title","content","user_id") VALUES('방과후 수업 프로그램 제안합니다.','아이들을 위해 코딩 방과후 수업을 여는 것이 좋겠습니다.',4);


-- 결재 정보 입력(문서를 결재에 올린 직후)

INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,3,1);
INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,2,2);
INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(1,1,3);
INSERT INTO "approvals"("document_id","user_id","approval_order") VALUES(2,3,1);

## 장부장(3)의 결재 승인
UPDATE approvals SET status = '승인' WHERE id = 1;

## 황교감(2)의 결재 반려
UPDATE approvals SET status = '반려', content='63빌딩을 더 좋아할 것 같습니다.' WHERE id = 2;






SELECT d.id, d.title, d.content, u.name AS author_name, d.created_at
FROM documents d
JOIN approvals ar ON d.id = ar.document_id
JOIN users u ON d.user_id = u.id
WHERE ar.user_id = 3 AND ar.status = '검토 중';

