
-- ============================================================================
-- Merge STG_STELLAR_WAITLISTS to DW_STELLAR_WAITLISTS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_WAITLISTS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_WAITLISTS tgt
    USING STG_STELLAR_WAITLISTS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.LOCATION_ID = src.LOCATION_ID,
            tgt.CATEGORY_ID = src.CATEGORY_ID,
            tgt.STYLE_ID = src.STYLE_ID,
            tgt.CUSTOMER_ID = src.CUSTOMER_ID,
            tgt.TIME_ID = src.TIME_ID,
            tgt.TIMEFRAME_ID = src.TIMEFRAME_ID,
            tgt.FIRST_NAME = src.FIRST_NAME,
            tgt.LAST_NAME = src.LAST_NAME,
            tgt.EMAIL = src.EMAIL,
            tgt.PHONE = src.PHONE,
            tgt.DEPARTURE_DATE = src.DEPARTURE_DATE,
            tgt.LENGTH_REQUESTED = src.LENGTH_REQUESTED,
            tgt.WAIT_LIST_TIME = src.WAIT_LIST_TIME,
            tgt.FULFILLED = src.FULFILLED,
            tgt.FULFILLED_DATE = src.FULFILLED_DATE,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, LOCATION_ID, CATEGORY_ID, STYLE_ID, CUSTOMER_ID, TIME_ID, TIMEFRAME_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, DEPARTURE_DATE, LENGTH_REQUESTED, WAIT_LIST_TIME, FULFILLED, FULFILLED_DATE, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.LOCATION_ID, src.CATEGORY_ID, src.STYLE_ID, src.CUSTOMER_ID, src.TIME_ID, src.TIMEFRAME_ID, src.FIRST_NAME, src.LAST_NAME, src.EMAIL, src.PHONE, src.DEPARTURE_DATE, src.LENGTH_REQUESTED, src.WAIT_LIST_TIME, src.FULFILLED, src.FULFILLED_DATE, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_WAITLISTS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_WAITLISTS: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_WAITLISTS;
/
