
-- ============================================================================
-- Merge STG_MOLO_BOATS to DW_MOLO_BOATS
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_MERGE_MOLO_BOATS(
    p_inserted_count OUT NUMBER,
    p_updated_count OUT NUMBER
)
IS
BEGIN
    -- Insert new records that don't exist in DW
    INSERT INTO DW_MOLO_BOATS (
        ID, PHOTO, MAKE, MODEL, NAME, LOA, BEAM, DRAFT, AIR_DRAFT, 
        REGISTRATION_NUMBER, REGISTRATION_STATE, CREATION_TIME, BOAT_TYPE_ID, 
        MARINA_LOCATION_ID, POWER_NEED_ID, NOTES, RECORD_STATUS_ID, 
        ASPNET_USER_ID, MAST_LENGTH, WEIGHT, COLOR, HULL_ID, KEY_LOCATION_CODE, 
        YEAR, HASH_ID, MOLO_API_PARTNER_ID, POWER_NEED1_ID, 
        LAST_EDITED_DATE_TIME, LAST_EDITED_USER_ID, 
        LAST_EDITED_MOLO_API_PARTNER_ID, FILESTACK_ID, TONNAGE, 
        GALLON_CAPACITY, IS_ACTIVE, BOOKING_MERGING_DONE, DECAL_NUMBER, 
        MANUFACTURER, SERIAL_NUMBER, REGISTRATION_EXPIRATION,
        DW_LAST_INSERTED,
        DW_LAST_UPDATED
    )
    SELECT 
        src.ID, src.PHOTO, src.MAKE, src.MODEL, src.NAME, src.LOA, src.BEAM, 
        src.DRAFT, src.AIR_DRAFT, src.REGISTRATION_NUMBER, src.REGISTRATION_STATE, 
        src.CREATION_TIME, src.BOAT_TYPE_ID, src.MARINA_LOCATION_ID, 
        src.POWER_NEED_ID, src.NOTES, src.RECORD_STATUS_ID, src.ASPNET_USER_ID, 
        src.MAST_LENGTH, src.WEIGHT, src.COLOR, src.HULL_ID, src.KEY_LOCATION_CODE, 
        src.YEAR, src.HASH_ID, src.MOLO_API_PARTNER_ID, src.POWER_NEED1_ID, 
        src.LAST_EDITED_DATE_TIME, src.LAST_EDITED_USER_ID, 
        src.LAST_EDITED_MOLO_API_PARTNER_ID, src.FILESTACK_ID, src.TONNAGE, 
        src.GALLON_CAPACITY, src.IS_ACTIVE, src.BOOKING_MERGING_DONE, 
        src.DECAL_NUMBER, src.MANUFACTURER, src.SERIAL_NUMBER, 
        src.REGISTRATION_EXPIRATION,
        SYSTIMESTAMP,
        SYSTIMESTAMP
    FROM STG_MOLO_BOATS src
    WHERE NOT EXISTS (
        SELECT 1 FROM DW_MOLO_BOATS tgt WHERE tgt.ID = src.ID
    );
    
    p_inserted_count := SQL%ROWCOUNT;
    
    -- Update existing records where data has changed
    UPDATE DW_MOLO_BOATS tgt
    SET (
        tgt.PHOTO, tgt.MAKE, tgt.MODEL, tgt.NAME, tgt.LOA, tgt.BEAM, 
        tgt.DRAFT, tgt.AIR_DRAFT, tgt.REGISTRATION_NUMBER, tgt.REGISTRATION_STATE, 
        tgt.CREATION_TIME, tgt.BOAT_TYPE_ID, tgt.MARINA_LOCATION_ID, 
        tgt.POWER_NEED_ID, tgt.NOTES, tgt.RECORD_STATUS_ID, tgt.ASPNET_USER_ID, 
        tgt.MAST_LENGTH, tgt.WEIGHT, tgt.COLOR, tgt.HULL_ID, tgt.KEY_LOCATION_CODE, 
        tgt.YEAR, tgt.HASH_ID, tgt.MOLO_API_PARTNER_ID, tgt.POWER_NEED1_ID, 
        tgt.LAST_EDITED_DATE_TIME, tgt.LAST_EDITED_USER_ID, 
        tgt.LAST_EDITED_MOLO_API_PARTNER_ID, tgt.FILESTACK_ID, tgt.TONNAGE, 
        tgt.GALLON_CAPACITY, tgt.IS_ACTIVE, tgt.BOOKING_MERGING_DONE, 
        tgt.DECAL_NUMBER, tgt.MANUFACTURER, tgt.SERIAL_NUMBER, 
        tgt.REGISTRATION_EXPIRATION, tgt.DW_LAST_UPDATED
    ) = (
        SELECT 
            src.PHOTO, src.MAKE, src.MODEL, src.NAME, src.LOA, src.BEAM, 
            src.DRAFT, src.AIR_DRAFT, src.REGISTRATION_NUMBER, src.REGISTRATION_STATE, 
            src.CREATION_TIME, src.BOAT_TYPE_ID, src.MARINA_LOCATION_ID, 
            src.POWER_NEED_ID, src.NOTES, src.RECORD_STATUS_ID, src.ASPNET_USER_ID, 
            src.MAST_LENGTH, src.WEIGHT, src.COLOR, src.HULL_ID, src.KEY_LOCATION_CODE, 
            src.YEAR, src.HASH_ID, src.MOLO_API_PARTNER_ID, src.POWER_NEED1_ID, 
            src.LAST_EDITED_DATE_TIME, src.LAST_EDITED_USER_ID, 
            src.LAST_EDITED_MOLO_API_PARTNER_ID, src.FILESTACK_ID, src.TONNAGE, 
            src.GALLON_CAPACITY, src.IS_ACTIVE, src.BOOKING_MERGING_DONE, 
            src.DECAL_NUMBER, src.MANUFACTURER, src.SERIAL_NUMBER, 
            src.REGISTRATION_EXPIRATION, SYSTIMESTAMP
        FROM STG_MOLO_BOATS src
        WHERE src.ID = tgt.ID
    )
    WHERE EXISTS (
        SELECT 1 FROM STG_MOLO_BOATS src 
        WHERE src.ID = tgt.ID
        AND (
            -- Only update if data has actually changed
            NVL(tgt.PHOTO, '~') != NVL(src.PHOTO, '~')
            OR NVL(tgt.MAKE, '~') != NVL(src.MAKE, '~')
            OR NVL(tgt.MODEL, '~') != NVL(src.MODEL, '~')
            OR NVL(tgt.NAME, '~') != NVL(src.NAME, '~')
            OR NVL(tgt.LOA, '~') != NVL(src.LOA, '~')
            OR NVL(tgt.BEAM, '~') != NVL(src.BEAM, '~')
            OR NVL(tgt.DRAFT, '~') != NVL(src.DRAFT, '~')
            OR NVL(tgt.AIR_DRAFT, '~') != NVL(src.AIR_DRAFT, '~')
            OR NVL(tgt.REGISTRATION_NUMBER, '~') != NVL(src.REGISTRATION_NUMBER, '~')
            OR NVL(tgt.REGISTRATION_STATE, '~') != NVL(src.REGISTRATION_STATE, '~')
            OR NVL(tgt.CREATION_TIME, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD')) != NVL(src.CREATION_TIME, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'))
            OR NVL(tgt.BOAT_TYPE_ID, -1) != NVL(src.BOAT_TYPE_ID, -1)
            OR NVL(tgt.MARINA_LOCATION_ID, -1) != NVL(src.MARINA_LOCATION_ID, -1)
            OR NVL(tgt.POWER_NEED_ID, -1) != NVL(src.POWER_NEED_ID, -1)
            OR NVL(tgt.NOTES, '~') != NVL(src.NOTES, '~')
            OR NVL(tgt.RECORD_STATUS_ID, -1) != NVL(src.RECORD_STATUS_ID, -1)
            OR NVL(tgt.ASPNET_USER_ID, '~') != NVL(src.ASPNET_USER_ID, '~')
            OR NVL(tgt.MAST_LENGTH, '~') != NVL(src.MAST_LENGTH, '~')
            OR NVL(tgt.WEIGHT, -9999999) != NVL(src.WEIGHT, -9999999)
            OR NVL(tgt.COLOR, '~') != NVL(src.COLOR, '~')
            OR NVL(tgt.HULL_ID, '~') != NVL(src.HULL_ID, '~')
            OR NVL(tgt.KEY_LOCATION_CODE, '~') != NVL(src.KEY_LOCATION_CODE, '~')
            OR NVL(tgt.YEAR, -1) != NVL(src.YEAR, -1)
            OR NVL(tgt.HASH_ID, '~') != NVL(src.HASH_ID, '~')
            OR NVL(tgt.MOLO_API_PARTNER_ID, -1) != NVL(src.MOLO_API_PARTNER_ID, -1)
            OR NVL(tgt.POWER_NEED1_ID, -1) != NVL(src.POWER_NEED1_ID, -1)
            OR NVL(tgt.LAST_EDITED_DATE_TIME, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD')) != NVL(src.LAST_EDITED_DATE_TIME, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'))
            OR NVL(tgt.LAST_EDITED_USER_ID, '~') != NVL(src.LAST_EDITED_USER_ID, '~')
            OR NVL(tgt.LAST_EDITED_MOLO_API_PARTNER_ID, -1) != NVL(src.LAST_EDITED_MOLO_API_PARTNER_ID, -1)
            OR NVL(tgt.FILESTACK_ID, -1) != NVL(src.FILESTACK_ID, -1)
            OR NVL(tgt.TONNAGE, -9999999) != NVL(src.TONNAGE, -9999999)
            OR NVL(tgt.GALLON_CAPACITY, -1) != NVL(src.GALLON_CAPACITY, -1)
            OR NVL(tgt.IS_ACTIVE, -1) != NVL(src.IS_ACTIVE, -1)
            OR NVL(tgt.BOOKING_MERGING_DONE, -1) != NVL(src.BOOKING_MERGING_DONE, -1)
            OR NVL(tgt.DECAL_NUMBER, '~') != NVL(src.DECAL_NUMBER, '~')
            OR NVL(tgt.MANUFACTURER, '~') != NVL(src.MANUFACTURER, '~')
            OR NVL(tgt.SERIAL_NUMBER, '~') != NVL(src.SERIAL_NUMBER, '~')
            OR NVL(tgt.REGISTRATION_EXPIRATION, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD')) != NVL(src.REGISTRATION_EXPIRATION, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'))
        )
    );
    
    p_updated_count := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_BOATS: Inserted ' || p_inserted_count || ', Updated ' || p_updated_count || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_BOATS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_BOATS;
