
-- ============================================================================
-- Merge STG_STELLAR_CUSTOMER_BOATS to DW_STELLAR_CUSTOMER_BOATS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_CUSTOMER_BOATS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_CUSTOMER_BOATS tgt
    USING STG_STELLAR_CUSTOMER_BOATS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.CUSTOMER_ID = src.CUSTOMER_ID,
            tgt.SLIP_ID = src.SLIP_ID,
            tgt.BOAT_NAME = src.BOAT_NAME,
            tgt.BOAT_NUMBER = src.BOAT_NUMBER,
            tgt.LENGTH_FEET = src.LENGTH_FEET,
            tgt.WIDTH_FEET = src.WIDTH_FEET,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, CUSTOMER_ID, SLIP_ID, BOAT_NAME, BOAT_NUMBER, LENGTH_FEET, WIDTH_FEET, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.CUSTOMER_ID, src.SLIP_ID, src.BOAT_NAME, src.BOAT_NUMBER, src.LENGTH_FEET, src.WIDTH_FEET, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_CUSTOMER_BOATS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_CUSTOMER_BOATS: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_CUSTOMER_BOATS;
/
