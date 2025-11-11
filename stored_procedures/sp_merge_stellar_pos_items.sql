
-- ============================================================================
-- Merge STG_STELLAR_POS_ITEMS to DW_STELLAR_POS_ITEMS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_POS_ITEMS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_POS_ITEMS tgt
    USING STG_STELLAR_POS_ITEMS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.LOCATION_ID = src.LOCATION_ID,
            tgt.SKU = src.SKU,
            tgt.ITEM_NAME = src.ITEM_NAME,
            tgt.COST = src.COST,
            tgt.PRICE = src.PRICE,
            tgt.TAX_EXEMPT = src.TAX_EXEMPT,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, LOCATION_ID, SKU, ITEM_NAME, COST, PRICE, TAX_EXEMPT, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.LOCATION_ID, src.SKU, src.ITEM_NAME, src.COST, src.PRICE, src.TAX_EXEMPT, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_POS_ITEMS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_POS_ITEMS: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_POS_ITEMS;
/
