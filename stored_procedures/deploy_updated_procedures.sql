-- ============================================================================
-- Deploy Updated Merge Procedures with INSERT/UPDATE Counts
-- ============================================================================
-- This script deploys the 5 key merge procedures that now return
-- separate insert and update counts via OUT parameters.
--
-- Run this script to update your database before testing.
-- ============================================================================

PROMPT Deploying SP_MERGE_MOLO_BOATS...
@@sp_merge_molo_boats.sql

PROMPT Deploying SP_MERGE_MOLO_INVOICES...
@@sp_merge_molo_invoices.sql

PROMPT Deploying SP_MERGE_MOLO_ITEM_MASTERS...
@@sp_merge_molo_item_masters.sql

PROMPT Deploying SP_MERGE_MOLO_RESERVATIONS...
@@sp_merge_molo_reservations.sql

PROMPT Deploying SP_MERGE_MOLO_CONTACTS...
@@sp_merge_molo_contacts.sql

PROMPT
PROMPT ============================================================================
PROMPT Deployment Complete!
PROMPT ============================================================================
PROMPT
PROMPT The following procedures now return insert/update counts:
PROMPT   - SP_MERGE_MOLO_BOATS(p_inserted_count OUT, p_updated_count OUT)
PROMPT   - SP_MERGE_MOLO_INVOICES(p_inserted_count OUT, p_updated_count OUT)
PROMPT   - SP_MERGE_MOLO_ITEM_MASTERS(p_inserted_count OUT, p_updated_count OUT)
PROMPT   - SP_MERGE_MOLO_RESERVATIONS(p_inserted_count OUT, p_updated_count OUT)
PROMPT   - SP_MERGE_MOLO_CONTACTS(p_inserted_count OUT, p_updated_count OUT)
PROMPT
PROMPT Next step: Run test_merge_procedures.py to verify the changes
PROMPT ============================================================================
