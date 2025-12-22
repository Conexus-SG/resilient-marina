
  CREATE OR REPLACE EDITIONABLE PROCEDURE "API_USER"."SP_MERGE_MOLO_RECURRING_INVOICE_OPTIONS" AS
    v_merged_count NUMBER := 0;
    v_inserted_count NUMBER := 0;
    v_updated_count NUMBER := 0;
BEGIN
    MERGE INTO DW_MOLO_RECURRING_INVOICE_OPTIONS tgt
    USING STG_MOLO_RECURRING_INVOICE_OPTIONS src
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
    
    v_merged_count := SQL%ROWCOUNT;
    COMMIT;
    
    SELECT COUNT(*) INTO v_inserted_count
    FROM DW_MOLO_RECURRING_INVOICE_OPTIONS
    WHERE DW_LAST_INSERTED = DW_LAST_UPDATED;
    
    v_updated_count := v_merged_count - v_inserted_count;
    
    DBMS_OUTPUT.PUT_LINE('Recurring Invoice Options merge completed:');
    DBMS_OUTPUT.PUT_LINE('  Total merged: ' || v_merged_count);
    DBMS_OUTPUT.PUT_LINE('  Inserted: ' || v_inserted_count);
    DBMS_OUTPUT.PUT_LINE('  Updated: ' || v_updated_count);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in SP_MERGE_MOLO_RECURRING_INVOICE_OPTIONS: ' || SQLERRM);
        RAISE;
END SP_MERGE_MOLO_RECURRING_INVOICE_OPTIONS;
/