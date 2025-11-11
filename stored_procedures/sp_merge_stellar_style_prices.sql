
-- ============================================================================
-- Merge STG_STELLAR_STYLE_PRICES to DW_STELLAR_STYLE_PRICES
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_STYLE_PRICES
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_STYLE_PRICES tgt
    USING STG_STELLAR_STYLE_PRICES src
    ON (tgt.TIME_ID = src.TIME_ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.DEFAULT_PRICE = src.DEFAULT_PRICE,
            tgt.HOLIDAY = src.HOLIDAY,
            tgt.SATURDAY = src.SATURDAY,
            tgt.SUNDAY = src.SUNDAY,
            tgt.MONDAY = src.MONDAY,
            tgt.TUESDAY = src.TUESDAY,
            tgt.WEDNESDAY = src.WEDNESDAY,
            tgt.THURSDAY = src.THURSDAY,
            tgt.FRIDAY = src.FRIDAY,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            TIME_ID, DEFAULT_PRICE, HOLIDAY, SATURDAY, SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.TIME_ID, src.DEFAULT_PRICE, src.HOLIDAY, src.SATURDAY, src.SUNDAY, src.MONDAY, src.TUESDAY, src.WEDNESDAY, src.THURSDAY, src.FRIDAY, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_STYLE_PRICES: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_STYLE_PRICES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_STYLE_PRICES;
/
