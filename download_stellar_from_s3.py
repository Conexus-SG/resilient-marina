#!/usr/bin/env python3
"""
Stellar Business Data Processing Module

Downloads gzipped DATA files from S3, parses CSVs, and inserts into Oracle staging tables.
Processes 9 core Stellar tables: customers, locations, seasons, accessories, etc.
"""

import boto3
import logging
import gzip
import csv
import io
import sys
from stellar_db_functions import OracleConnector

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('stellar_processing.log', mode='a')
    ]
)

logger = logging.getLogger(__name__)


def parse_int(value):
    """Convert string to int or None if empty."""
    if value == '' or value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def parse_float(value):
    """Convert string to float or None if empty."""
    if value == '' or value is None:
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def parse_customers_data(csv_content):
    """Parse customers CSV - 52 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('user_id')),
            parse_int(row.get('club_principal_user_id')),
            parse_int(row.get('coupon_id')),
            parse_int(row.get('club_tier_id')),
            row.get('firstname'),
            row.get('lastname'),
            row.get('middlename'),
            row.get('gender'),
            row.get('phone'),
            row.get('cell'),
            row.get('emergencyname'),
            row.get('emergencyphone'),
            row.get('secondary_email'),
            row.get('billing_street1'),
            row.get('billing_street2'),
            row.get('billing_city'),
            row.get('billing_state'),
            row.get('billing_country'),
            row.get('billing_zip'),
            row.get('mailing_street1'),
            row.get('mailing_street2'),
            row.get('mailing_city'),
            row.get('mailing_state'),
            row.get('mailing_country'),
            row.get('mailing_zip'),
            parse_int(row.get('numkids')),
            row.get('referrer'),
            row.get('services'),
            row.get('dob'),
            row.get('dlstate'),
            row.get('dlcountry'),
            row.get('dlnumber'),
            row.get('notes'),
            row.get('internal_notes'),
            row.get('club_status'),
            row.get('club_start_date'),
            parse_int(row.get('club_use_recurring_billing')),
            row.get('club_recurring_billing_start_date'),
            parse_float(row.get('balance')),
            row.get('bdrc'),
            parse_int(row.get('penalty_points')),
            parse_float(row.get('open_balance_threshold')),
            row.get('club_end_date'),
            row.get('cc_saved_name'),
            row.get('cc_saved_last4'),
            row.get('cc_saved_expiry'),
            row.get('cc_saved_profile_id'),
            row.get('cc_saved_method_id'),
            row.get('cc_saved_address_id'),
            row.get('external_id'),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} customer records")
    return data_rows


def parse_locations_data(csv_content):
    """Parse locations CSV - 22 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            row.get('code'),
            row.get('location_name'),
            row.get('location_type'),
            parse_int(row.get('minimum_1')),
            parse_int(row.get('minimum_2')),
            parse_int(row.get('delivery')),
            parse_int(row.get('frontend')),
            row.get('pricing'),
            parse_int(row.get('is_internal')),
            parse_int(row.get('is_canceled')),
            row.get('cancel_reason'),
            row.get('cancel_date'),
            parse_int(row.get('is_transferred')),
            row.get('transfer_destination'),
            row.get('module_type'),
            row.get('operating_location'),
            row.get('zoho_id'),
            row.get('zcrm_id'),
            parse_int(row.get('is_active')),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} location records")
    return data_rows


def parse_seasons_data(csv_content):
    """Parse seasons CSV - 20 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('location_id')),
            row.get('season_name'),
            row.get('season_start'),
            row.get('season_end'),
            row.get('status'),
            row.get('weekday_min_start_time'),
            row.get('weekday_max_start_time'),
            row.get('weekday_min_end_time'),
            row.get('weekday_max_end_time'),
            row.get('weekend_min_start_time'),
            row.get('weekend_max_start_time'),
            row.get('weekend_min_end_time'),
            row.get('weekend_max_end_time'),
            row.get('holiday_min_start_time'),
            row.get('holiday_max_start_time'),
            row.get('holiday_min_end_time'),
            row.get('holiday_max_end_time'),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} season records")
    return data_rows


def parse_accessories_data(csv_content):
    """Parse accessories CSV - 19 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('location_id')),
            row.get('accessory_name'),
            parse_int(row.get('position')),
            parse_int(row.get('frontend_position')),
            row.get('short_name'),
            row.get('abbreviation'),
            row.get('image'),
            parse_float(row.get('price')),
            parse_float(row.get('deposit_amount')),
            parse_int(row.get('tax_exempt')),
            parse_int(row.get('max_overlapping_rentals')),
            parse_int(row.get('frontend_qty_limit')),
            parse_int(row.get('use_striped_background')),
            parse_int(row.get('backend_available_days')),
            parse_int(row.get('frontend_available_days')),
            parse_int(row.get('max_same_departures')),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} accessory records")
    return data_rows


def parse_accessory_options_data(csv_content):
    """Parse accessory_options CSV - 6 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('accessory_id')),
            row.get('value'),
            parse_int(row.get('use_striped_background')),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} accessory option records")
    return data_rows


def parse_accessory_tiers_data(csv_content):
    """Parse accessory_tiers CSV - 8 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('accessory_id')),
            parse_int(row.get('min_hours')),
            parse_int(row.get('max_hours')),
            parse_float(row.get('price')),
            parse_int(row.get('accessory_option_id')),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} accessory tier records")
    return data_rows


def parse_amenities_data(csv_content):
    """Parse amenities CSV - 16 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('location_id')),
            row.get('amenity_name'),
            parse_int(row.get('frontend_display')),
            row.get('frontend_name'),
            parse_int(row.get('frontend_position')),
            parse_int(row.get('featured')),
            parse_int(row.get('filterable')),
            row.get('icon'),
            row.get('type'),
            row.get('options'),
            row.get('prefix'),
            row.get('suffix'),
            row.get('description'),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} amenity records")
    return data_rows


def parse_categories_data(csv_content):
    """Parse categories CSV - 15 columns matching actual CSV structure."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('id')),
            parse_int(row.get('location_id')),
            row.get('category_name'),
            parse_int(row.get('frontend_display')),
            row.get('frontend_name'),
            row.get('frontend_type'),
            parse_int(row.get('frontend_position')),
            parse_int(row.get('filter_unit_type_enabled')),
            row.get('filter_unit_type_name'),
            parse_int(row.get('filter_unit_type_position')),
            parse_int(row.get('min_nights_multi_day')),
            row.get('calendar_banner_text'),
            row.get('description'),
            row.get('created_at'),
            row.get('updated_at')
        ))
    
    logger.info(f"Parsed {len(data_rows)} category records")
    return data_rows


def parse_holidays_data(csv_content):
    """Parse holidays CSV - 2 columns (no ID column)."""
    reader = csv.DictReader(io.StringIO(csv_content))
    data_rows = []
    
    for row in reader:
        data_rows.append((
            parse_int(row.get('location_id')),
            row.get('holiday_date')
        ))
    
    logger.info(f"Parsed {len(data_rows)} holiday records")
    return data_rows


def find_latest_data_file_in_s3(s3_client, bucket, prefix):
    """Find the most recent .gz file in S3 bucket with given prefix."""
    try:
        response = s3_client.list_objects_v2(Bucket=bucket, Prefix=prefix)
        
        if 'Contents' not in response:
            logger.warning(f"No files found in s3://{bucket}/{prefix}")
            return None
        
        gz_files = [obj for obj in response['Contents'] if obj['Key'].endswith('.gz')]
        
        if not gz_files:
            logger.warning(f"No .gz files found in s3://{bucket}/{prefix}")
            return None
        
        gz_files.sort(key=lambda x: x['LastModified'], reverse=True)
        latest_file = gz_files[0]['Key']
        
        logger.info(f"Found latest file: {latest_file}")
        return latest_file
        
    except Exception as e:
        logger.error(f"Error finding latest file: {e}")
        return None


def download_and_parse_stellar_table(s3_client, bucket, table_name, parser_func):
    """Download Stellar table from S3, decompress, and parse CSV."""
    prefix = f"{table_name}/"
    
    logger.info(f"\nProcessing table: {table_name.upper()}")
    
    latest_key = find_latest_data_file_in_s3(s3_client, bucket, prefix)
    if not latest_key:
        return None
    
    try:
        logger.info(f"Downloading: s3://{bucket}/{latest_key}")
        response = s3_client.get_object(Bucket=bucket, Key=latest_key)
        
        with gzip.GzipFile(fileobj=response['Body']) as gzipfile:
            csv_content = gzipfile.read().decode('utf-8')
        
        logger.info(f"Downloaded and decompressed {len(csv_content)} bytes")
        
        data_rows = parser_func(csv_content)
        return data_rows
        
    except Exception as e:
        logger.exception(f"Error processing {table_name}: {e}")
        return None


def process_stellar_data_from_s3(
    bucket,
    region,
    db_user,
    db_password,
    db_dsn,
    aws_access_key_id=None,
    aws_secret_access_key=None
):
    """
    Main Stellar data processing function.
    Downloads gzipped DATA files from S3 and inserts into Oracle staging tables.
    """
    logger.info("=" * 80)
    logger.info("STELLAR BUSINESS DATA PROCESSING - START")
    logger.info("=" * 80)
    
    # Initialize S3 client
    try:
        if aws_access_key_id and aws_secret_access_key:
            s3_client = boto3.client(
                's3',
                region_name=region,
                aws_access_key_id=aws_access_key_id,
                aws_secret_access_key=aws_secret_access_key
            )
        else:
            s3_client = boto3.client('s3', region_name=region)
        
        logger.info(f"Connected to S3 in region: {region}, bucket: {bucket}")
        
    except Exception as e:
        logger.exception(f"Failed to initialize S3 client: {e}")
        raise
    
    # Initialize Oracle database
    try:
        db_connector = OracleConnector(db_user, db_password, db_dsn)
        logger.info("Connected to Oracle database")
    except Exception as e:
        logger.exception(f"Failed to connect to Oracle: {e}")
        raise
    
    # Define tables to process
    tables_to_process = [
        ('customers', parse_customers_data, db_connector.insert_customers),
        ('locations', parse_locations_data, db_connector.insert_locations),
        ('seasons', parse_seasons_data, db_connector.insert_seasons),
        ('accessories', parse_accessories_data, db_connector.insert_accessories),
        ('accessory_options', parse_accessory_options_data, db_connector.insert_accessory_options),
        ('accessory_tiers', parse_accessory_tiers_data, db_connector.insert_accessory_tiers),
        ('amenities', parse_amenities_data, db_connector.insert_amenities),
        ('categories', parse_categories_data, db_connector.insert_categories),
        ('holidays', parse_holidays_data, db_connector.insert_holidays),
    ]
    
    # Process each table
    total_records = 0
    successful_tables = 0
    failed_tables = []
    
    for table_name, parser_func, insert_func in tables_to_process:
        try:
            data_rows = download_and_parse_stellar_table(s3_client, bucket, table_name, parser_func)
            
            if data_rows:
                staging_table = f"STG_STELLAR_{table_name.upper()}"
                logger.info(f"Truncating {staging_table}...")
                db_connector.cursor.execute(f"TRUNCATE TABLE {staging_table}")
                db_connector.connection.commit()
                
                insert_func(data_rows)
                
                total_records += len(data_rows)
                successful_tables += 1
                logger.info(f"Successfully processed {table_name}: {len(data_rows)} records")
            else:
                logger.warning(f"No data found for {table_name}")
                failed_tables.append(table_name)
                
        except Exception as e:
            logger.exception(f"Failed to process {table_name}: {e}")
            failed_tables.append(table_name)
    
    # Close connection
    try:
        db_connector.cursor.close()
        db_connector.connection.close()
        logger.info("Database connection closed")
    except Exception as e:
        logger.warning(f"Error closing connection: {e}")
    
    # Summary
    logger.info("\n" + "=" * 80)
    logger.info("STELLAR BUSINESS DATA PROCESSING - SUMMARY")
    logger.info("=" * 80)
    logger.info(f"Successfully processed: {successful_tables}/{len(tables_to_process)} tables")
    logger.info(f"Total records loaded: {total_records}")
    
    if failed_tables:
        logger.warning(f"Failed tables: {', '.join(failed_tables)}")
    else:
        logger.info("All tables processed successfully!")
    
    logger.info("=" * 80)
