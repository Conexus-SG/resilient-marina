-- ============================================================================
-- Merge STG_MOLO_ACCOUNTS to DW_MOLO_ACCOUNTS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_MOLO_ACCOUNTS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_ACCOUNTS tgt
    USING STG_MOLO_ACCOUNTS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.ACCOUNT_STATUS_ID = src.ACCOUNT_STATUS_ID,
            tgt.MARINA_LOCATION_ID = src.MARINA_LOCATION_ID,
            tgt.CONTACT_ID = src.CONTACT_ID,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, ACCOUNT_STATUS_ID, MARINA_LOCATION_ID, CONTACT_ID,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.ACCOUNT_STATUS_ID, src.MARINA_LOCATION_ID, src.CONTACT_ID,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_ACCOUNTS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_ACCOUNTS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_ACCOUNTS;
/
