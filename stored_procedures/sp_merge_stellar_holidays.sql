
-- ============================================================================
-- Merge STG_STELLAR_HOLIDAYS to DW_STELLAR_HOLIDAYS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_HOLIDAYS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_HOLIDAYS tgt
    USING STG_STELLAR_HOLIDAYS src
    ON (tgt.LOCATION_ID = src.LOCATION_ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.HOLIDAY_DATE = src.HOLIDAY_DATE,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            LOCATION_ID, HOLIDAY_DATE,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.LOCATION_ID, src.HOLIDAY_DATE,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_HOLIDAYS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_HOLIDAYS: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_HOLIDAYS;
/
