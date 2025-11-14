# MERGE Stored Procedure Optimization

## Overview
All MERGE stored procedures have been optimized to prevent unnecessary UPDATE operations when data hasn't changed.

## What Was Changed

### Before
```sql
WHEN MATCHED THEN
    UPDATE SET
        tgt.COLUMN1 = src.COLUMN1,
        tgt.COLUMN2 = src.COLUMN2,
        ...
        tgt.DW_LAST_UPDATED = SYSTIMESTAMP
```

### After
```sql
WHEN MATCHED THEN
    UPDATE SET
        tgt.COLUMN1 = src.COLUMN1,
        tgt.COLUMN2 = src.COLUMN2,
        ...
        tgt.DW_LAST_UPDATED = SYSTIMESTAMP
    WHERE 
        -- Only update if data has actually changed
        NVL(tgt.COLUMN1, '~') != NVL(src.COLUMN1, '~')
        OR NVL(tgt.COLUMN2, -1) != NVL(src.COLUMN2, -1)
        OR ...
```

## Benefits

1. **Performance**: Prevents unnecessary write operations when source and target data are identical
2. **Accurate Timestamps**: `DW_LAST_UPDATED` only changes when data actually changes
3. **Reduced I/O**: Fewer disk writes and transaction log entries
4. **Better Auditing**: Timestamp changes now reliably indicate real data modifications

## How It Works

The WHERE clause compares each column between source (STG_*) and target (DW_*) tables:

- **String columns**: Uses `NVL(column, '~')` to handle NULLs
- **Integer/ID columns**: Uses `NVL(column, -1)` to handle NULLs
- **Decimal/Float columns**: Uses `NVL(column, -999999)` to handle NULLs
- **Timestamp columns**: Uses `NVL(column, TO_TIMESTAMP('1900-01-01', 'YYYY-MM-DD'))` to handle NULLs

The UPDATE only executes if **any** column value differs between source and target.

## Updated Procedures

Total: **66 out of 77** stored procedures updated

### MOLO Procedures (38 updated)
- sp_merge_molo_account_status
- sp_merge_molo_accounts
- sp_merge_molo_address_types
- sp_merge_molo_boat_types
- sp_merge_molo_boats
- sp_merge_molo_cities
- sp_merge_molo_companies
- sp_merge_molo_contact_auto_charge
- sp_merge_molo_contact_types
- sp_merge_molo_contacts
- sp_merge_molo_countries
- sp_merge_molo_currencies
- sp_merge_molo_insurance_status
- sp_merge_molo_invoice_items
- sp_merge_molo_invoice_status
- sp_merge_molo_invoice_types
- sp_merge_molo_invoices
- sp_merge_molo_item_charge_methods
- sp_merge_molo_item_masters
- sp_merge_molo_marina_locations
- sp_merge_molo_payment_methods
- sp_merge_molo_phone_types
- sp_merge_molo_piers
- sp_merge_molo_power_needs
- sp_merge_molo_record_status
- sp_merge_molo_reservation_status
- sp_merge_molo_reservation_types
- sp_merge_molo_reservations
- sp_merge_molo_seasonal_charge_methods
- sp_merge_molo_seasonal_prices
- sp_merge_molo_slip_types
- sp_merge_molo_slips
- sp_merge_molo_statements_preference
- sp_merge_molo_transaction_methods
- sp_merge_molo_transaction_types
- sp_merge_molo_transactions
- sp_merge_molo_transient_charge_methods
- sp_merge_molo_transient_prices (manually updated first)

### Stellar Procedures (28 updated)
- sp_merge_stellar_accessories
- sp_merge_stellar_accessory_options
- sp_merge_stellar_accessory_tiers
- sp_merge_stellar_amenities
- sp_merge_stellar_blacklists
- sp_merge_stellar_booking_accessories
- sp_merge_stellar_booking_boats
- sp_merge_stellar_booking_payments
- sp_merge_stellar_bookings
- sp_merge_stellar_categories
- sp_merge_stellar_closed_dates
- sp_merge_stellar_club_tiers
- sp_merge_stellar_coupons
- sp_merge_stellar_customer_boats
- sp_merge_stellar_customers
- sp_merge_stellar_fuel_sales
- sp_merge_stellar_holidays
- sp_merge_stellar_locations
- sp_merge_stellar_pos_items
- sp_merge_stellar_pos_sales
- sp_merge_stellar_season_dates
- sp_merge_stellar_seasons
- sp_merge_stellar_style_boats
- sp_merge_stellar_style_groups
- sp_merge_stellar_style_hourly_prices
- sp_merge_stellar_style_prices
- sp_merge_stellar_style_times
- sp_merge_stellar_styles
- sp_merge_stellar_waitlists

### Skipped (11 procedures)
These procedures either:
- Already had WHERE clauses
- Have simple structures that didn't match the pattern
- Are lookup tables with only ID and NAME columns

## Testing

After deploying the updated procedures:

1. Run the data load process normally
2. Run it again immediately with the same data
3. Check DW_LAST_UPDATED timestamps - they should NOT change on the second run
4. Verify update counts in the log output

Example:
```sql
-- First run: Will update all records
CALL SP_MERGE_MOLO_ITEM_MASTERS();
-- Output: "Merged 706 records"

-- Second run (same data): Should update 0 records
CALL SP_MERGE_MOLO_ITEM_MASTERS();
-- Output: "Merged 0 records" (if data unchanged)
```

## Deployment

To deploy the updated procedures:

```bash
# Option 1: Run the deployment script
python3 deploy_procedures_simple.py

# Option 2: Execute individual procedure files
sqlplus user/pass@db @stored_procedures/sp_merge_molo_transient_prices.sql
```

## Maintenance

The script `update_merge_procedures_with_where.py` can be run again in the future if:
- New merge procedures are added
- Procedures are regenerated and lose the WHERE clause
- The WHERE clause logic needs to be updated

```bash
python3 update_merge_procedures_with_where.py
```

## Notes

- The WHERE clause uses NVL to handle NULL comparisons properly
- The chosen NULL substitutes ('~', -1, -999999, '1900-01-01') are unlikely to appear in real data
- If a column might legitimately contain these substitute values, adjust the script accordingly
- This optimization is especially valuable for tables with frequent but mostly unchanged data
