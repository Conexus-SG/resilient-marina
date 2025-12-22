
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_MOLO_BOATS" 
IS
    v_inserted NUMBER := 0;
    v_updated NUMBER := 0;
    v_timestamp TIMESTAMP := SYSTIMESTAMP;
BEGIN
    MERGE INTO DW_MOLO_BOATS tgt
    USING STG_MOLO_BOATS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.PHOTO = src.PHOTO,
            tgt.MAKE = src.MAKE,
            tgt.MODEL = src.MODEL,
            tgt.NAME = src.NAME,
            tgt.LOA = src.LOA,
            tgt.BEAM = src.BEAM,
            tgt.DRAFT = src.DRAFT,
            tgt.AIR_DRAFT = src.AIR_DRAFT,
            tgt.REGISTRATION_NUMBER = src.REGISTRATION_NUMBER,
            tgt.REGISTRATION_STATE = src.REGISTRATION_STATE,
            tgt.CREATION_TIME = src.CREATION_TIME,
            tgt.BOAT_TYPE_ID = src.BOAT_TYPE_ID,
            tgt.MARINA_LOCATION_ID = src.MARINA_LOCATION_ID,
            tgt.POWER_NEED_ID = src.POWER_NEED_ID,
            tgt.NOTES = src.NOTES,
            tgt.RECORD_STATUS_ID = src.RECORD_STATUS_ID,
            tgt.ASPNET_USER_ID = src.ASPNET_USER_ID,
            tgt.MAST_LENGTH = src.MAST_LENGTH,
            tgt.WEIGHT = src.WEIGHT,
            tgt.COLOR = src.COLOR,
            tgt.HULL_ID = src.HULL_ID,
            tgt.KEY_LOCATION_CODE = src.KEY_LOCATION_CODE,
            tgt.YEAR = src.YEAR,
            tgt.HASH_ID = src.HASH_ID,
            tgt.MOLO_API_PARTNER_ID = src.MOLO_API_PARTNER_ID,
            tgt.POWER_NEED1_ID = src.POWER_NEED1_ID,
            tgt.LAST_EDITED_DATE_TIME = src.LAST_EDITED_DATE_TIME,
            tgt.LAST_EDITED_USER_ID = src.LAST_EDITED_USER_ID,
            tgt.LAST_EDITED_MOLO_API_PARTNER_ID = src.LAST_EDITED_MOLO_API_PARTNER_ID,
            tgt.FILESTACK_ID = src.FILESTACK_ID,
            tgt.TONNAGE = src.TONNAGE,
            tgt.GALLON_CAPACITY = src.GALLON_CAPACITY,
            tgt.IS_ACTIVE = src.IS_ACTIVE,
            tgt.BOOKING_MERGING_DONE = src.BOOKING_MERGING_DONE,
            tgt.DECAL_NUMBER = src.DECAL_NUMBER,
            tgt.MANUFACTURER = src.MANUFACTURER,
            tgt.SERIAL_NUMBER = src.SERIAL_NUMBER,
            tgt.REGISTRATION_EXPIRATION = src.REGISTRATION_EXPIRATION,
            tgt.DW_LAST_UPDATED = v_timestamp
        WHERE
            NVL(tgt.PHOTO, '~NULL~') <> NVL(src.PHOTO, '~NULL~') OR
            NVL(tgt.MAKE, '~NULL~') <> NVL(src.MAKE, '~NULL~') OR
            NVL(tgt.MODEL, '~NULL~') <> NVL(src.MODEL, '~NULL~') OR
            NVL(tgt.NAME, '~NULL~') <> NVL(src.NAME, '~NULL~') OR
            NVL(tgt.LOA, '~NULL~') <> NVL(src.LOA, '~NULL~') OR
            NVL(tgt.BEAM, '~NULL~') <> NVL(src.BEAM, '~NULL~') OR
            NVL(tgt.DRAFT, '~NULL~') <> NVL(src.DRAFT, '~NULL~') OR
            NVL(tgt.AIR_DRAFT, '~NULL~') <> NVL(src.AIR_DRAFT, '~NULL~') OR
            NVL(tgt.REGISTRATION_NUMBER, '~NULL~') <> NVL(src.REGISTRATION_NUMBER, '~NULL~') OR
            NVL(tgt.REGISTRATION_STATE, '~NULL~') <> NVL(src.REGISTRATION_STATE, '~NULL~') OR
            NVL(tgt.CREATION_TIME, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) <> NVL(src.CREATION_TIME, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) OR
            NVL(tgt.BOAT_TYPE_ID, -999) <> NVL(src.BOAT_TYPE_ID, -999) OR
            NVL(tgt.MARINA_LOCATION_ID, -999) <> NVL(src.MARINA_LOCATION_ID, -999) OR
            NVL(tgt.POWER_NEED_ID, -999) <> NVL(src.POWER_NEED_ID, -999) OR
            NVL(tgt.NOTES, '~NULL~') <> NVL(src.NOTES, '~NULL~') OR
            NVL(tgt.RECORD_STATUS_ID, -999) <> NVL(src.RECORD_STATUS_ID, -999) OR
            NVL(tgt.ASPNET_USER_ID, '~NULL~') <> NVL(src.ASPNET_USER_ID, '~NULL~') OR
            NVL(tgt.MAST_LENGTH, '~NULL~') <> NVL(src.MAST_LENGTH, '~NULL~') OR
            NVL(tgt.WEIGHT, -999.999) <> NVL(src.WEIGHT, -999.999) OR
            NVL(tgt.COLOR, '~NULL~') <> NVL(src.COLOR, '~NULL~') OR
            NVL(tgt.HULL_ID, '~NULL~') <> NVL(src.HULL_ID, '~NULL~') OR
            NVL(tgt.KEY_LOCATION_CODE, '~NULL~') <> NVL(src.KEY_LOCATION_CODE, '~NULL~') OR
            NVL(tgt.YEAR, -999) <> NVL(src.YEAR, -999) OR
            NVL(tgt.HASH_ID, '~NULL~') <> NVL(src.HASH_ID, '~NULL~') OR
            NVL(tgt.MOLO_API_PARTNER_ID, -999) <> NVL(src.MOLO_API_PARTNER_ID, -999) OR
            NVL(tgt.POWER_NEED1_ID, -999) <> NVL(src.POWER_NEED1_ID, -999) OR
            NVL(tgt.LAST_EDITED_DATE_TIME, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) <> NVL(src.LAST_EDITED_DATE_TIME, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) OR
            NVL(tgt.LAST_EDITED_USER_ID, '~NULL~') <> NVL(src.LAST_EDITED_USER_ID, '~NULL~') OR
            NVL(tgt.LAST_EDITED_MOLO_API_PARTNER_ID, -999) <> NVL(src.LAST_EDITED_MOLO_API_PARTNER_ID, -999) OR
            NVL(tgt.FILESTACK_ID, -999) <> NVL(src.FILESTACK_ID, -999) OR
            NVL(tgt.TONNAGE, -999.999) <> NVL(src.TONNAGE, -999.999) OR
            NVL(tgt.GALLON_CAPACITY, -999.999) <> NVL(src.GALLON_CAPACITY, -999.999) OR
            NVL(tgt.IS_ACTIVE, -999) <> NVL(src.IS_ACTIVE, -999) OR
            NVL(tgt.BOOKING_MERGING_DONE, -999) <> NVL(src.BOOKING_MERGING_DONE, -999) OR
            NVL(tgt.DECAL_NUMBER, '~NULL~') <> NVL(src.DECAL_NUMBER, '~NULL~') OR
            NVL(tgt.MANUFACTURER, '~NULL~') <> NVL(src.MANUFACTURER, '~NULL~') OR
            NVL(tgt.SERIAL_NUMBER, '~NULL~') <> NVL(src.SERIAL_NUMBER, '~NULL~') OR
            NVL(tgt.REGISTRATION_EXPIRATION, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) <> NVL(src.REGISTRATION_EXPIRATION, TO_TIMESTAMP('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
    WHEN NOT MATCHED THEN
        INSERT (
            ID, PHOTO, MAKE, MODEL, NAME, LOA, BEAM, DRAFT, AIR_DRAFT, REGISTRATION_NUMBER, REGISTRATION_STATE, CREATION_TIME, BOAT_TYPE_ID, MARINA_LOCATION_ID, POWER_NEED_ID, NOTES, RECORD_STATUS_ID, ASPNET_USER_ID, MAST_LENGTH, WEIGHT, COLOR, HULL_ID, KEY_LOCATION_CODE, YEAR, HASH_ID, MOLO_API_PARTNER_ID, POWER_NEED1_ID, LAST_EDITED_DATE_TIME, LAST_EDITED_USER_ID, LAST_EDITED_MOLO_API_PARTNER_ID, FILESTACK_ID, TONNAGE, GALLON_CAPACITY, IS_ACTIVE, BOOKING_MERGING_DONE, DECAL_NUMBER, MANUFACTURER, SERIAL_NUMBER, REGISTRATION_EXPIRATION,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.PHOTO, src.MAKE, src.MODEL, src.NAME, src.LOA, src.BEAM, src.DRAFT, src.AIR_DRAFT, src.REGISTRATION_NUMBER, src.REGISTRATION_STATE, src.CREATION_TIME, src.BOAT_TYPE_ID, src.MARINA_LOCATION_ID, src.POWER_NEED_ID, src.NOTES, src.RECORD_STATUS_ID, src.ASPNET_USER_ID, src.MAST_LENGTH, src.WEIGHT, src.COLOR, src.HULL_ID, src.KEY_LOCATION_CODE, src.YEAR, src.HASH_ID, src.MOLO_API_PARTNER_ID, src.POWER_NEED1_ID, src.LAST_EDITED_DATE_TIME, src.LAST_EDITED_USER_ID, src.LAST_EDITED_MOLO_API_PARTNER_ID, src.FILESTACK_ID, src.TONNAGE, src.GALLON_CAPACITY, src.IS_ACTIVE, src.BOOKING_MERGING_DONE, src.DECAL_NUMBER, src.MANUFACTURER, src.SERIAL_NUMBER, src.REGISTRATION_EXPIRATION,
            v_timestamp,
            v_timestamp
        );
    
    -- Count inserted records
    SELECT COUNT(*) INTO v_inserted
    FROM DW_MOLO_BOATS
    WHERE DW_LAST_INSERTED = v_timestamp;
    
    -- Count updated records
    SELECT COUNT(*) INTO v_updated
    FROM DW_MOLO_BOATS
    WHERE DW_LAST_UPDATED = v_timestamp
      AND DW_LAST_INSERTED < v_timestamp;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_BOATS: ' || v_inserted || ' inserted, ' || v_updated || ' updated');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_BOATS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_BOATS;
/