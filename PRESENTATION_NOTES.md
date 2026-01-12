# AWS Marina Data ETL Pipeline - Presentation Overview

## Executive Summary

**What**: Enterprise ETL pipeline that synchronizes marina management data from two source systems into an Oracle data warehouse  
**Why**: Enable business intelligence, reporting, and unified data analytics across MOLO (marina ops) and Stellar (boat rentals)  
**Scale**: 77 data tables + 21 analytical views processing thousands of records daily

---

## System Architecture

### Three-Layer Data Pipeline

```
┌─────────────────────────────────────────┐
│  SOURCE SYSTEMS (AWS S3)                │
│  ├─ MOLO: 48 CSV files (ZIP format)    │
│  └─ Stellar: 29 CSV files (.gz format) │
└────────────────┬────────────────────────┘
                 │ Download & Extract
┌────────────────▼────────────────────────┐
│  STAGING TABLES (STG_*)                 │
│  ├─ STG_MOLO_* (48 tables)             │
│  └─ STG_STELLAR_* (29 tables)          │
│  Purpose: Raw CSV data loaded as-is    │
└────────────────┬────────────────────────┘
                 │ MERGE Stored Procedures
┌────────────────▼────────────────────────┐
│  DATA WAREHOUSE TABLES (DW_*)           │
│  ├─ DW_MOLO_* (48 tables)              │
│  └─ DW_STELLAR_* (29 tables)           │
│  Features: Auto timestamps, PK tracking│
└────────────────┬────────────────────────┘
                 │ SQL Queries & Views
┌────────────────▼────────────────────────┐
│  BUSINESS INTELLIGENCE VIEWS            │
│  ├─ MOLO Analytics (5 views)           │
│  ├─ Stellar Analytics (1 view)         │
│  └─ NetSuite Financial (15 views)      │
└─────────────────────────────────────────┘
```

---

## Key Components

### 1. **Python ETL Scripts** (3 main files)

#### `download_csv_from_s3.py` (Main Orchestrator)
- Downloads MOLO ZIP file from S3
- Extracts and parses 48 CSV files
- Loads into 48 staging tables
- Calls master merge procedure

#### `download_stellar_from_s3.py` (Stellar Processor)
- Downloads .gz files from S3
- Decompresses 29 Stellar CSV files
- Handles special cases (composite keys, custom PKs)
- Inserts into 29 Stellar staging tables

#### `molo_db_functions.py` & `stellar_db_functions.py`
- Oracle database connectors
- Staging table management
- Merge procedure execution
- Error handling and logging

### 2. **79 Stored Procedures**

```
MOLO Procedures (48 total)
├─ Core entities: accounts, boats, companies, contacts, invoices, transactions
├─ Reference data: address_types, boat_types, payment_methods, currencies, etc.
└─ Pricing: seasonal_prices, transient_prices, item_masters

Stellar Procedures (29 total)
├─ Bookings: customers, bookings, booking_boats, booking_payments
├─ Inventory: styles, style_boats, style_groups, categories
├─ Pricing: seasons, style_hourly_prices, style_times, style_prices
├─ Sales: pos_items, pos_sales, fuel_sales
└─ Reference: accessories, club_tiers, coupons, holidays, blacklists

Master Procedure
└─ SP_RUN_ALL_MOLO_STELLAR_MERGES (orchestrates all 77 merges)
```

### 3. **21 Analytical Views**

#### **MOLO Marina Views** (5 views)
Focus on marina occupancy and revenue analytics

| View | Purpose | Key Metrics |
|------|---------|------------|
| `dw_molo_daily_boat_lengths_vw` | Boat inventory analysis | Boat length distribution daily |
| `dw_molo_daily_slip_count_vw` | Slip inventory tracking | Available/occupied slips by day |
| `dw_molo_daily_slip_occupancy_vw` | Occupancy rates | Occupancy % trends over time |
| `dw_molo_rate_over_linear_foot` | Revenue per foot | Rate analysis by boat size |
| `dw_molo_rate_over_linear_foot_vw` | Rate normalization | Normalized rates for comparison |

**Use Cases**:
- Daily occupancy dashboard
- Revenue per linear foot KPI
- Slip allocation planning
- Seasonal occupancy trends
- Pricing strategy analysis

#### **Stellar Rental Views** (1 view)
Focus on boat rental activity and booking metrics

| View | Purpose | Key Metrics |
|------|---------|------------|
| `dw_stellar_daily_rentals_vw` | Daily rental activity | Bookings, revenue, boats rented daily |

**Use Cases**:
- Daily rental volume tracking
- Revenue trending
- Seasonal demand patterns
- Fleet utilization rates

#### **NetSuite Financial Integration Views** (15 views)
Real-time financial reporting linked to accounting system

| View | Purpose | Linked To |
|------|---------|-----------|
| `DW_NS_X_FIN_CASHSALE_V` | Cash transaction summary | POS/Cash receipts |
| `DW_NS_X_FIN_CHECK_V` | Check payment processing | Account payables |
| `DW_NS_X_FIN_INVOICE_V` | Invoice records | Customer invoices |
| `DW_NS_X_FIN_CUST_PAYMENT_V` | Customer payments | A/R collections |
| `DW_NS_X_FIN_JOURNAL_V` | Journal entries | GL transactions |
| `DW_NS_X_FIN_DEPOSIT_V` | Deposit tracking | Bank deposits |
| `DW_NS_X_FIN_CREDIT_CARD_V` | CC transactions | Payment processing |
| `DW_NS_X_FIN_VENDBILL_V` | Vendor bills | A/P invoicing |
| `DW_NS_X_FIN_VENDBILL_PAYMENT_V` | Vendor payments | A/P payments |
| `DW_NS_X_FIN_VENDCRED_V` | Vendor credits | A/P credits |
| `DW_NS_X_FIN_CUST_CREDIT_V` | Customer credits | A/R credits |
| `DW_NS_X_FIN_CUST_REFUND_V` | Customer refunds | Refund transactions |
| `DW_NS_X_FIN_CC_REFUND_V` | CC refunds | Chargeback handling |
| `DW_NS_X_FIN_DEPENTRY_V` | Deposit entries | Deposit detail lines |
| `DW_NS_X_FIN_REPORT_V` | Financial summary | Consolidated reporting |

**Use Cases**:
- Daily revenue reconciliation
- Cash flow analysis
- Vendor/customer account status
- GL integration verification
- Financial reporting automation

---

## Data Coverage

### MOLO System (Marina Management)
**48 Tables** covering:
- **Locations & Infrastructure**: Marina locations, piers, slips, slip types
- **Reservations**: Reservations, reservation status/types, boats, companies
- **Financial**: Invoices, invoice items, transactions, payment methods
- **Operations**: Contacts, accounts, address types, phone types
- **Pricing**: Seasonal/transient pricing, charge methods, due date settings
- **Reference**: Currencies, power needs, equipment types, record status

### Stellar System (Boat Rentals)
**29 Tables** covering:
- **Customers & Bookings**: Customer accounts, bookings, booking boats/payments/accessories
- **Boat Inventory**: Style groups, styles, style boats, customer boats
- **Pricing & Availability**: Seasons, season dates, hourly/nightly/multi-day pricing
- **Accessories**: Accessories, options, tiers
- **Sales & Operations**: POS items/sales, fuel sales, closed dates, blacklists
- **Membership**: Club tiers, coupons, waitlists
- **Reference**: Locations, categories, amenities, holidays

---

## ETL Process Flow

### Daily Execution Steps

1. **Initialize** (5 min)
   - Load config.json credentials
   - Setup Oracle Instant Client + wallet
   - Connect to AWS S3 and Oracle DB

2. **Extract MOLO** (10 min)
   - Download latest ZIP from S3
   - Extract 48 CSV files
   - Validate file integrity

3. **Extract Stellar** (8 min)
   - Download latest .gz files from S3
   - Decompress 29 Stellar CSV files
   - Handle special data cases

4. **Load Staging** (15 min)
   - Truncate all 77 staging tables
   - Batch insert CSV data into STG_* tables
   - Apply data type conversions

5. **Merge to DW** (12 min)
   - Execute SP_RUN_ALL_MOLO_STELLAR_MERGES
   - Runs all 77 merge procedures
   - MERGE: UPDATE existing + INSERT new records
   - Auto-populate INSERTED_DATE and UPDATED_DATE

6. **Validation** (Optional)
   - Compare CSV vs staging tables (field validation)
   - Compare staging vs DW tables (merge validation)
   - Sample N records per table

**Total Runtime**: ~50 minutes for complete refresh

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Data Source** | AWS S3 | Cloud storage for CSV backups |
| **ETL Language** | Python 3 | Orchestration & data processing |
| **Database** | Oracle Autonomous DB | Data warehouse (Chicago region) |
| **DB Driver** | python-oracledb | Python/Oracle connectivity |
| **Authentication** | mTLS Wallet | Secure ADB connection |
| **Containerization** | Docker | Production deployment |
| **Orchestration** | OCI Container Instances | Managed execution on schedule |
| **Configuration** | JSON (config.json) | Centralized settings |
| **Logging** | Python logging | File + console output |

---

## Security & Configuration

### Configuration Management
```json
{
  "aws": { "access_key_id", "secret_access_key", "region" },
  "database": { "user", "password", "dsn" },
  "s3": { "molo_bucket", "stellar_bucket" },
  "email": { "enabled", "smtp_server", "recipients" },
  "logging": { "level" }
}
```

### Data Protection
- ✅ Credentials in [`config.json`](config.json ) (git-ignored)
- ✅ Oracle wallet authentication (mTLS)
- ✅ S3 IAM policies (least privilege)
- ✅ Database user permissions (read/write staging + execute procedures)
- ✅ Audit timestamps on all DW records

### OCI Infrastructure (Hard-Coded)
- **Database**: `oax4504110443_low` (Chicago)
- **Region**: `us-chicago-1`
- **Vault**: OCI Vault for secret management
- **Container Registry**: OCI Registry for image storage

---

## Key Metrics & Performance

### Data Volume
- **MOLO**: 48 tables, ~500K+ records
- **Stellar**: 29 tables, ~200K+ records
- **Total**: 77 tables, ~700K+ records loaded daily

### Processing Efficiency
- **Staging Load**: 50-100K records/minute
- **MERGE Operations**: Sub-second per table
- **Full Refresh**: 40-60 minutes end-to-end
- **Incremental Updates**: 5-10 minutes

### View Performance
- **Daily Analytics Views**: Real-time (sub-second query)
- **Financial Views**: Live GL integration (no lag)
- **Composite Views**: <2 second response time

---

## Deployment Architecture

### Local Development
```
config.json → Python Scripts → Oracle Autonomous DB (remote)
```

### Production (OCI)
```
Docker Container → OCI Container Instance → Oracle DB
  ↓                    ↓
  ├─ Wallet           ├─ Scheduled execution
  ├─ Code             ├─ Auto-restart on failure
  ├─ Dependencies     └─ Logging to OCI Logging
```

### Scheduling
- ETL runs on schedule (daily/hourly/on-demand)
- Email notifications on success/failure
- Error logs saved to file

---

## Use Cases & Business Value

### Marina Operations (MOLO)
- 📊 Real-time slip occupancy dashboard
- 💰 Revenue analysis by slip type/rate
- 📈 Seasonal demand forecasting
- 🎯 Pricing optimization analysis

### Boat Rental Operations (Stellar)
- 📅 Daily booking volume tracking
- 🚤 Boat utilization rate analytics
- 💵 Revenue per boat/location metrics
- 👥 Customer booking patterns

### Financial Reporting (NetSuite)
- 🏦 Daily cash position
- 📋 A/R and A/P aging
- 🧾 GL reconciliation
- 📊 Financial statement automation

---

## Key Advantages

✅ **Unified Data Model**: MOLO + Stellar + NetSuite in single warehouse  
✅ **Automated Refresh**: Full refresh <1 hour, no manual intervention  
✅ **Scalable Architecture**: Easily add new tables/views  
✅ **Data Quality**: Validation framework for CSV integrity  
✅ **Real-time Analytics**: Views updated with each ETL run  
✅ **Audit Trail**: INSERTED_DATE / UPDATED_DATE on all records  
✅ **Error Resilience**: Detailed logging, email alerts, rollback on failure  
✅ **Cloud-Native**: Serverless execution on OCI Container Instances  

---

## Future Enhancements

- 🚀 **Incremental Loads**: Track only changed records (vs full refresh)
- ⚡ **Parallel Processing**: Load MOLO + Stellar simultaneously
- 🔔 **Advanced Alerting**: Data quality checks, anomaly detection
- 📊 **Power BI Integration**: Direct connection to semantic models
- 🤖 **ML Pipeline**: Forecasting, anomaly detection
- 📱 **Mobile Dashboards**: Real-time KPI tracking

---

## Questions to Prepare For

**Q: What happens if S3 upload is delayed?**  
A: ETL waits at configured retry interval; can trigger manually on-demand

**Q: How do you handle schema changes?**  
A: Update table DDL in `tables/` folder, redeploy procedures, run ETL

**Q: What's the RPO (Recovery Point Objective)?**  
A: 24 hours (daily backups); incremental approach can reduce to 1 hour

**Q: Can MOLO and Stellar run independently?**  
A: Yes - `--process-molo` or `--process-stellar` flags available

**Q: How is the wallet secured?**  
A: Stored in OCI Vault, injected at runtime, never in code

**Q: Do merges support soft deletes?**  
A: Current: No (full refresh). Future: Yes (with change data capture)

---

## Summary Slide

**Marina Data ETL Pipeline**
- **Scope**: 2 source systems + Financial GL
- **Scale**: 77 tables + 21 views, 700K+ daily records
- **Speed**: <1 hour full refresh
- **Security**: Encrypted credentials, wallet auth, audit trails
- **Reliability**: Automated with email alerts
- **Value**: Unified analytics for ops, finance, and executive reporting

**Status**: ✅ Production-ready, running daily
