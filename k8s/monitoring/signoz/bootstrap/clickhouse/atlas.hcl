exporter "sql" "schema_file" {
  path = "schema.sql"
  # split_by = object
  # naming   = lower
  indent   = "  "
}

env "monitoring" {
  url = getenv("DB_URL")
  dev = "docker://clickhouse/23.11"
  export {
    schema {
      inspect = exporter.sql.schema_file
    }
  }
}
