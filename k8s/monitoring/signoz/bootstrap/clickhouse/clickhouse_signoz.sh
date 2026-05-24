#!/bin/bash

# ==========================================
# Bash Strict Mode
# ==========================================
set -euo pipefail

# ==========================================
# Configuration & Dynamic Arguments
# ==========================================
OUTPUT_FILE="./schema/01_clickhouse_signoz_dump.sql"

# Environment Variables
CLUSTER="${CLICKHOUSE_CLUSTER:-'{cluster}'}"

# Regex Definitions
DB_REGEX="^(signoz_.+)$"
TABLE_DATA_REGEX="^(distributed_schema_migrations.*|distributed_column_evolution_metadata)$"

# Safely capture the first argument, default to 'load' if not provided
MODE="${1:-load}" 

# Build the base client arguments dynamically
CH_ARGS=()
[ -n "${CLICKHOUSE_HOST:-}" ]     && CH_ARGS+=("-h" "$CLICKHOUSE_HOST")
[ -n "${CLICKHOUSE_PORT:-}" ]     && CH_ARGS+=("--port" "$CLICKHOUSE_PORT")
[ -n "${CLICKHOUSE_USER:-}" ]     && CH_ARGS+=("-u" "$CLICKHOUSE_USER")
[ -n "${CLICKHOUSE_PASSWORD:-}" ] && CH_ARGS+=("--password" "$CLICKHOUSE_PASSWORD")

# ==========================================
# Helper Functions
# ==========================================

ch_client() {
    clickhouse-client "${CH_ARGS[@]}" "$@"
}

# ==========================================
# Core Logic: Dump
# ==========================================
do_dump() {
    echo "Starting ClickHouse dump to $OUTPUT_FILE..."
    echo "Using connection arguments: ${CH_ARGS[*]:-(Client Defaults)}"

    if [ -n "$CLUSTER" ]; then
        echo "Mode: Cluster Export (Injecting ON CLUSTER '$CLUSTER')"
    fi

    # Initialize/clear the output file
    > "$OUTPUT_FILE"
    echo "-- ==========================================" >> "$OUTPUT_FILE"
    echo "-- ClickHouse Schema and Data Dump" >> "$OUTPUT_FILE"
    echo "-- Generated: $(date)" >> "$OUTPUT_FILE"
    echo "-- ==========================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    set +e
    DATABASES=$(ch_client -q "SHOW DATABASES" | grep -E "$DB_REGEX")
    GREP_STATUS=$?
    set -e

    if [ $GREP_STATUS -ne 0 ] || [ -z "$DATABASES" ]; then
        echo "No databases found matching regex: $DB_REGEX"
        exit 0
    fi

    for DB in $DATABASES; do
        echo "Processing database: $DB"
        echo "-- ==========================================" >> "$OUTPUT_FILE"
        echo "-- DATABASE: $DB" >> "$OUTPUT_FILE"
        echo "-- ==========================================" >> "$OUTPUT_FILE"
        
        # 1. Dump Database Schema
        RAW_DB_DDL=$(ch_client --format="TabSeparatedRaw" -q "SHOW CREATE DATABASE \`$DB\`")
        
        if [ -n "$CLUSTER" ]; then
            CLEAN_DB_DDL=$(echo "$RAW_DB_DDL" | sed -E 's/^(CREATE[a-zA-Z ]+ (`[^`]+`|[^ ]+))/\1 ON CLUSTER '"'${CLUSTER}'"'/i')
            CLEAN_DB_DDL=$(echo "$CLEAN_DB_DDL" | sed -E 's/^(ENGINE = Distributed\()'"'cluster'"',/\1'"'${CLUSTER}'"',/i')
        else
            CLEAN_DB_DDL="$RAW_DB_DDL"
        fi
        
        echo "$CLEAN_DB_DDL" >> "$OUTPUT_FILE"
        echo ";" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # 2. Fetch all tables AND their engines to isolate Materialized Views
        TABLES_INFO=$(ch_client -q "SELECT name, engine FROM system.tables WHERE database = '$DB' FORMAT TabSeparated")
        
        NORMAL_TABLES=""
        DISTRIBUTED_TABLES=""
        MATERIALIZED_VIEWS=""
        DATA_TABLES=""

        # Parse the TabSeparated output
        while IFS=$'\t' read -r TABLE ENGINE; do
            [ -z "$TABLE" ] && continue
            
            # Categorize Schemas
            if [ "$ENGINE" == "MaterializedView" ]; then
                MATERIALIZED_VIEWS="$MATERIALIZED_VIEWS $TABLE"
            elif [[ "$TABLE" =~ ^distributed_ ]]; then
                DISTRIBUTED_TABLES="$DISTRIBUTED_TABLES $TABLE"
            else
                NORMAL_TABLES="$NORMAL_TABLES $TABLE"
            fi

            # Categorize Data Extraction
            if [[ "$TABLE" =~ $TABLE_DATA_REGEX ]]; then
                DATA_TABLES="$DATA_TABLES $TABLE"
            fi
        done <<< "$TABLES_INFO"

        # Function to clean and write Table/View DDL
        write_clean_table_ddl() {
            local TARGET_DB=$1
            local TARGET_TABLE=$2
            
            RAW_DDL=$(ch_client --format="TabSeparatedRaw" -q "SHOW CREATE TABLE \`$TARGET_DB\`.\`$TARGET_TABLE\`")
            
            # Target Environment Injection
            if [ -n "$CLUSTER" ]; then
                CLEAN_DDL=$(echo "$RAW_DDL" | sed -E 's/^(CREATE[a-zA-Z ]+ (`[^`]+`|[^ ]+)(\.(`[^`]+`|[^ (]+))?)/\1 ON CLUSTER '"'${CLUSTER}'"'/i')
            else
                CLEAN_DDL="$RAW_DDL"
            fi
            
            echo "$CLEAN_DDL" >> "$OUTPUT_FILE"
            echo ";" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        }

        # Phase 1: Dump Base Schemas
        if [ -n "$NORMAL_TABLES" ]; then
            echo "-- ---> Phase 1: Base Tables" >> "$OUTPUT_FILE"
            for TABLE in $NORMAL_TABLES; do
                echo "  -> Dumping schema: $DB.$TABLE"
                echo "-- Table Schema: $DB.$TABLE" >> "$OUTPUT_FILE"
                write_clean_table_ddl "$DB" "$TABLE"
            done
        fi

        # Phase 2: Dump Dependent (Distributed) Schemas
        if [ -n "$DISTRIBUTED_TABLES" ]; then
            echo "-- ---> Phase 2: Distributed Tables" >> "$OUTPUT_FILE"
            for TABLE in $DISTRIBUTED_TABLES; do
                echo "  -> Dumping schema: $DB.$TABLE"
                echo "-- Table Schema: $DB.$TABLE" >> "$OUTPUT_FILE"
                write_clean_table_ddl "$DB" "$TABLE"
            done
        fi

        # Phase 3: Dump Materialized Views
        if [ -n "$MATERIALIZED_VIEWS" ]; then
            echo "-- ---> Phase 3: Materialized Views" >> "$OUTPUT_FILE"
            for TABLE in $MATERIALIZED_VIEWS; do
                echo "  -> Dumping view: $DB.$TABLE"
                echo "-- View Schema: $DB.$TABLE" >> "$OUTPUT_FILE"
                write_clean_table_ddl "$DB" "$TABLE"
            done
        fi

        # Phase 4: Dump Data Inserts
        if [ -n "$DATA_TABLES" ]; then
            echo "-- ---> Phase 4: Data Inserts" >> "$OUTPUT_FILE"
            for TABLE in $DATA_TABLES; do
                echo "     => Extracting data: $DB.$TABLE"
                echo "-- Table Data: $DB.$TABLE" >> "$OUTPUT_FILE"
                ch_client -q "SELECT * FROM \`$DB\`.\`$TABLE\` SETTINGS output_format_sql_insert_table_name='\`$DB\`.\`$TABLE\`' FORMAT SQLInsert" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            done
        fi
        
        echo "" >> "$OUTPUT_FILE"
    done

    echo "Dump complete. File saved to $OUTPUT_FILE."
}

# ==========================================
# Core Logic: Load
# ==========================================
do_load() {
    echo "Starting ClickHouse load operation..."
    echo "Using connection arguments: ${CH_ARGS[*]:-(Client Defaults)}"

    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "Error: The file '$OUTPUT_FILE' does not exist."
        echo "Please run the script with the 'dump' argument first to generate the file."
        exit 1
    fi

    echo "Loading definitions and data from $OUTPUT_FILE..."
    
    ch_client --multiquery < "$OUTPUT_FILE"

    echo "Load complete."
}

# ==========================================
# Main Execution Router
# ==========================================
case "$MODE" in
    dump)
        do_dump
        ;;
    load)
        do_load
        ;;
    *)
        echo "Error: Invalid argument '$MODE'."
        echo "Usage: $0 [dump|load]"
        echo "Note: If no argument is provided, the script defaults to 'load'."
        exit 1
        ;;
esac
