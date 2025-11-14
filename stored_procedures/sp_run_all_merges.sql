
-- ============================================================================
-- Master Procedure: Execute All MOLO and Stellar Merges
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_RUN_ALL_MOLO_STELLAR_MERGES(
    p_stats OUT SYS_REFCURSOR
)
IS
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration NUMBER;
    
    -- Tier 1: Variables to capture individual procedure OUT parameters
    v_boats_inserted NUMBER := 0;
    v_boats_updated NUMBER := 0;
    v_invoices_inserted NUMBER := 0;
    v_invoices_updated NUMBER := 0;
    v_item_masters_inserted NUMBER := 0;
    v_item_masters_updated NUMBER := 0;
    v_reservations_inserted NUMBER := 0;
    v_reservations_updated NUMBER := 0;
    v_contacts_inserted NUMBER := 0;
    v_contacts_updated NUMBER := 0;
    
    -- Tier 2: Additional high-value procedures
    v_accounts_inserted NUMBER := 0;
    v_accounts_updated NUMBER := 0;
    v_invoice_items_inserted NUMBER := 0;
    v_invoice_items_updated NUMBER := 0;
    v_transactions_inserted NUMBER := 0;
    v_transactions_updated NUMBER := 0;
    v_slips_inserted NUMBER := 0;
    v_slips_updated NUMBER := 0;
    v_stellar_bookings_inserted NUMBER := 0;
    v_stellar_bookings_updated NUMBER := 0;
    v_stellar_customers_inserted NUMBER := 0;
    v_stellar_customers_updated NUMBER := 0;
    v_stellar_booking_payments_inserted NUMBER := 0;
    v_stellar_booking_payments_updated NUMBER := 0;
    
    TYPE stats_rec IS RECORD (
        table_name VARCHAR2(100),
        inserted_count NUMBER,
        updated_count NUMBER
    );
    TYPE stats_table IS TABLE OF stats_rec INDEX BY PLS_INTEGER;
    v_stats stats_table;
    v_idx PLS_INTEGER := 0;
BEGIN
    v_start_time := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('STARTING MERGE: STG_* -> DW_* Tables');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- MOLO Merges
    DBMS_OUTPUT.PUT_LINE('--- Processing MOLO Tables ---');
    SP_MERGE_MOLO_ACCOUNT_STATUS;
    
    -- Accounts with stats tracking
    SP_MERGE_MOLO_ACCOUNTS(v_accounts_inserted, v_accounts_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_ACCOUNTS';
    v_stats(v_idx).inserted_count := v_accounts_inserted;
    v_stats(v_idx).updated_count := v_accounts_updated;
    
    SP_MERGE_MOLO_ADDRESS_TYPES;
    
    -- Boats with stats tracking
    SP_MERGE_MOLO_BOATS(v_boats_inserted, v_boats_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_BOATS';
    v_stats(v_idx).inserted_count := v_boats_inserted;
    v_stats(v_idx).updated_count := v_boats_updated;
    
    SP_MERGE_MOLO_BOAT_TYPES;
    SP_MERGE_MOLO_CITIES;
    SP_MERGE_MOLO_COMPANIES;
    SP_MERGE_MOLO_CONTACT_AUTO_CHARGE;
    
    -- Contacts with stats tracking
    SP_MERGE_MOLO_CONTACTS(v_contacts_inserted, v_contacts_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_CONTACTS';
    v_stats(v_idx).inserted_count := v_contacts_inserted;
    v_stats(v_idx).updated_count := v_contacts_updated;
    
    SP_MERGE_MOLO_CONTACT_TYPES;
    SP_MERGE_MOLO_COUNTRIES;
    SP_MERGE_MOLO_CURRENCIES;
    SP_MERGE_MOLO_DUE_DATE_SETTINGS;
    SP_MERGE_MOLO_EQUIPMENT_FUEL_TYPES;
    SP_MERGE_MOLO_EQUIPMENT_TYPES;
    SP_MERGE_MOLO_INSTALLMENTS_PAYMENT_METHODS;
    SP_MERGE_MOLO_INSURANCE_STATUS;
    
    -- Invoice Items with stats tracking
    SP_MERGE_MOLO_INVOICE_ITEMS(v_invoice_items_inserted, v_invoice_items_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_INVOICE_ITEMS';
    v_stats(v_idx).inserted_count := v_invoice_items_inserted;
    v_stats(v_idx).updated_count := v_invoice_items_updated;
    
    -- Invoices with stats tracking
    SP_MERGE_MOLO_INVOICES(v_invoices_inserted, v_invoices_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_INVOICES';
    v_stats(v_idx).inserted_count := v_invoices_inserted;
    v_stats(v_idx).updated_count := v_invoices_updated;
    
    SP_MERGE_MOLO_INVOICE_STATUS;
    SP_MERGE_MOLO_INVOICE_TYPES;
    SP_MERGE_MOLO_INVOICE_ITEM_TYPES;
    SP_MERGE_MOLO_ITEM_CHARGE_METHODS;
    
    -- Item Masters with stats tracking
    SP_MERGE_MOLO_ITEM_MASTERS(v_item_masters_inserted, v_item_masters_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_ITEM_MASTERS';
    v_stats(v_idx).inserted_count := v_item_masters_inserted;
    v_stats(v_idx).updated_count := v_item_masters_updated;
    
    SP_MERGE_MOLO_MARINA_LOCATIONS;
    SP_MERGE_MOLO_PAYMENT_METHODS;
    SP_MERGE_MOLO_PAYMENTS_PROVIDER;
    SP_MERGE_MOLO_PHONE_TYPES;
    SP_MERGE_MOLO_PIERS;
    SP_MERGE_MOLO_POWER_NEEDS;
    SP_MERGE_MOLO_RECORD_STATUS;
    SP_MERGE_MOLO_RECURRING_INVOICE_OPTIONS;
    
    -- Reservations with stats tracking
    SP_MERGE_MOLO_RESERVATIONS(v_reservations_inserted, v_reservations_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_RESERVATIONS';
    v_stats(v_idx).inserted_count := v_reservations_inserted;
    v_stats(v_idx).updated_count := v_reservations_updated;
    
    SP_MERGE_MOLO_RESERVATION_STATUS;
    SP_MERGE_MOLO_RESERVATION_TYPES;
    SP_MERGE_MOLO_SEASONAL_CHARGE_METHODS;
    SP_MERGE_MOLO_SEASONAL_INVOICING_METHODS;
    SP_MERGE_MOLO_SEASONAL_PRICES;
    
    -- Slips with stats tracking
    SP_MERGE_MOLO_SLIPS(v_slips_inserted, v_slips_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_SLIPS';
    v_stats(v_idx).inserted_count := v_slips_inserted;
    v_stats(v_idx).updated_count := v_slips_updated;
    
    SP_MERGE_MOLO_SLIP_TYPES;
    SP_MERGE_MOLO_STATEMENTS_PREFERENCE;
    SP_MERGE_MOLO_TRANSACTION_METHODS;
    
    -- Transactions with stats tracking
    SP_MERGE_MOLO_TRANSACTIONS(v_transactions_inserted, v_transactions_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_MOLO_TRANSACTIONS';
    v_stats(v_idx).inserted_count := v_transactions_inserted;
    v_stats(v_idx).updated_count := v_transactions_updated;
    
    SP_MERGE_MOLO_TRANSACTION_TYPES;
    SP_MERGE_MOLO_TRANSIENT_CHARGE_METHODS;
    SP_MERGE_MOLO_TRANSIENT_INVOICING_METHODS;
    SP_MERGE_MOLO_TRANSIENT_PRICES;
    SP_MERGE_MOLO_VESSEL_ENGINE_CLASS;
    
    -- Stellar Merges
    DBMS_OUTPUT.PUT_LINE('--- Processing Stellar Tables ---');
    
    -- Stellar Customers with stats tracking
    SP_MERGE_STELLAR_CUSTOMERS(v_stellar_customers_inserted, v_stellar_customers_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_STELLAR_CUSTOMERS';
    v_stats(v_idx).inserted_count := v_stellar_customers_inserted;
    v_stats(v_idx).updated_count := v_stellar_customers_updated;
    
    SP_MERGE_STELLAR_LOCATIONS;
    SP_MERGE_STELLAR_SEASONS;
    SP_MERGE_STELLAR_ACCESSORIES;
    SP_MERGE_STELLAR_ACCESSORY_OPTIONS;
    SP_MERGE_STELLAR_ACCESSORY_TIERS;
    SP_MERGE_STELLAR_AMENITIES;
    SP_MERGE_STELLAR_CATEGORIES;
    SP_MERGE_STELLAR_HOLIDAYS;
    
    -- Stellar Bookings with stats tracking
    SP_MERGE_STELLAR_BOOKINGS(v_stellar_bookings_inserted, v_stellar_bookings_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_STELLAR_BOOKINGS';
    v_stats(v_idx).inserted_count := v_stellar_bookings_inserted;
    v_stats(v_idx).updated_count := v_stellar_bookings_updated;
    
    SP_MERGE_STELLAR_BOOKING_BOATS;
    
    -- Stellar Booking Payments with stats tracking
    SP_MERGE_STELLAR_BOOKING_PAYMENTS(v_stellar_booking_payments_inserted, v_stellar_booking_payments_updated);
    v_idx := v_idx + 1;
    v_stats(v_idx).table_name := 'DW_STELLAR_BOOKING_PAYMENTS';
    v_stats(v_idx).inserted_count := v_stellar_booking_payments_inserted;
    v_stats(v_idx).updated_count := v_stellar_booking_payments_updated;
    
    SP_MERGE_STELLAR_BOOKING_ACCESSORIES;
    SP_MERGE_STELLAR_STYLE_GROUPS;
    SP_MERGE_STELLAR_STYLES;
    SP_MERGE_STELLAR_STYLE_BOATS;
    SP_MERGE_STELLAR_CUSTOMER_BOATS;
    SP_MERGE_STELLAR_SEASON_DATES;
    SP_MERGE_STELLAR_STYLE_HOURLY_PRICES;
    SP_MERGE_STELLAR_STYLE_TIMES;
    SP_MERGE_STELLAR_STYLE_PRICES;
    SP_MERGE_STELLAR_CLUB_TIERS;
    SP_MERGE_STELLAR_COUPONS;
    SP_MERGE_STELLAR_POS_ITEMS;
    SP_MERGE_STELLAR_POS_SALES;
    SP_MERGE_STELLAR_FUEL_SALES;
    SP_MERGE_STELLAR_WAITLISTS;
    SP_MERGE_STELLAR_CLOSED_DATES;
    SP_MERGE_STELLAR_BLACKLISTS;
    
    v_end_time := SYSTIMESTAMP;
    v_duration := EXTRACT(SECOND FROM (v_end_time - v_start_time));
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('ALL MERGES COMPLETED');
    DBMS_OUTPUT.PUT_LINE('Duration: ' || ROUND(v_duration, 2) || ' seconds');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- Return merge statistics via cursor from PL/SQL collection
    OPEN p_stats FOR
        -- Tier 1 procedures
        SELECT 'DW_MOLO_BOATS' AS table_name, v_boats_inserted AS inserted_count, v_boats_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_CONTACTS' AS table_name, v_contacts_inserted AS inserted_count, v_contacts_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_INVOICES' AS table_name, v_invoices_inserted AS inserted_count, v_invoices_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_ITEM_MASTERS' AS table_name, v_item_masters_inserted AS inserted_count, v_item_masters_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_RESERVATIONS' AS table_name, v_reservations_inserted AS inserted_count, v_reservations_updated AS updated_count FROM DUAL
        UNION ALL
        -- Tier 2 procedures
        SELECT 'DW_MOLO_ACCOUNTS' AS table_name, v_accounts_inserted AS inserted_count, v_accounts_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_INVOICE_ITEMS' AS table_name, v_invoice_items_inserted AS inserted_count, v_invoice_items_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_TRANSACTIONS' AS table_name, v_transactions_inserted AS inserted_count, v_transactions_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_MOLO_SLIPS' AS table_name, v_slips_inserted AS inserted_count, v_slips_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_STELLAR_BOOKINGS' AS table_name, v_stellar_bookings_inserted AS inserted_count, v_stellar_bookings_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_STELLAR_CUSTOMERS' AS table_name, v_stellar_customers_inserted AS inserted_count, v_stellar_customers_updated AS updated_count FROM DUAL
        UNION ALL
        SELECT 'DW_STELLAR_BOOKING_PAYMENTS' AS table_name, v_stellar_booking_payments_inserted AS inserted_count, v_stellar_booking_payments_updated AS updated_count FROM DUAL
        ORDER BY 1;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END SP_RUN_ALL_MOLO_STELLAR_MERGES;
