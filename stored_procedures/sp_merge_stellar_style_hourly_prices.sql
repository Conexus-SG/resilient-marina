
-- ============================================================================
-- Merge STG_STELLAR_STYLE_HOURLY_PRICES to DW_STELLAR_STYLE_HOURLY_PRICES
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_STYLE_HOURLY_PRICES
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_STYLE_HOURLY_PRICES tgt
    USING STG_STELLAR_STYLE_HOURLY_PRICES src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.STYLE_ID = src.STYLE_ID,
            tgt.SEASON_ID = src.SEASON_ID,
            tgt.HOURLY_TYPE = src.HOURLY_TYPE,
            tgt.DEFAULT_PRICE = src.DEFAULT_PRICE,
            tgt.HOLIDAY = src.HOLIDAY,
            tgt.SATURDAY = src.SATURDAY,
            tgt.SUNDAY = src.SUNDAY,
            tgt.MONDAY = src.MONDAY,
            tgt.TUESDAY = src.TUESDAY,
            tgt.WEDNESDAY = src.WEDNESDAY,
            tgt.THURSDAY = src.THURSDAY,
            tgt.FRIDAY = src.FRIDAY,
            tgt.DAY_DISCOUNT = src.DAY_DISCOUNT,
            tgt.UNDER_ONE_HOUR = src.UNDER_ONE_HOUR,
            tgt.FIRST_HOUR_AM = src.FIRST_HOUR_AM,
            tgt.FIRST_HOUR_PM = src.FIRST_HOUR_PM,
            tgt.MAX_PRICE = src.MAX_PRICE,
            tgt.MIN_HOURS = src.MIN_HOURS,
            tgt.MAX_HOURS = src.MAX_HOURS,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, STYLE_ID, SEASON_ID, HOURLY_TYPE, DEFAULT_PRICE, HOLIDAY, SATURDAY, SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, DAY_DISCOUNT, UNDER_ONE_HOUR, FIRST_HOUR_AM, FIRST_HOUR_PM, MAX_PRICE, MIN_HOURS, MAX_HOURS, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.STYLE_ID, src.SEASON_ID, src.HOURLY_TYPE, src.DEFAULT_PRICE, src.HOLIDAY, src.SATURDAY, src.SUNDAY, src.MONDAY, src.TUESDAY, src.WEDNESDAY, src.THURSDAY, src.FRIDAY, src.DAY_DISCOUNT, src.UNDER_ONE_HOUR, src.FIRST_HOUR_AM, src.FIRST_HOUR_PM, src.MAX_PRICE, src.MIN_HOURS, src.MAX_HOURS, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_STYLE_HOURLY_PRICES: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_STYLE_HOURLY_PRICES: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_STYLE_HOURLY_PRICES;
/
