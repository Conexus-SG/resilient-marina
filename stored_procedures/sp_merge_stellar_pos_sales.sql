
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_STELLAR_POS_SALES" 
IS
    v_inserted NUMBER := 0;
    v_updated NUMBER := 0;
    v_timestamp TIMESTAMP := SYSTIMESTAMP;
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
            tgt.DW_LAST_UPDATED = v_timestamp
        WHERE (
            NVL(tgt.ID, -999) <> NVL(src.ID, -999) OR
            NVL(tgt.LOCATION_ID, -999) <> NVL(src.LOCATION_ID, -999) OR
            NVL(tgt.ADMIN_ID, -999) <> NVL(src.ADMIN_ID, -999) OR
            NVL(tgt.CUSTOMER_NAME, '~NULL~') <> NVL(src.CUSTOMER_NAME, '~NULL~') OR
            NVL(tgt.SUB_TOTAL, -999.999) <> NVL(src.SUB_TOTAL, -999.999) OR
            NVL(tgt.TAX_1, -999.999) <> NVL(src.TAX_1, -999.999) OR
            NVL(tgt.GRAND_TOTAL, -999.999) <> NVL(src.GRAND_TOTAL, -999.999) OR
            NVL(tgt.AMOUNT_PAID, -999.999) <> NVL(src.AMOUNT_PAID, -999.999) OR
            NVL(tgt.CREATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) <> NVL(src.CREATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) OR
            NVL(tgt.UPDATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) <> NVL(src.UPDATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) OR
            NVL(tgt.DELETED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) <> NVL(src.DELETED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
        )
    WHEN NOT MATCHED THEN
        INSERT (
            ID, LOCATION_ID, ADMIN_ID, CUSTOMER_NAME, SUB_TOTAL, TAX_1, GRAND_TOTAL, AMOUNT_PAID, CREATED_AT, UPDATED_AT, DELETED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.LOCATION_ID, src.ADMIN_ID, src.CUSTOMER_NAME, src.SUB_TOTAL, src.TAX_1, src.GRAND_TOTAL, src.AMOUNT_PAID, src.CREATED_AT, src.UPDATED_AT, src.DELETED_AT,
            v_timestamp,
            v_timestamp
        );
    
    -- Count inserts and updates
    SELECT COUNT(*) INTO v_inserted 
    FROM DW_STELLAR_POS_SALES 
    WHERE DW_LAST_INSERTED = v_timestamp;
    
    SELECT COUNT(*) INTO v_updated 
    FROM DW_STELLAR_POS_SALES 
    WHERE DW_LAST_UPDATED = v_timestamp 
    AND DW_LAST_INSERTED < v_timestamp;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_POS_SALES: ' || v_inserted || ' inserted, ' || v_updated || ' updated');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_POS_SALES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_POS_SALES;
/