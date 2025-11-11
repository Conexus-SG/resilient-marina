
-- ============================================================================
-- Merge STG_STELLAR_LOCATIONS to DW_STELLAR_LOCATIONS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_STELLAR_LOCATIONS
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO DW_STELLAR_LOCATIONS tgt
    USING STG_STELLAR_LOCATIONS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.CODE = src.CODE,
            tgt.LOCATION_NAME = src.LOCATION_NAME,
            tgt.LOCATION_TYPE = src.LOCATION_TYPE,
            tgt.MINIMUM_1 = src.MINIMUM_1,
            tgt.MINIMUM_2 = src.MINIMUM_2,
            tgt.DELIVERY = src.DELIVERY,
            tgt.FRONTEND = src.FRONTEND,
            tgt.PRICING = src.PRICING,
            tgt.IS_INTERNAL = src.IS_INTERNAL,
            tgt.IS_CANCELED = src.IS_CANCELED,
            tgt.CANCEL_REASON = src.CANCEL_REASON,
            tgt.CANCEL_DATE = src.CANCEL_DATE,
            tgt.IS_TRANSFERRED = src.IS_TRANSFERRED,
            tgt.TRANSFER_DESTINATION = src.TRANSFER_DESTINATION,
            tgt.MODULE_TYPE = src.MODULE_TYPE,
            tgt.OPERATING_LOCATION = src.OPERATING_LOCATION,
            tgt.ZOHO_ID = src.ZOHO_ID,
            tgt.ZCRM_ID = src.ZCRM_ID,
            tgt.IS_ACTIVE = src.IS_ACTIVE,
            tgt.CREATED_AT = src.CREATED_AT,
            tgt.UPDATED_AT = src.UPDATED_AT,
            tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (
            ID, CODE, LOCATION_NAME, LOCATION_TYPE, MINIMUM_1, MINIMUM_2, DELIVERY, FRONTEND, PRICING, IS_INTERNAL, IS_CANCELED, CANCEL_REASON, CANCEL_DATE, IS_TRANSFERRED, TRANSFER_DESTINATION, MODULE_TYPE, OPERATING_LOCATION, ZOHO_ID, ZCRM_ID, IS_ACTIVE, CREATED_AT, UPDATED_AT,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.CODE, src.LOCATION_NAME, src.LOCATION_TYPE, src.MINIMUM_1, src.MINIMUM_2, src.DELIVERY, src.FRONTEND, src.PRICING, src.IS_INTERNAL, src.IS_CANCELED, src.CANCEL_REASON, src.CANCEL_DATE, src.IS_TRANSFERRED, src.TRANSFER_DESTINATION, src.MODULE_TYPE, src.OPERATING_LOCATION, src.ZOHO_ID, src.ZCRM_ID, src.IS_ACTIVE, src.CREATED_AT, src.UPDATED_AT,
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_STELLAR_LOCATIONS: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_STELLAR_LOCATIONS: ' || SQLERRM);
        RAISE;
END SP_MERGE_STELLAR_LOCATIONS;
/
