
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_MOLO_EQUIPMENT_TYPES" AS
    v_merge_count NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_EQUIPMENT_TYPES tgt
    USING STG_MOLO_EQUIPMENT_TYPES src
    ON (tgt.ID = src.ID)
    WHEN MATCHED THEN
        UPDATE SET
            tgt.NAME = src.NAME,
            tgt.DW_LAST_UPDATED = CURRENT_TIMESTAMP
        WHERE
            NVL(tgt.NAME, '~') != NVL(src.NAME, '~')
    WHEN NOT MATCHED THEN
        INSERT (
            ID,
            NAME,
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            src.ID,
            src.NAME,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    
    v_merge_count := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('DW_MOLO_EQUIPMENT_TYPES: Merged ' || v_merge_count || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_EQUIPMENT_TYPES: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_EQUIPMENT_TYPES;
/