
-- ============================================================================
-- Merge STG_MOLO_COUNTRIES to DW_MOLO_COUNTRIES
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_MOLO_COUNTRIES
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_COUNTRIES tgt
    USING STG_MOLO_COUNTRIES src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.NAME = src.NAME,
            tgt.CODE = src.CODE,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, NAME, CODE,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.NAME, src.CODE,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_COUNTRIES: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_COUNTRIES: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_COUNTRIES;
/
