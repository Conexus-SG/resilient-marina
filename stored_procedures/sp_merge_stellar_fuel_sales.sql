
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_STELLAR_FUEL_SALES" 
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_FUEL_SALES tgt
    USING STG_STELLAR_FUEL_SALES src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.LOCATION_ID = src.LOCATION_ID,
            tgt.ADMIN_ID = src.ADMIN_ID,
            tgt.CUSTOMER_NAME = src.CUSTOMER_NAME,
            tgt.FUEL_TYPE = src.FUEL_TYPE,
            tgt.QTY = src.QTY,
            tgt.PRICE = src.PRICE,
            tgt.SUB_TOTAL = src.SUB_TOTAL,
            tgt.TIP = src.TIP,
            tgt.GRAND_TOTAL = src.GRAND_TOTAL,
            tgt.AMOUNT_PAID = src.AMOUNT_PAID,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DELETED_AT = src.DELETED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, LOCATION_ID, ADMIN_ID, CUSTOMER_NAME, FUEL_TYPE, QTY, PRICE, SUB_TOTAL, TIP, GRAND_TOTAL, AMOUNT_PAID, CREATED_AT, UPDATED_AT, DELETED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.LOCATION_ID, src.ADMIN_ID, src.CUSTOMER_NAME, src.FUEL_TYPE, src.QTY, src.PRICE, src.SUB_TOTAL, src.TIP, src.GRAND_TOTAL, src.AMOUNT_PAID, src.CREATED_AT, src.UPDATED_AT, src.DELETED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_FUEL_SALES: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_FUEL_SALES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_FUEL_SALES;
/