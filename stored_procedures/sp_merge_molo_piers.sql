
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_MOLO_PIERS" 
IS
    v_inserted NUMBER := 0;
    v_updated NUMBER := 0;
    v_timestamp TIMESTAMP := SYSTIMESTAMP;
BEGIN
    v_timestamp := SYSTIMESTAMP;
    
    MERGE INTO DW_MOLO_PIERS tgt
    USING STG_MOLO_PIERS src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.NAME = src.NAME,
            tgt.MARINA_LOCATION_ID = src.MARINA_LOCATION_ID,
            tgt.DW_LAST_UPDATED = v_timestamp
        WHERE (
            NVL(tgt.ID, -999) <> NVL(src.ID, -999) OR
            NVL(tgt.NAME, '~NULL~') <> NVL(src.NAME, '~NULL~') OR
            NVL(tgt.MARINA_LOCATION_ID, -999) <> NVL(src.MARINA_LOCATION_ID, -999)
        )
    WHEN NOT MATCHED THEN
        INSERT (
            ID, NAME, MARINA_LOCATION_ID,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID, src.NAME, src.MARINA_LOCATION_ID,
            v_timestamp,
            v_timestamp
        );
    
    -- Count updated records
    SELECT COUNT(*) INTO v_updated
    FROM DW_MOLO_PIERS
    WHERE DW_LAST_UPDATED = v_timestamp
    AND DW_LAST_UPDATED > DW_LAST_INSERTED;
    
    -- Count inserted records
    SELECT COUNT(*) INTO v_inserted
    FROM DW_MOLO_PIERS
    WHERE DW_LAST_INSERTED = v_timestamp;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_PIERS: ' || v_inserted || ' inserted, ' || v_updated || ' updated');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_PIERS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_PIERS;
/