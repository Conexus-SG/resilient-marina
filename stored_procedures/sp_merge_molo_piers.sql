
-- ============================================================================
-- Merge STG_MOLO_PIERS to DW_MOLO_PIERS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_MOLO_PIERS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_PIERS tgt
    USING STG_MOLO_PIERS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.NAME = src.NAME,
            tgt.MARINA_LOCATION_ID = src.MARINA_LOCATION_ID,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, NAME, MARINA_LOCATION_ID,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.NAME, src.MARINA_LOCATION_ID,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_PIERS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_PIERS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_PIERS;
/
