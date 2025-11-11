
-- ============================================================================
-- Merge STG_STELLAR_POS_SALES to DW_STELLAR_POS_SALES
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_POS_SALES
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_POS_SALES tgt
    USING STG_STELLAR_POS_SALES src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.LOCATION_ID = src.LOCATION_ID,
            tgt.ADMIN_ID = src.ADMIN_ID,
            tgt.CUSTOMER_NAME = src.CUSTOMER_NAME,
            tgt.SUB_TOTAL = src.SUB_TOTAL,
            tgt.TAX_1 = src.TAX_1,
            tgt.GRAND_TOTAL = src.GRAND_TOTAL,
            tgt.AMOUNT_PAID = src.AMOUNT_PAID,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DELETED_AT = src.DELETED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, LOCATION_ID, ADMIN_ID, CUSTOMER_NAME, SUB_TOTAL, TAX_1, GRAND_TOTAL, AMOUNT_PAID, CREATED_AT, UPDATED_AT, DELETED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.LOCATION_ID, src.ADMIN_ID, src.CUSTOMER_NAME, src.SUB_TOTAL, src.TAX_1, src.GRAND_TOTAL, src.AMOUNT_PAID, src.CREATED_AT, src.UPDATED_AT, src.DELETED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_POS_SALES: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_POS_SALES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_POS_SALES;
/
