
-- ============================================================================
-- Merge STG_STELLAR_STYLE_PRICES to DW_STELLAR_STYLE_PRICES
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_STYLE_PRICES
IS
    v_inserted NUMBER := 0;
    v_updated NUMBER := 0;
    v_timestamp TIMESTAMP := SYSTIMESTAMP;
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
            tgt.DW_LAST_UPDATED = v_timestamp
        WHERE (
            NVL(tgt.TIME_ID, -999) <> NVL(src.TIME_ID, -999) OR
            NVL(tgt.DEFAULT_PRICE, -999.999) <> NVL(src.DEFAULT_PRICE, -999.999) OR
            NVL(tgt.HOLIDAY, -999.999) <> NVL(src.HOLIDAY, -999.999) OR
            NVL(tgt.SATURDAY, -999.999) <> NVL(src.SATURDAY, -999.999) OR
            NVL(tgt.SUNDAY, -999.999) <> NVL(src.SUNDAY, -999.999) OR
            NVL(tgt.MONDAY, -999.999) <> NVL(src.MONDAY, -999.999) OR
            NVL(tgt.TUESDAY, -999.999) <> NVL(src.TUESDAY, -999.999) OR
            NVL(tgt.WEDNESDAY, -999.999) <> NVL(src.WEDNESDAY, -999.999) OR
            NVL(tgt.THURSDAY, -999.999) <> NVL(src.THURSDAY, -999.999) OR
            NVL(tgt.FRIDAY, -999.999) <> NVL(src.FRIDAY, -999.999) OR
            NVL(tgt.CREATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) <> NVL(src.CREATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) OR
            NVL(tgt.UPDATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) <> NVL(src.UPDATED_AT, TO_TIMESTAMP('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
        )
    WHEN NOT MATCHED THEN
        INSERT (
            TIME_ID, DEFAULT_PRICE, HOLIDAY, SATURDAY, SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.TIME_ID, src.DEFAULT_PRICE, src.HOLIDAY, src.SATURDAY, src.SUNDAY, src.MONDAY, src.TUESDAY, src.WEDNESDAY, src.THURSDAY, src.FRIDAY, src.CREATED_AT, src.UPDATED_AT,
            v_timestamp,
            v_timestamp
        );
    
    SELECT COUNT(*) INTO v_inserted FROM DW_STELLAR_STYLE_PRICES WHERE DW_LAST_INSERTED = v_timestamp;
    SELECT COUNT(*) INTO v_updated FROM DW_STELLAR_STYLE_PRICES WHERE DW_LAST_UPDATED = v_timestamp AND DW_LAST_INSERTED < v_timestamp;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_STYLE_PRICES: ' || v_inserted || ' inserted, ' || v_updated || ' updated');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_STYLE_PRICES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_STYLE_PRICES;
/
