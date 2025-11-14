-- ============================================================================
-- Merge STG_MOLO_ACCOUNTS to DW_MOLO_ACCOUNTS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_MOLO_ACCOUNTS(
    p_inserted_count OUT NUMBER,
    p_updated_count OUT NUMBER
)
IS
BEGIN
    -- Insert new records that don't exist in DW
    INSERT INTO DW_MOLO_ACCOUNTS (
        ID, ACCOUNT_STATUS_ID, MARINA_LOCATION_ID, CONTACT_ID,
        DW_LAST_INSERTED,
        DW_LAST_UPDATED
    )
    SELECT 
        src.ID, src.ACCOUNT_STATUS_ID, src.MARINA_LOCATION_ID, src.CONTACT_ID,
        SYSTIMESTAMP,
        SYSTIMESTAMP
    FROM STG_MOLO_ACCOUNTS src
    WHERE NOT EXISTS (
        SELECT 1 FROM DW_MOLO_ACCOUNTS tgt WHERE tgt.ID = src.ID
    );
    
    p_inserted_count := SQL%ROWCOUNT;
    
    -- Update existing records where data has changed
    UPDATE DW_MOLO_ACCOUNTS tgt
    SET (
        tgt.ACCOUNT_STATUS_ID, tgt.MARINA_LOCATION_ID, tgt.CONTACT_ID,
        tgt.DW_LAST_UPDATED
    ) = (
        SELECT 
            src.ACCOUNT_STATUS_ID, src.MARINA_LOCATION_ID, src.CONTACT_ID,
            SYSTIMESTAMP
        FROM STG_MOLO_ACCOUNTS src
        WHERE src.ID = tgt.ID
    )
    WHERE EXISTS (
        SELECT 1 FROM STG_MOLO_ACCOUNTS src
        WHERE src.ID = tgt.ID
        AND (
            NVL(tgt.ACCOUNT_STATUS_ID, -1) != NVL(src.ACCOUNT_STATUS_ID, -1)
            OR NVL(tgt.MARINA_LOCATION_ID, -1) != NVL(src.MARINA_LOCATION_ID, -1)
            OR NVL(tgt.CONTACT_ID, -1) != NVL(src.CONTACT_ID, -1)
        )
    );
    
    p_updated_count := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_ACCOUNTS: Inserted ' || p_inserted_count || ', Updated ' || p_updated_count || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_ACCOUNTS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_ACCOUNTS;
