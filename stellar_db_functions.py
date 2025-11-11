"""
Stellar Business Database Functions Module

This module contains Oracle database connector and all merge functions 
for Stellar Business marina system tables. Follows the same pattern as
molo_db_functions.py for consistency and maintainability.

Contains 29 merge functions for Stellar Business data management including:
- Core entities: locations, customers, bookings
- Booking details: booking_boats, booking_payments, booking_accessories
- Style/Boat data: style_groups, styles, style_boats, customer_boats
- Pricing: seasons, season_dates, style_hourly_prices, style_times, style_prices
- Accessories: accessories, accessory_options, accessory_tiers
- Sales: pos_items, pos_sales, fuel_sales
- Membership: club_tiers, coupons
- Operations: waitlists, closed_dates, holidays, blacklists
- Reference data: categories, amenities

Dependencies:
    - oracledb: Oracle database connectivity
    - logging: For structured logging
    - os: For environment variable access
"""

import os
import logging
import oracledb

# Set up logging
logger = logging.getLogger(__name__)


class OracleConnector:
    """
    Oracle Database connector with support for Oracle Autonomous Database.
    
    This class handles database connections using Oracle Instant Client and
    provides methods for MERGE operations on Stellar Business tables.
    
    Attributes:
        connection: Oracle database connection object
        cursor: Database cursor for executing SQL statements
    """
    
    def __init__(self, user, password, dsn):
        """
        Initialize Oracle database connection.
        
        Args:
            user (str): Database username
            password (str): Database password  
            dsn (str): Database data source name (connection string)
        """
        # Configure Oracle wallet for Autonomous Database
        self._setup_oracle_wallet()
        
        # Initialize Oracle Instant Client
        self._initialize_oracle_client()
        
        # Establish database connection
        logger.info("Attempting to connect to Oracle database...")
        logger.info(f"   User: {user}")
        logger.info(f"   DSN: {dsn}")
        
        self.connection = oracledb.connect(
            user=user,
            password=password,
            dsn=dsn
        )
        logger.info("✅ Oracle database connection successful!")
        self.cursor = self.connection.cursor()
    
    def _setup_oracle_wallet(self):
        """Set up Oracle wallet environment for Autonomous Database."""
        # Get absolute path to wallet directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        wallet_dir = os.path.join(script_dir, "wallet_demo")
        
        # Convert to absolute path and verify it exists
        wallet_dir = os.path.abspath(wallet_dir)
        
        if os.path.exists(wallet_dir):
            os.environ['TNS_ADMIN'] = wallet_dir
            logger.info(f"✅ TNS_ADMIN set to: {wallet_dir}")
            
            # Verify wallet files exist
            required_files = ['cwallet.sso', 'tnsnames.ora', 'sqlnet.ora']
            missing_files = [f for f in required_files if not os.path.exists(os.path.join(wallet_dir, f))]
            
            if missing_files:
                logger.warning(f"⚠️  Missing wallet files: {missing_files}")
            else:
                logger.info("✅ All required wallet files found")
        else:
            logger.error(f"❌ Wallet directory not found: {wallet_dir}")
            raise FileNotFoundError(f"Wallet directory not found: {wallet_dir}")
    
    def _initialize_oracle_client(self):
        """Initialize Oracle Instant Client with common installation paths."""
        try:
            # Try different common paths for Oracle Instant Client
            client_paths = [
                "/opt/oracle/instantclient",           # Linux/Docker
                r"C:\oracle\instantclient_21_3",       # Windows
                r"C:\oracle\instantclient"             # Windows alternative
            ]
            
            for path in client_paths:
                if os.path.exists(path):
                    oracledb.init_oracle_client(lib_dir=path)
                    logger.info(f"Oracle Instant Client initialized from: {path}")
                    break
            else:
                logger.warning(
                    "Oracle Instant Client path not found, trying without lib_dir"
                )
                oracledb.init_oracle_client()
                
        except Exception as e:
            logger.warning(f"Oracle client already initialized or error: {e}")
    
    def truncate_staging_tables(self):
        """
        Truncate all Stellar staging tables before data load.
        
        This method clears all staging tables in preparation for fresh data.
        Following the rosnet-api-integration pattern: truncate, insert to 
        staging, then call stored procedures to merge into data warehouse.
        """
        staging_tables = [
            'STG_STELLAR_LOCATIONS', 'STG_STELLAR_CUSTOMERS', 
            'STG_STELLAR_BOOKINGS', 'STG_STELLAR_BOOKING_BOATS',
            'STG_STELLAR_BOOKING_PAYMENTS', 'STG_STELLAR_STYLE_GROUPS',
            'STG_STELLAR_STYLES', 'STG_STELLAR_STYLE_BOATS',
            'STG_STELLAR_CUSTOMER_BOATS', 'STG_STELLAR_SEASONS',
            'STG_STELLAR_SEASON_DATES', 
            'STG_STELLAR_STYLE_HOURLY_PRICES',
            'STG_STELLAR_STYLE_TIMES', 'STG_STELLAR_STYLE_PRICES',
            'STG_STELLAR_ACCESSORIES', 'STG_STELLAR_ACCESSORY_OPTIONS',
            'STG_STELLAR_ACCESSORY_TIERS', 
            'STG_STELLAR_BOOKING_ACCESSORIES',
            'STG_STELLAR_CLUB_TIERS', 'STG_STELLAR_COUPONS',
            'STG_STELLAR_POS_ITEMS', 'STG_STELLAR_POS_SALES',
            'STG_STELLAR_FUEL_SALES', 'STG_STELLAR_WAITLISTS',
            'STG_STELLAR_CLOSED_DATES', 'STG_STELLAR_HOLIDAYS',
            'STG_STELLAR_BLACKLISTS', 'STG_STELLAR_CATEGORIES',
            'STG_STELLAR_AMENITIES'
        ]
        
        logger.info("Truncating Stellar staging tables...")
        for table in staging_tables:
            try:
                self.cursor.execute(f"TRUNCATE TABLE {table}")
                logger.debug(f"✅ Truncated {table}")
            except Exception as e:
                logger.warning(f"Could not truncate {table}: {e}")
        
        self.connection.commit()
        logger.info(
            f"✅ Successfully truncated {len(staging_tables)} "
            "Stellar staging tables"
        )
    
    def run_all_merges(self):
        """
        Execute the master stored procedure that merges all staging tables.
        
        This calls SP_RUN_ALL_MOLO_STELLAR_MERGES which internally calls 
        all individual merge procedures. The stored procedures handle:
        - MERGE logic (UPDATE existing, INSERT new)
        - INSERTED_DATE and UPDATED_DATE management
        - Transaction commits
        """
        logger.info(
            "Executing stored procedure to merge all Stellar staging "
            "data to data warehouse..."
        )
        try:
            self.cursor.execute("BEGIN SP_RUN_ALL_MOLO_STELLAR_MERGES; END;")
            self.connection.commit()
            logger.info("✅ Successfully completed all Stellar merge operations")
        except Exception as e:
            logger.warning(
                f"⚠️  Stored procedure SP_RUN_ALL_MOLO_STELLAR_MERGES not found or failed: {e}"
            )
            logger.warning(
                "   Data has been loaded into STG_STELLAR_* staging tables successfully."
            )
            logger.warning(
                "   Create the stored procedures to merge STG_* → DW_* tables."
            )
            # Don't raise - let the process continue
            self.connection.rollback()
    
    def close(self):
        """Close database cursor and connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Database connection closed")


    # ========================================================================
    # MERGE FUNCTIONS - Stellar Business Tables
    # ========================================================================

    def insert_locations(self, data_rows):
        """
        Insert location data into STG_STELLAR_LOCATIONS table.
        All 22 columns.
        
        Args:
            data_rows: List of tuples containing location data
        """
        if not data_rows:
            logger.info("No location data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_LOCATIONS (ID, CODE, LOCATION_NAME, LOCATION_TYPE, MINIMUM_1, MINIMUM_2,
                    DELIVERY, FRONTEND, PRICING, IS_INTERNAL, IS_CANCELED, 
                    CANCEL_REASON, CANCEL_DATE, IS_TRANSFERRED, TRANSFER_DESTINATION,
                    MODULE_TYPE, OPERATING_LOCATION, ZOHO_ID, ZCRM_ID, IS_ACTIVE,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} location records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging location data: {e}")
            raise

    def insert_customers(self, data_rows):
        """
        Insert customer data into STG_STELLAR_CUSTOMERS table.
        All 52 columns, using USER_ID as primary key (not ID!).
        
        Args:
            data_rows: List of tuples containing customer data
        """
        if not data_rows:
            logger.info("No customer data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_CUSTOMERS (USER_ID, CLUB_PRINCIPAL_USER_ID, COUPON_ID, CLUB_TIER_ID,
                    FIRST_NAME, LAST_NAME, MIDDLE_NAME, GENDER,
                    PHONE, CELL, EMERGENCY_NAME, EMERGENCY_PHONE, SECONDARY_EMAIL,
                    BILLING_STREET1, BILLING_STREET2, BILLING_CITY, BILLING_STATE, BILLING_COUNTRY, BILLING_ZIP,
                    MAILING_STREET1, MAILING_STREET2, MAILING_CITY, MAILING_STATE, MAILING_COUNTRY, MAILING_ZIP,
                    NUM_KIDS, REFERRER, SERVICES, DATE_OF_BIRTH,
                    DL_STATE, DL_COUNTRY, DL_NUMBER,
                    NOTES, INTERNAL_NOTES,
                    CLUB_STATUS, CLUB_START_DATE, CLUB_USE_RECURRING_BILLING, CLUB_RECURRING_BILLING_START_DATE,
                    BALANCE, BOAT_DAMAGE_RESPONSIBILITY_COVERAGE, PENALTY_POINTS, OPEN_BALANCE_THRESHOLD, CLUB_END_DATE,
                    CC_SAVED_NAME, CC_SAVED_LAST4, CC_SAVED_EXPIRY, CC_SAVED_PROFILE_ID,
                    CC_SAVED_METHOD_ID, CC_SAVED_ADDRESS_ID,
                    EXTERNAL_ID, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39, :40, :41, :42, :43, :44, :45, :46, :47, :48, :49, :50, :51, :52)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} customer records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging customer data: {e}")
            raise

    def insert_bookings(self, data_rows):
        """
        Insert booking data into STG_STELLAR_BOOKINGS table.
        
        Args:
            data_rows: List of tuples containing booking data (82 columns)
        """
        if not data_rows:
            logger.info("No booking data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_BOOKINGS (ID, LOCATION_ID, CUSTOMER_ID, CREATOR_ID, ADMIN_ID, BILLING_FIRST_NAME, BILLING_LAST_NAME, BILLING_STREET1, BILLING_STREET2, BILLING_CITY, BILLING_STATE, BILLING_COUNTRY, BILLING_ZIP, CC_SAVED_NAME, CC_SAVED_LAST4, CC_SAVED_PROFILE_ID, CC_SAVED_METHOD_ID, CC_SAVED_ADDRESS_ID, CC_PREAUTH_ID, CC_PREAUTH_AMOUNT, CC_CONNECT_TYPE, CC_CONNECT_ID, ACCESSORIES_CUSTOM_PRICE, ACCESSORIES_TOTAL, INSURANCE_AMOUNT, PETS, PARKING, PARKING_OVERRIDE, BOATS_TOTAL, POS_TOTAL, USE_CLUB_CREDITS, NO_SHOW_FEE, CANCELLATION_FEE, CLUB_FEES, CLUB_FEES_OVERRIDE, SUB_TOTAL, CONVENIENCE_FEE, CONVENIENCE_FEE_WAIVED, INTERNAL_APPLICATION_FEE, TAX_1, TAX_1_EXEMPT, TAX_1_RATE_OVERRIDE, TAX_2, TAX_2_EXEMPT, CHECK_IN_TAX_1, CHECK_IN_TAX_2, CHECK_IN_TOTAL, DEPOSIT_TOTAL, DEPOSIT_OVERRIDE, DEPOSIT_WAIVED, GRATUITY, GRAND_TOTAL, ADJUSTMENT_TOTAL, AMOUNT_PAID, NOTES, NOTES_CONTRACT, NOTES_FROM_CUSTOMER, NOTES_FROM_CUSTOMER_CONTRACT, NOTES_FOR_CUSTOMER, NOTES_FOR_CUSTOMER_CONTRACT, FRONTEND, IS_ON_HOLD, IS_LOCKED, IS_FINALIZED, IS_CANCELED, OVERRIDE_TURNAROUND_TIME, CANCELLATION_TYPE, BYPASS_CLUB_RESTRICTIONS, RENTERS_INSURANCE_INTEREST, COUPON_ID, COUPON_TYPE, COUPON_AMOUNT, DISCOUNT_TOTAL, AGENT_ID, AGENT_NAME, REFERRER_ID, SAFETY_REMINDER, DELETED_ADMIN_ID, CREATED_AT, UPDATED_AT, FINALIZED_AT, DELETED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39, :40, :41, :42, :43, :44, :45, :46, :47, :48, :49, :50, :51, :52, :53, :54, :55, :56, :57, :58, :59, :60, :61, :62, :63, :64, :65, :66, :67, :68, :69, :70, :71, :72, :73, :74, :75, :76, :77, :78, :79, :80, :81, :82)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} booking records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging booking data: {e}")
            raise

    def insert_booking_boats(self, data_rows):
        """
        Insert booking boat data into STG_STELLAR_BOOKING_BOATS table.
        
        Args:
            data_rows: List of tuples containing booking boat data (57 columns)
        """
        if not data_rows:
            logger.info("No booking boat data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_BOOKING_BOATS (ID, BOOKING_ID, STYLE_ID, BOAT_ID, TIME_ID, TIMEFRAME_ID,
                    MAIN_BOAT, NUM_PASSENGERS, BOAT_DEPARTURE, BOAT_RETURN, STATUS_BOOKING,
                    PRICE, PRICE_OVERRIDE, SIGNATURE_DATE, CHECK_OUT_DATE, CHECK_OUT_EQUIPMENT,
                    CHECK_OUT_NOTES, CHECK_OUT_ENGINE_HOURS, CHECK_IN_DATE, CHECK_IN_EQUIPMENT,
                    CHECK_IN_NOTES, CHECK_IN_ENGINE_HOURS, CHECK_IN_HOURS, CHECK_IN_DEPOSIT,
                    CHECK_IN_WEATHER, CHECK_IN_LATE, CHECK_IN_MISC_NON_TAX, CHECK_IN_MISC_TAX,
                    CHECK_IN_CLEANING, CHECK_IN_GALLONS, CHECK_IN_FUEL, CHECK_IN_DIESEL_GALLONS,
                    CHECK_IN_DIESEL, CHECK_IN_TIP, CHECK_IN_TAX_1, CHECK_IN_TAX_2, CHECK_IN_TOTAL,
                    QUEUE_ADMIN_ID, QUEUE_DATE, ATTENDANT_QUEUE_ADMIN_ID, ATTENDANT_WATER_ADMIN_ID,
                    BOAT_ASSIGNED, ADDITIONAL_DRIVERS, ADDITIONAL_DRIVER_NAMES, ACCESSORIES_MIGRATED,
                    PRICE_RULE_ID, PRICE_RULE_ORIGINAL_PRICE, PRICE_RULE_DYNAMIC_PRICE,
                    PRICE_RULE_DIFFERENCE, EMERGENCY_NAME, EMERGENCY_PHONE, DATE_OF_BIRTH,
                    CONTRACT_RETURN_PDF, CONTRACT_PDF, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39, :40, :41, :42, :43, :44, :45, :46, :47, :48, :49, :50, :51, :52, :53, :54, :55, :56)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} booking boat records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging booking boat data: {e}")
            raise

    def insert_booking_payments(self, data_rows):
        """
        Insert booking payment data into STG_STELLAR_BOOKING_PAYMENTS table.
        
        Args:
            data_rows: List of tuples containing booking payment data (56 columns)
        """
        if not data_rows:
            logger.info("No booking payment data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_BOOKING_PAYMENTS (ID, BOOKING_ID, CUSTOMER_ID, ADMIN_ID, FRONTEND, PAYMENT_FOR,
                    PAYMENT_TYPE, CARD_TYPE, PAYMENT_TOTAL, CASH_TOTAL, CREDIT_TOTAL,
                    AGENT_AR_TOTAL, CREDIT_LAST4, CREDIT_EXPIRY, BILLING_FIRST_NAME,
                    BILLING_LAST_NAME, BILLING_STREET1, BILLING_STREET2, BILLING_CITY,
                    BILLING_STATE, BILLING_COUNTRY, BILLING_ZIP, TRANS_ID,
                    ORIGINAL_PAYMENT_ID, STATUS_PAYMENT, NOTES, IS_AGENT_AR, OFFLINE_TYPE,
                    DOCK_MASTER_TICKET, MY_TASK_IT_ID, REPORT_BOATS, REPORT_PROPANE,
                    REPORT_ACCESSORIES, REPORT_PARKING, REPORT_INSURANCE, REPORT_FUEL,
                    REPORT_DAMAGES, REPORT_CLEANING, REPORT_LATE, REPORT_OTHER, REPORT_DISCOUNT,
                    INTERNAL_APPLICATION_FEE, CC_PROCESSOR_FEE, CC_BRAND, CC_COUNTRY,
                    CC_FUNDING, CC_CONNECT_TYPE, CC_CONNECT_ID, CC_PAYOUT_ID, CC_PAYOUT_DATE,
                    EXTERNAL_CHARGE_ID, IS_SYNCED, STRIPE_READER_ID, CREATED_AT, UPDATED_AT, DELETED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39, :40, :41, :42, :43, :44, :45, :46, :47, :48, :49, :50, :51, :52, :53, :54, :55, :56)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} booking payment records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging booking payment data: {e}")
            raise

    def insert_style_groups(self, data_rows):
        """
        Insert style group data into STG_STELLAR_STYLE_GROUPS table (11 columns).
        
        Args:
            data_rows: List of tuples containing style group data (11 values each)
        """
        if not data_rows:
            logger.info("No style group data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLE_GROUPS (ID, LOCATION_ID, GROUP_NAME, FRONTEND_MAX_SAME_DEPARTURES,
                    SAFETY_TEST_ENABLED, SAFETY_TEST_INSTRUCTIONS, SAFETY_TEST_MIN_PERCENT_PASS,
                    SAFETY_TEST_EXPIRATION_DAYS, SAFETY_VIDEO_LINK, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style group records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style group data: {e}")
            raise

    def insert_styles(self, data_rows):
        """
        Insert style data into STG_STELLAR_STYLES table (98 columns).
        
        Args:
            data_rows: List of tuples containing style data
        """
        if not data_rows:
            logger.info("No style data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLES (ID, LOCATION_ID, STYLE_GROUP_ID, STYLE_NAME, BACKEND_DISPLAY, POSITION_ORDER,
                    TURN_AROUND_TIME, DEPOSIT_AMOUNT, MULTI_DAY_DEPOSIT_AMOUNT, PRE_AUTH_AMOUNT,
                    FUEL_BURN_RATIO, TAX_1_RATE, TAX_2_RATE, INSURANCE_ENABLED, INSURANCE_PRICING_TYPE,
                    INSURANCE_PRICING_RATE, INSURANCE_FIRST_DAY_PRICE, GRATUITY_ENABLED, GRATUITY_PRICING_RATE,
                    PARKING_QTY_MULTIPLIER, FRONTEND_DISPLAY, FRONTEND_NAME, FRONTEND_POSITION, FRONTEND_TYPE,
                    FRONTEND_QTY_LIMIT, FRONTEND_UNIT_SELECTOR, FRONTEND_PARTIAL_PAYMENT_TYPE,
                    FRONTEND_PARTIAL_PAYMENT_AMOUNT, BACKEND_MULTI_DAY_DISABLED, MAX_SAME_STYLE_PER_BOOKING,
                    FRONTEND_MIN_HOURS_ADVANCE_DEPARTURE, BACKEND_HOURLY_ENABLED, WEEK_DAY_BACKEND_HOURLY_MIN_HOURS,
                    WEEK_DAY_BACKEND_HOURLY_MAX_HOURS, WEEK_END_BACKEND_HOURLY_MIN_HOURS, WEEK_END_BACKEND_HOURLY_MAX_HOURS,
                    HOLIDAY_BACKEND_HOURLY_MIN_HOURS, HOLIDAY_BACKEND_HOURLY_MAX_HOURS, FRONTEND_HOURLY_ENABLED,
                    WEEK_DAY_FRONTEND_HOURLY_MIN_HOURS, WEEK_DAY_FRONTEND_HOURLY_MAX_HOURS,
                    WEEK_DAY_FRONTEND_HOURLY_TIME_INCREMENT, WEEK_DAY_FRONTEND_HOURLY_LENGTH_INCREMENT,
                    WEEK_END_FRONTEND_HOURLY_MIN_HOURS, WEEK_END_FRONTEND_HOURLY_MAX_HOURS,
                    WEEK_END_FRONTEND_HOURLY_TIME_INCREMENT, WEEK_END_FRONTEND_HOURLY_LENGTH_INCREMENT,
                    HOLIDAY_FRONTEND_HOURLY_MIN_HOURS, HOLIDAY_FRONTEND_HOURLY_MAX_HOURS,
                    HOLIDAY_FRONTEND_HOURLY_TIME_INCREMENT, HOLIDAY_FRONTEND_HOURLY_LENGTH_INCREMENT,
                    BACKEND_NIGHTLY_ENABLED, BACKEND_NIGHTLY_MIN_NIGHTS, BACKEND_NIGHTLY_MAX_NIGHTS,
                    BACKEND_NIGHTLY_START, BACKEND_NIGHTLY_END, BACKEND_NIGHTLY_DISCOUNT_DAYS,
                    BACKEND_NIGHTLY_DISCOUNT_TYPE, BACKEND_NIGHTLY_DISCOUNT_AMOUNT, FRONTEND_NIGHTLY_ENABLED,
                    FRONTEND_NIGHTLY_MIN_NIGHTS, FRONTEND_NIGHTLY_MIN_NIGHTS_PEAK, FRONTEND_NIGHTLY_MAX_NIGHTS,
                    FRONTEND_NIGHTLY_START, FRONTEND_NIGHTLY_END, FRONTEND_NIGHTLY_ADDL_TIMES,
                    FRONTEND_NIGHTLY_DISCOUNT_DAYS, FRONTEND_NIGHTLY_DISCOUNT_TYPE, FRONTEND_NIGHTLY_DISCOUNT_AMOUNT,
                    IMAGE_URL, PASSENGERS, WEIGHT_CAPACITY, HORSEPOWER, ENGINE_TYPE, LENGTH_FEET,
                    WIDTH_FEET, DRAFT_FEET, FUEL_CAPACITY, BRAND, MODEL, TITLE,
                    DESCRIPTION_TEXT, SUMMARY_TEXT, NOTES, VIDEO_LINK, SMARTWAIVER_WAIVER_LINK,
                    ACCOUNTING_ITEM_ID, LOCAL_VIDEO_LINK, DOCKMASTER_PART_NUMBER, DOCKMASTER_TAX_CODE,
                    END_HOURS, SEASONAL_BUFFER_DEFAULT_LOWER, SEASONAL_BUFFER_DEFAULT_UPPER,
                    SEASONAL_BUFFER_PEAK_LOWER, SEASONAL_BUFFER_PEAK_UPPER, BILLABLE_UNIT_TYPE,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39, :40, :41, :42, :43, :44, :45, :46, :47, :48, :49, :50, :51, :52, :53, :54, :55, :56, :57, :58, :59, :60, :61, :62, :63, :64, :65, :66, :67, :68, :69, :70, :71, :72, :73, :74, :75, :76, :77, :78, :79, :80, :81, :82, :83, :84, :85, :86, :87, :88, :89, :90, :91, :92, :93, :94, :95, :96, :97, :98)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style data: {e}")
            raise

    def insert_style_boats(self, data_rows):
        """
        Insert style boat data into STG_STELLAR_STYLE_BOATS table.
        
        Args:
            data_rows: List of tuples containing style boat data (39 columns)
        """
        if not data_rows:
            logger.info("No style boat data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLE_BOATS (ID, STYLE_ID, BOAT_NUMBER, PAPER_LESS_NUMBER, MOTOR, MANUFACTURER,
                    SERIAL_NUMBER, IN_FLEET, HULL_NUMBER, STATE_NUMBER, CYLINDERS, HP,
                    MODEL, BOAT_TYPE, PURCHASED_DATE, PURCHASED_COST, SALE_DATE, SALE_PRICE,
                    CLUB_LOCATION, DEALER_NAME, DEALER_CITY, DEALER_STATE, PO_NUMBER,
                    BOAT_YEAR_MODEL, MOTOR_YEAR_MODEL, MOTOR_MANUFACTURER_MODEL,
                    STATE_REG_DATE, STATE_REG_EXP_DATE, ENGINE_PURCHASED_COST,
                    BACKEND_DISPLAY, POSITION_ORDER, STATUS_BOAT, SERVICE_START, SERVICE_END,
                    CLEAN_STATUS, INSURANCE_REG_NO, BUOY_INSURANCE_STATUS, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33, :34, :35, :36, :37, :38, :39)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style boat records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style boat data: {e}")
            raise

    def insert_customer_boats(self, data_rows):
        """
        Insert customer boat data into STG_STELLAR_CUSTOMER_BOATS table.
        Customer-owned boats - 9 columns.
        
        Args:
            data_rows: List of tuples containing customer boat data (9 columns)
        """
        if not data_rows:
            logger.info("No customer boat data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_CUSTOMER_BOATS (ID, CUSTOMER_ID, SLIP_ID, BOAT_NAME, BOAT_NUMBER,
                    LENGTH_FEET, WIDTH_FEET, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} customer boat records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging customer boat data: {e}")
            raise

    def insert_seasons(self, data_rows):
        """
        Insert season data into STG_STELLAR_SEASONS table.
        All 20 columns.
        
        Args:
            data_rows: List of tuples containing season data
        """
        if not data_rows:
            logger.info("No season data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_SEASONS (ID, LOCATION_ID, SEASON_NAME, SEASON_START, SEASON_END,
                    STATUS_SEASON, WEEK_DAY_MIN_START_TIME, WEEK_DAY_MAX_START_TIME,
                    WEEK_DAY_MIN_END_TIME, WEEK_DAY_MAX_END_TIME, WEEK_END_MIN_START_TIME,
                    WEEK_END_MAX_START_TIME, WEEK_END_MIN_END_TIME, WEEK_END_MAX_END_TIME,
                    HOLIDAY_MIN_START_TIME, HOLIDAY_MAX_START_TIME, HOLIDAY_MIN_END_TIME,
                    HOLIDAY_MAX_END_TIME, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} season records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging season data: {e}")
            raise

    def insert_season_dates(self, data_rows):
        """
        Insert season date data into STG_STELLAR_SEASON_DATES table.
        Season date ranges - 4 columns.
        
        Args:
            data_rows: List of tuples containing season date data (4 columns)
        """
        if not data_rows:
            logger.info("No season date data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_SEASON_DATES (ID, SEASON_ID, START_DATE, END_DATE)
            VALUES (:1, :2, :3, :4)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} season date records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging season date data: {e}")
            raise

    def insert_style_hourly_prices(self, data_rows):
        """
        Insert style hourly price data into STG_STELLAR_STYLE_HOURLY_PRICES table.
        Hourly pricing by style and season - 22 columns.
        
        Args:
            data_rows: List of tuples containing style hourly price data (22 columns)
        """
        if not data_rows:
            logger.info("No style hourly price data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLE_HOURLY_PRICES (ID, STYLE_ID, SEASON_ID, HOURLY_TYPE, DEFAULT_PRICE,
                    HOLIDAY, SATURDAY, SUNDAY, MONDAY, TUESDAY, WEDNESDAY,
                    THURSDAY, FRIDAY, DAY_DISCOUNT, UNDER_ONE_HOUR,
                    FIRST_HOUR_AM, FIRST_HOUR_PM, MAX_PRICE, MIN_HOURS,
                    MAX_HOURS, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style hourly price records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style hourly price data: {e}")
            raise

    def insert_style_times(self, data_rows):
        """
        Insert style time data into STG_STELLAR_STYLE_TIMES table.
        Time slot availability by style - 26 columns (note: missing UPDATED_AT in schema, has 25 total).
        
        Args:
            data_rows: List of tuples containing style time data (25 columns)
        """
        if not data_rows:
            logger.info("No style time data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLE_TIMES (ID, STYLE_ID, SEASON_ID, DESCRIPTION_TEXT, FRONTEND_DISPLAY,
                    START_1, END_1, END_DAYS_1, STATUS_1, START_2, END_2, END_DAYS_2,
                    STATUS_2, START_3, END_3, END_DAYS_3, STATUS_3, START_4, END_4,
                    END_DAYS_4, STATUS_4, VALID_DAYS, HOLIDAYS_ONLY_IF_VALID_DAY,
                    MAPPED_TIME_ID, CREATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style time records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style time data: {e}")
            raise
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style time records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style time data: {e}")
            raise

    def insert_style_prices(self, data_rows):
        """
        Insert style price data into STG_STELLAR_STYLE_PRICES table.
        Uses TIME_ID as primary key (not ID). 12 columns total.
        
        Args:
            data_rows: List of tuples containing style price data
        """
        if not data_rows:
            logger.info("No style price data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_STYLE_PRICES (TIME_ID, DEFAULT_PRICE, HOLIDAY, SATURDAY, SUNDAY, MONDAY,
                    TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} style price records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging style price data: {e}")
            raise

    def insert_accessories(self, data_rows):
        """
        Insert accessory data into STG_STELLAR_ACCESSORIES table.
        All 19 columns.
        
        Args:
            data_rows: List of tuples containing accessory data
        """
        if not data_rows:
            logger.info("No accessory data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_ACCESSORIES (ID, LOCATION_ID, ACCESSORY_NAME, POSITION_ORDER, FRONTEND_POSITION,
                    SHORT_NAME, ABBREVIATION, IMAGE_URL, PRICE, DEPOSIT_AMOUNT,
                    TAX_EXEMPT, MAX_OVERLAPPING_RENTALS, FRONTEND_QTY_LIMIT,
                    USE_STRIPED_BACKGROUND, BACKEND_AVAILABLE_DAYS, FRONTEND_AVAILABLE_DAYS,
                    MAX_SAME_DEPARTURES, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} accessory records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging accessory data: {e}")
            raise

    def insert_accessory_options(self, data_rows):
        """
        Insert accessory option data into STG_STELLAR_ACCESSORY_OPTIONS table.
        CSV 'value' → DB 'VALUE_TEXT', CSV 'use_striped_background' → DB 'USE_STRIPED_BACKGROUND'
        
        Args:
            data_rows: List of tuples containing accessory option data (6 fields)
        """
        if not data_rows:
            logger.info("No accessory option data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_ACCESSORY_OPTIONS (ID, ACCESSORY_ID, VALUE_TEXT, USE_STRIPED_BACKGROUND,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} accessory option records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging accessory option data: {e}")
            raise

    def insert_accessory_tiers(self, data_rows):
        """
        Insert accessory tier data into STG_STELLAR_ACCESSORY_TIERS table.
        8 columns: ID, ACCESSORY_ID, MIN_HOURS, MAX_HOURS, PRICE, ACCESSORY_OPTION_ID, CREATED_AT, UPDATED_AT
        
        Args:
            data_rows: List of tuples containing accessory tier data (8 fields)
        """
        if not data_rows:
            logger.info("No accessory tier data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_ACCESSORY_TIERS (ID, ACCESSORY_ID, MIN_HOURS, MAX_HOURS, PRICE, ACCESSORY_OPTION_ID,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} accessory tier records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging accessory tier data: {e}")
            raise

    def insert_booking_accessories(self, data_rows):
        """
        Insert booking accessory data into STG_STELLAR_BOOKING_ACCESSORIES table.
        Uses composite key (BOOKING_ID + ACCESSORY_ID) - no ID column.
        
        Args:
            data_rows: List of tuples containing booking accessory data (8 columns)
        """
        if not data_rows:
            logger.info("No booking accessory data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_BOOKING_ACCESSORIES (BOOKING_ID, ACCESSORY_ID, QTY, PRICE, PRICE_OVERRIDE,
                    ACCESSORY_OPTION_ID, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} booking accessory records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging booking accessory data: {e}")
            raise

    def insert_club_tiers(self, data_rows):
        """
        Insert club tier data into STG_STELLAR_CLUB_TIERS table.
        Complete 28-column membership tier structure.
        
        Args:
            data_rows: List of tuples containing club tier data (28 columns)
        """
        if not data_rows:
            logger.info("No club tier data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_CLUB_TIERS (ID, LOCATION_ID, TIER_NAME, FRONTEND_DISPLAY, FRONTEND_NAME,
                    FRONTEND_POSITION, TERM_LENGTH, TERM_LENGTH_TYPE, TERM_AUTO_RENEW,
                    TERM_FEE, PERIOD_LENGTH, PERIOD_LENGTH_TYPE, CREDITS_PER_PERIOD,
                    HOURS_PER_CREDIT, PERIOD_FEE, FRONTEND_DISPLAY_PRICING, NO_SHOW_FEE,
                    ALLOW_SELF_CANCELLATIONS, CANCELLATION_FEE, APPLICATION_FEE,
                    BOAT_DAMAGE_RESPONSIBILITY_DEDUCTION, MAX_PENDING_WAIT_LIST_ENTRIES,
                    FREE_ACCESSORIES, DESCRIPTION_TEXT, TERMS_TEXT, STATUS_TIER,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} club tier records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging club tier data: {e}")
            raise

    def insert_coupons(self, data_rows):
        """
        Insert coupon data into STG_STELLAR_COUPONS table.
        Discount coupon management - 30 columns.
        
        Args:
            data_rows: List of tuples containing coupon data (30 columns)
        """
        if not data_rows:
            logger.info("No coupon data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_COUPONS (ID, LOCATION_ID, CODE, COUPON_NAME, COUPON_TYPE, COUPON_AMOUNT,
                    COUNT_ALLOWED, COUNT_ALLOWED_DAILY, COUNT_USED, RENTAL_START,
                    RENTAL_END, COUPON_START, COUPON_END, MIN_DEPARTURE_TIME,
                    MAX_DEPARTURE_TIME, MIN_RETURN_TIME, MAX_RETURN_TIME, MIN_HOURS,
                    MAX_HOURS, MIN_HOURS_BEFORE_DEPARTURE, MAX_HOURS_BEFORE_DEPARTURE,
                    MAX_SAME_DAY_PER_CUSTOMER, MAX_ACTIVE_PER_CUSTOMER,
                    DISABLE_CONSECUTIVE_PER_CUSTOMER, STATUS_COUPON, VALID_DAYS,
                    HOLIDAYS_ONLY_IF_VALID_DAY, VALID_STYLES, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} coupon records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging coupon data: {e}")
            raise

    def insert_pos_items(self, data_rows):
        """
        Insert POS item data into STG_STELLAR_POS_ITEMS table.
        Point of sale inventory items - 9 columns.
        
        Args:
            data_rows: List of tuples containing POS item data (9 columns)
        """
        if not data_rows:
            logger.info("No POS item data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_POS_ITEMS (ID, LOCATION_ID, SKU, ITEM_NAME, COST, PRICE,
                    TAX_EXEMPT, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} POS item records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging POS item data: {e}")
            raise

    def insert_pos_sales(self, data_rows):
        """
        Insert POS sale data into STG_STELLAR_POS_SALES table.
        Point of sale transactions - 11 columns.
        
        Args:
            data_rows: List of tuples containing POS sale data (11 columns)
        """
        if not data_rows:
            logger.info("No POS sale data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_POS_SALES (ID, LOCATION_ID, ADMIN_ID, CUSTOMER_NAME, SUB_TOTAL, TAX_1,
                    GRAND_TOTAL, AMOUNT_PAID, CREATED_AT, UPDATED_AT, DELETED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} POS sale records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging POS sale data: {e}")
            raise

    def insert_fuel_sales(self, data_rows):
        """
        Insert fuel sale data into STG_STELLAR_FUEL_SALES table.
        Fuel sales transactions - 14 columns.
        
        Args:
            data_rows: List of tuples containing fuel sale data (14 columns)
        """
        if not data_rows:
            logger.info("No fuel sale data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_FUEL_SALES (ID, LOCATION_ID, ADMIN_ID, CUSTOMER_NAME, FUEL_TYPE, QTY,
                    PRICE, SUB_TOTAL, TIP, GRAND_TOTAL, AMOUNT_PAID,
                    CREATED_AT, UPDATED_AT, DELETED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} fuel sale records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging fuel sale data: {e}")
            raise

    def insert_waitlists(self, data_rows):
        """
        Insert waitlist data into STG_STELLAR_WAITLISTS table.
        Customer waitlists for boat reservations - 18 columns.
        
        Args:
            data_rows: List of tuples containing waitlist data (18 columns)
        """
        if not data_rows:
            logger.info("No waitlist data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_WAITLISTS (ID, LOCATION_ID, CATEGORY_ID, STYLE_ID, CUSTOMER_ID, TIME_ID,
                    TIMEFRAME_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, DEPARTURE_DATE,
                    LENGTH_REQUESTED, WAIT_LIST_TIME, FULFILLED, FULFILLED_DATE,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} waitlist records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging waitlist data: {e}")
            raise

    def insert_closed_dates(self, data_rows):
        """
        Insert closed date data into STG_STELLAR_CLOSED_DATES table.
        Business closure dates - 9 columns.
        
        Args:
            data_rows: List of tuples containing closed date data (9 columns)
        """
        if not data_rows:
            logger.info("No closed date data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_CLOSED_DATES (ID, LOCATION_ID, CLOSED_DATE, ALLOW_BACKEND_DEPARTURES,
                    ALLOW_BACKEND_RETURNS, ALLOW_FRONTEND_DEPARTURES,
                    ALLOW_FRONTEND_RETURNS, CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} closed date records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging closed date data: {e}")
            raise

    def insert_holidays(self, data_rows):
        """
        Insert holiday data into STG_STELLAR_HOLIDAYS table.
        Table has NO ID column - uses composite key (LOCATION_ID + HOLIDAY_DATE)
        
        Args:
            data_rows: List of tuples containing holiday data (2 fields: location_id, holiday_date)
        """
        if not data_rows:
            logger.info("No holiday data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_HOLIDAYS (LOCATION_ID, HOLIDAY_DATE)
            VALUES (:1, :2)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} holiday records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging holiday data: {e}")
            raise

    def insert_blacklists(self, data_rows):
        """
        Insert blacklist data into STG_STELLAR_BLACKLISTS table.
        Customer restriction list - 11 columns (note: missing UPDATED_AT in schema, has 10 total).
        
        Args:
            data_rows: List of tuples containing blacklist data (10 columns)
        """
        if not data_rows:
            logger.info("No blacklist data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_BLACKLISTS (ID, LOCATION_ID, FIRST_NAME, LAST_NAME, PHONE, CELL,
                    EMAIL, DL_NUMBER, NOTES, CREATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} blacklist records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging blacklist data: {e}")
            raise
            self.connection.rollback()
            logger.exception(f"❌ Error merging blacklist data: {e}")
            raise

    def insert_categories(self, data_rows):
        """
        Insert category data into STG_STELLAR_CATEGORIES table.
        All 15 columns, CSV 'description' → DB 'DESCRIPTION_TEXT'
        
        Args:
            data_rows: List of tuples containing category data (15 fields)
        """
        if not data_rows:
            logger.info("No category data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_CATEGORIES (ID, LOCATION_ID, CATEGORY_NAME, 
                    FRONTEND_DISPLAY, FRONTEND_NAME, FRONTEND_TYPE, FRONTEND_POSITION,
                    FILTER_UNIT_TYPE_ENABLED, FILTER_UNIT_TYPE_NAME, FILTER_UNIT_TYPE_POSITION,
                    MIN_NIGHTS_MULTI_DAY, CALENDAR_BANNER_TEXT, DESCRIPTION_TEXT,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} category records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging category data: {e}")
            raise

    def insert_amenities(self, data_rows):
        """
        Insert amenity data into STG_STELLAR_AMENITIES table.
        All 16 columns.
        
        Args:
            data_rows: List of tuples containing amenity data
        """
        if not data_rows:
            logger.info("No amenity data to process")
            return
        
        insert_sql = """
        INSERT INTO STG_STELLAR_AMENITIES (ID, LOCATION_ID, AMENITY_NAME, FRONTEND_DISPLAY, FRONTEND_NAME,
                    FRONTEND_POSITION, FEATURED, FILTERABLE, ICON, AMENITY_TYPE,
                    OPTIONS_TEXT, PREFIX_TEXT, SUFFIX_TEXT, DESCRIPTION_TEXT,
                    CREATED_AT, UPDATED_AT)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16)"""
        
        try:
            self.cursor.executemany(insert_sql, data_rows)
            self.connection.commit()
            logger.info(f"✅ Inserted {len(data_rows)} amenity records")
        except Exception as e:
            self.connection.rollback()
            logger.exception(f"❌ Error merging amenity data: {e}")
            raise


