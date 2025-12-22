
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_MOLO_ACCOUNT_STATUS" 
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_ACCOUNT_STATUS tgt
    USING STG_MOLO_ACCOUNT_STATUS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.NAME = src.NAME,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
        WHERE 
            NVL(tgt.NAME, '~') != NVL(src.NAME, '~')
    WHEN NOT MATCHED THEN
        INSERT (
            ID, NAME,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.NAME,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_ACCOUNT_STATUS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_ACCOUNT_STATUS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_ACCOUNT_STATUS;
/