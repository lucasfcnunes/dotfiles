-- ==========================================
-- ClickHouse Schema and Data Dump
-- Generated: 2026-05-26T23:33:29 -03
-- ==========================================

-- ==========================================
-- DATABASE: signoz_analytics
-- ==========================================
CREATE DATABASE signoz_analytics ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_analytics.rule_state_history_v0
CREATE TABLE signoz_analytics.rule_state_history_v0 ON CLUSTER '{cluster}'
(
    `_retention_days` UInt32 DEFAULT 180,
    `rule_id` LowCardinality(String),
    `rule_name` LowCardinality(String),
    `overall_state` LowCardinality(String),
    `overall_state_changed` Bool,
    `state` LowCardinality(String),
    `state_changed` Bool,
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (rule_id, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalDay(_retention_days)
SETTINGS ttl_only_drop_parts = 1, index_granularity = 8192
;

-- Table Schema: signoz_analytics.schema_migrations_v2
CREATE TABLE signoz_analytics.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_analytics.distributed_rule_state_history_v0
CREATE TABLE signoz_analytics.distributed_rule_state_history_v0 ON CLUSTER '{cluster}'
(
    `rule_id` LowCardinality(String),
    `rule_name` LowCardinality(String),
    `overall_state` LowCardinality(String),
    `overall_state_changed` Bool,
    `state` LowCardinality(String),
    `state_changed` Bool,
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5))
)
ENGINE = Distributed('{cluster}', 'signoz_analytics', 'rule_state_history_v0', cityHash64(rule_id, rule_name, fingerprint))
;

-- Table Schema: signoz_analytics.distributed_schema_migrations_v2
CREATE TABLE signoz_analytics.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_analytics', 'schema_migrations_v2', rand())
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_analytics.distributed_schema_migrations_v2
INSERT INTO `signoz_analytics`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1, 'finished', '', '2026-05-26 19:43:15.000000000', '1970-01-01 00:00:00.000000000');


-- ==========================================
-- DATABASE: signoz_logs
-- ==========================================
CREATE DATABASE signoz_logs ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_logs.logs_attribute_keys
CREATE TABLE signoz_logs.logs_attribute_keys ON CLUSTER '{cluster}'
(
    `name` String,
    `datatype` String,
    `timestamp` DateTime DEFAULT toDateTime(now())
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (name, datatype)
TTL timestamp + toIntervalDay(15)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_logs.logs_resource_keys
CREATE TABLE signoz_logs.logs_resource_keys ON CLUSTER '{cluster}'
(
    `name` String,
    `datatype` String,
    `timestamp` DateTime DEFAULT toDateTime(now())
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (name, datatype)
TTL timestamp + toIntervalDay(15)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_logs.logs_v2
CREATE TABLE signoz_logs.logs_v2 ON CLUSTER '{cluster}'
(
    `ts_bucket_start` UInt64 CODEC(DoubleDelta, LZ4),
    `resource_fingerprint` String CODEC(ZSTD(1)),
    `timestamp` UInt64 CODEC(DoubleDelta, LZ4),
    `observed_timestamp` UInt64 CODEC(DoubleDelta, LZ4),
    `id` String CODEC(ZSTD(1)),
    `trace_id` String CODEC(ZSTD(1)),
    `span_id` String CODEC(ZSTD(1)),
    `trace_flags` UInt32,
    `severity_text` LowCardinality(String) CODEC(ZSTD(1)),
    `severity_number` UInt8,
    `body` String CODEC(ZSTD(2)),
    `attributes_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `attributes_number` Map(LowCardinality(String), Float64) CODEC(ZSTD(1)),
    `attributes_bool` Map(LowCardinality(String), Bool) CODEC(ZSTD(1)),
    `resources_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `scope_name` String CODEC(ZSTD(1)),
    `scope_version` String CODEC(ZSTD(1)),
    `scope_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `_retention_days` UInt16 DEFAULT 15,
    `_retention_days_cold` UInt16 DEFAULT 0,
    `resource` JSON(max_dynamic_paths = 100) CODEC(ZSTD(1)),
    INDEX id_minmax id TYPE minmax GRANULARITY 1,
    INDEX severity_number_idx severity_number TYPE set(25) GRANULARITY 4,
    INDEX severity_text_idx severity_text TYPE set(25) GRANULARITY 4,
    INDEX trace_flags_idx trace_flags TYPE bloom_filter GRANULARITY 4,
    INDEX body_index_v2_token lower(body) TYPE tokenbf_v1(10000, 2, 0) GRANULARITY 1,
    INDEX body_index_v2_ngram lower(body) TYPE ngrambf_v1(4, 15000, 3, 0) GRANULARITY 1,
    INDEX scope_name_idx scope_name TYPE tokenbf_v1(10240, 3, 0) GRANULARITY 4,
    INDEX attributes_string_idx_key mapKeys(attributes_string) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX attributes_string_idx_val mapValues(attributes_string) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    INDEX attributes_number_idx_key mapKeys(attributes_number) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX attributes_number_idx_val mapValues(attributes_number) TYPE bloom_filter GRANULARITY 1,
    INDEX attributes_bool_idx_key mapKeys(attributes_bool) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX trace_id_idx trace_id TYPE tokenbf_v1(10000, 5, 0) GRANULARITY 1,
    INDEX span_id_idx span_id TYPE tokenbf_v1(5000, 5, 0) GRANULARITY 1
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY (toDate(timestamp / 1000000000), _retention_days, _retention_days_cold)
ORDER BY (ts_bucket_start, resource_fingerprint, severity_text, timestamp, id)
TTL toDateTime(timestamp / 1000000000) + toIntervalDay(_retention_days)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_logs.logs_v2_resource
CREATE TABLE signoz_logs.logs_v2_resource ON CLUSTER '{cluster}'
(
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` String CODEC(ZSTD(1)),
    `seen_at_ts_bucket_start` Int64 CODEC(Delta(8), ZSTD(1)),
    `_retention_days` UInt16 DEFAULT 15,
    `_retention_days_cold` UInt16 DEFAULT 0,
    INDEX idx_labels lower(labels) TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1,
    INDEX idx_labels_v1 labels TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY (toDate(seen_at_ts_bucket_start), _retention_days, _retention_days_cold)
ORDER BY (labels, fingerprint, seen_at_ts_bucket_start)
TTL (toDateTime(seen_at_ts_bucket_start) + toIntervalDay(_retention_days)) + toIntervalSecond(1800)
SETTINGS ttl_only_drop_parts = 1, index_granularity = 8192
;

-- Table Schema: signoz_logs.schema_migrations_v2
CREATE TABLE signoz_logs.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_logs.tag_attributes_v2
CREATE TABLE signoz_logs.tag_attributes_v2 ON CLUSTER '{cluster}'
(
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `tag_key` String CODEC(ZSTD(1)),
    `tag_type` LowCardinality(String) CODEC(ZSTD(1)),
    `tag_data_type` LowCardinality(String) CODEC(ZSTD(1)),
    `string_value` String CODEC(ZSTD(1)),
    `number_value` Nullable(Float64) CODEC(ZSTD(1)),
    INDEX string_value_index string_value TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1,
    INDEX number_value_index number_value TYPE minmax GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (tag_key, tag_type, tag_data_type, string_value, number_value)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, allow_nullable_key = 1
;

-- Table Schema: signoz_logs.usage
CREATE TABLE signoz_logs.usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tenant, collector_id, exporter_id, timestamp)
TTL timestamp + toIntervalDay(3)
SETTINGS index_granularity = 8192
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_logs.distributed_logs_attribute_keys
CREATE TABLE signoz_logs.distributed_logs_attribute_keys ON CLUSTER '{cluster}'
(
    `name` String,
    `datatype` String
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'logs_attribute_keys', cityHash64(datatype))
;

-- Table Schema: signoz_logs.distributed_logs_resource_keys
CREATE TABLE signoz_logs.distributed_logs_resource_keys ON CLUSTER '{cluster}'
(
    `name` String,
    `datatype` String
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'logs_resource_keys', cityHash64(datatype))
;

-- Table Schema: signoz_logs.distributed_logs_v2
CREATE TABLE signoz_logs.distributed_logs_v2 ON CLUSTER '{cluster}'
(
    `ts_bucket_start` UInt64 CODEC(DoubleDelta, LZ4),
    `resource_fingerprint` String CODEC(ZSTD(1)),
    `timestamp` UInt64 CODEC(DoubleDelta, LZ4),
    `observed_timestamp` UInt64 CODEC(DoubleDelta, LZ4),
    `id` String CODEC(ZSTD(1)),
    `trace_id` String CODEC(ZSTD(1)),
    `span_id` String CODEC(ZSTD(1)),
    `trace_flags` UInt32,
    `severity_text` LowCardinality(String) CODEC(ZSTD(1)),
    `severity_number` UInt8,
    `body` String CODEC(ZSTD(2)),
    `attributes_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `attributes_number` Map(LowCardinality(String), Float64) CODEC(ZSTD(1)),
    `attributes_bool` Map(LowCardinality(String), Bool) CODEC(ZSTD(1)),
    `resources_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `scope_name` String CODEC(ZSTD(1)),
    `scope_version` String CODEC(ZSTD(1)),
    `scope_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `_retention_days` UInt16 DEFAULT 15,
    `_retention_days_cold` UInt16 DEFAULT 0,
    `resource` JSON(max_dynamic_paths = 100) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'logs_v2', cityHash64(id))
;

-- Table Schema: signoz_logs.distributed_logs_v2_resource
CREATE TABLE signoz_logs.distributed_logs_v2_resource ON CLUSTER '{cluster}'
(
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` String CODEC(ZSTD(1)),
    `seen_at_ts_bucket_start` Int64 CODEC(Delta(8), ZSTD(1)),
    `_retention_days` UInt16 DEFAULT 15,
    `_retention_days_cold` UInt16 DEFAULT 0
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'logs_v2_resource', cityHash64(labels, fingerprint))
;

-- Table Schema: signoz_logs.distributed_schema_migrations_v2
CREATE TABLE signoz_logs.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'schema_migrations_v2', rand())
;

-- Table Schema: signoz_logs.distributed_tag_attributes_v2
CREATE TABLE signoz_logs.distributed_tag_attributes_v2 ON CLUSTER '{cluster}'
(
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `tag_key` String CODEC(ZSTD(1)),
    `tag_type` LowCardinality(String) CODEC(ZSTD(1)),
    `tag_data_type` LowCardinality(String) CODEC(ZSTD(1)),
    `string_value` String CODEC(ZSTD(1)),
    `number_value` Nullable(Float64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'tag_attributes_v2', cityHash64(rand()))
;

-- Table Schema: signoz_logs.distributed_usage
CREATE TABLE signoz_logs.distributed_usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_logs', 'usage', cityHash64(rand()))
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_logs.distributed_schema_migrations_v2
INSERT INTO `signoz_logs`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1, 'finished', '', '2026-05-26 19:39:28.000000000', '1970-01-01 00:00:00.000000000'), (2, 'finished', '', '2026-05-26 19:39:30.000000000', '1970-01-01 00:00:00.000000000'), (3, 'finished', '', '2026-05-26 19:39:32.000000000', '1970-01-01 00:00:00.000000000'), (4, 'finished', '', '2026-05-26 19:39:33.000000000', '1970-01-01 00:00:00.000000000'), (5, 'finished', '', '2026-05-26 19:39:35.000000000', '1970-01-01 00:00:00.000000000'), (6, 'finished', '', '2026-05-26 19:39:36.000000000', '1970-01-01 00:00:00.000000000'), (7, 'finished', '', '2026-05-26 19:39:38.000000000', '1970-01-01 00:00:00.000000000'), (8, 'finished', '', '2026-05-26 19:39:39.000000000', '1970-01-01 00:00:00.000000000'), (9, 'finished', '', '2026-05-26 19:39:41.000000000', '1970-01-01 00:00:00.000000000'), (1000, 'finished', '', '2026-05-26 19:43:46.000000000', '1970-01-01 00:00:00.000000000'), (1001, 'finished', '', '2026-05-26 19:41:16.000000000', '1970-01-01 00:00:00.000000000'), (1002, 'finished', '', '2026-05-26 19:41:23.000000000', '1970-01-01 00:00:00.000000000'), (1003, 'finished', '', '2026-05-26 19:43:50.000000000', '1970-01-01 00:00:00.000000000'), (1004, 'finished', '', '2026-05-26 19:41:25.000000000', '1970-01-01 00:00:00.000000000'), (1005, 'finished', '', '2026-05-26 19:41:29.000000000', '1970-01-01 00:00:00.000000000');


-- ==========================================
-- DATABASE: signoz_metadata
-- ==========================================
CREATE DATABASE signoz_metadata ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_metadata.attributes_metadata
CREATE TABLE signoz_metadata.attributes_metadata ON CLUSTER '{cluster}'
(
    `unix_milli` UInt64,
    `data_source` String,
    `resource_fingerprint` UInt64,
    `attrs_fingerprint` UInt64,
    `resource_attributes` Map(LowCardinality(String), String),
    `attributes` Map(LowCardinality(String), String),
    INDEX idx_resource_attributes_map_keys mapKeys(resource_attributes) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_attributes_map_keys mapKeys(attributes) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_resource_attributes_map_values mapValues(resource_attributes) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    INDEX idx_attributes_map_values mapValues(attributes) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (data_source, unix_milli, resource_fingerprint, attrs_fingerprint)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS ttl_only_drop_parts = 1, index_granularity = 8192
;

-- Table Schema: signoz_metadata.column_evolution_metadata
CREATE TABLE signoz_metadata.column_evolution_metadata ON CLUSTER '{cluster}'
(
    `signal` String CODEC(ZSTD(1)),
    `column_name` String CODEC(ZSTD(1)),
    `column_type` String CODEC(ZSTD(1)),
    `field_context` String CODEC(ZSTD(1)),
    `field_name` String CODEC(ZSTD(1)),
    `version` UInt32 CODEC(DoubleDelta, ZSTD(1)),
    `release_time` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(release_time / 1000000000)
ORDER BY (signal, column_name, column_type, field_context, field_name, version)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_metadata.schema_migrations_v2
CREATE TABLE signoz_metadata.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_metadata.distributed_attributes_metadata
CREATE TABLE signoz_metadata.distributed_attributes_metadata ON CLUSTER '{cluster}'
(
    `unix_milli` UInt64,
    `data_source` String,
    `resource_fingerprint` UInt64,
    `attrs_fingerprint` UInt64,
    `resource_attributes` Map(LowCardinality(String), String),
    `attributes` Map(LowCardinality(String), String)
)
ENGINE = Distributed('{cluster}', 'signoz_metadata', 'attributes_metadata', cityHash64(data_source, resource_fingerprint, attrs_fingerprint))
;

-- Table Schema: signoz_metadata.distributed_column_evolution_metadata
CREATE TABLE signoz_metadata.distributed_column_evolution_metadata ON CLUSTER '{cluster}'
(
    `signal` String CODEC(ZSTD(1)),
    `column_name` String CODEC(ZSTD(1)),
    `column_type` String CODEC(ZSTD(1)),
    `field_context` String CODEC(ZSTD(1)),
    `field_name` String CODEC(ZSTD(1)),
    `version` UInt32 CODEC(DoubleDelta, ZSTD(1)),
    `release_time` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metadata', 'column_evolution_metadata', cityHash64(signal, column_name))
;

-- Table Schema: signoz_metadata.distributed_schema_migrations_v2
CREATE TABLE signoz_metadata.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_metadata', 'schema_migrations_v2', rand())
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_metadata.distributed_column_evolution_metadata
INSERT INTO `signoz_metadata`.`distributed_column_evolution_metadata` (`signal`, `column_name`, `column_type`, `field_context`, `field_name`, `version`, `release_time`) VALUES ('logs', 'resource', 'JSON()', 'resource', '__all__', 1, 1779824366851647200), ('traces', 'resource', 'JSON()', 'resource', '__all__', 1, 1779824366851648800), ('logs', 'resources_string', 'Map(LowCardinality(String), Float64)', 'resource', '__all__', 0, 0), ('traces', 'resources_string', 'Map(LowCardinality(String), Float64)', 'resource', '__all__', 0, 0);

-- Table Data: signoz_metadata.distributed_schema_migrations_v2
INSERT INTO `signoz_metadata`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1000, 'finished', '', '2026-05-26 19:43:04.000000000', '1970-01-01 00:00:00.000000000'), (1001, 'finished', '', '2026-05-26 19:43:12.000000000', '1970-01-01 00:00:00.000000000');


-- ==========================================
-- DATABASE: signoz_meter
-- ==========================================
CREATE DATABASE signoz_meter ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_meter.samples
CREATE TABLE signoz_meter.samples ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT 'default',
    `unit` LowCardinality(String) DEFAULT 'default',
    `type` LowCardinality(String) DEFAULT 'default',
    `is_monotonic` Bool DEFAULT false,
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toYYYYMM(toDateTime(intDiv(unix_milli, 1000)))
ORDER BY (temporality, metric_name, fingerprint, toDayOfMonth(toDateTime(intDiv(unix_milli, 1000))))
TTL toDateTime(intDiv(unix_milli, 1000)) + toIntervalYear(1)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_meter.samples_agg_1d
CREATE TABLE signoz_meter.samples_agg_1d ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT 'default',
    `unit` LowCardinality(String) DEFAULT 'default',
    `type` LowCardinality(String) DEFAULT 'default',
    `is_monotonic` Bool DEFAULT false,
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toYYYYMM(toDateTime(intDiv(unix_milli, 1000)))
ORDER BY (temporality, metric_name, fingerprint, toDayOfMonth(toDateTime(intDiv(unix_milli, 1000))))
TTL toDateTime(intDiv(unix_milli, 1000)) + toIntervalYear(1)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_meter.schema_migrations_v2
CREATE TABLE signoz_meter.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_meter.distributed_samples
CREATE TABLE signoz_meter.distributed_samples ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT 'default',
    `unit` LowCardinality(String) DEFAULT 'default',
    `type` LowCardinality(String) DEFAULT 'default',
    `is_monotonic` Bool DEFAULT false,
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_meter', 'samples', cityHash64(temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_meter.distributed_samples_agg_1d
CREATE TABLE signoz_meter.distributed_samples_agg_1d ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT 'default',
    `unit` LowCardinality(String) DEFAULT 'default',
    `type` LowCardinality(String) DEFAULT 'default',
    `is_monotonic` Bool DEFAULT false,
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_meter', 'samples_agg_1d', cityHash64(temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_meter.distributed_schema_migrations_v2
CREATE TABLE signoz_meter.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_meter', 'schema_migrations_v2', rand())
;

-- ---> Phase 3: Materialized Views
-- View Schema: signoz_meter.samples_agg_1d_mv
CREATE MATERIALIZED VIEW signoz_meter.samples_agg_1d_mv ON CLUSTER '{cluster}' TO signoz_meter.samples_agg_1d
(
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT 'default',
    `unit` LowCardinality(String) DEFAULT 'default',
    `type` LowCardinality(String) DEFAULT 'default',
    `is_monotonic` Bool DEFAULT false,
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
AS SELECT
    temporality,
    metric_name,
    description,
    unit,
    type,
    is_monotonic,
    labels,
    fingerprint,
    intDiv(unix_milli, 86400000) * 86400000 AS unix_milli,
    anyLast(value) AS last,
    min(value) AS min,
    max(value) AS max,
    sum(value) AS sum,
    count(*) AS count
FROM signoz_meter.samples
GROUP BY
    temporality,
    metric_name,
    fingerprint,
    description,
    unit,
    type,
    is_monotonic,
    labels,
    unix_milli
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_meter.distributed_schema_migrations_v2
INSERT INTO `signoz_meter`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1, 'finished', '', '2026-05-26 19:43:17.000000000', '1970-01-01 00:00:00.000000000'), (2, 'finished', '', '2026-05-26 19:43:19.000000000', '1970-01-01 00:00:00.000000000'), (3, 'finished', '', '2026-05-26 19:43:21.000000000', '1970-01-01 00:00:00.000000000'), (4, 'finished', '', '2026-05-26 19:43:22.000000000', '1970-01-01 00:00:00.000000000'), (5, 'finished', '', '2026-05-26 19:43:24.000000000', '1970-01-01 00:00:00.000000000');


-- ==========================================
-- DATABASE: signoz_metrics
-- ==========================================
CREATE DATABASE signoz_metrics ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_metrics.exp_hist
CREATE TABLE signoz_metrics.exp_hist ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `count` UInt64 CODEC(ZSTD(1)),
    `sum` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `min` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `max` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `sketch` AggregateFunction(quantilesDD(0.01, 0.5, 0.75, 0.9, 0.95, 0.99), UInt64) CODEC(ZSTD(1)),
    `flags` UInt32 DEFAULT 0 CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.metadata
CREATE TABLE signoz_metrics.metadata ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) CODEC(ZSTD(1)),
    `metric_name` LowCardinality(String) CODEC(ZSTD(1)),
    `description` String CODEC(ZSTD(1)),
    `unit` LowCardinality(String) CODEC(ZSTD(1)),
    `type` LowCardinality(String) CODEC(ZSTD(1)),
    `is_monotonic` Bool CODEC(ZSTD(1)),
    `attr_name` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_type` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_datatype` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_string_value` String CODEC(ZSTD(1)),
    `first_reported_unix_milli` SimpleAggregateFunction(min, UInt64) CODEC(ZSTD(1)),
    `last_reported_unix_milli` SimpleAggregateFunction(max, UInt64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(last_reported_unix_milli / 1000)
ORDER BY (temporality, metric_name, attr_name, attr_type, attr_datatype, attr_string_value)
TTL toDateTime(last_reported_unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS ttl_only_drop_parts = 1, index_granularity = 8192
;

-- Table Schema: signoz_metrics.samples_v2
CREATE TABLE signoz_metrics.samples_v2 ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `timestamp_ms` Int64 CODEC(DoubleDelta, LZ4),
    `value` Float64 CODEC(Gorilla(8), LZ4)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp_ms / 1000)
ORDER BY (metric_name, fingerprint, timestamp_ms)
TTL toDateTime(timestamp_ms / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.samples_v4
CREATE TABLE signoz_metrics.samples_v4 ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `flags` UInt32 DEFAULT 0 CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.samples_v4_agg_30m
CREATE TABLE signoz_metrics.samples_v4_agg_30m ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.samples_v4_agg_5m
CREATE TABLE signoz_metrics.samples_v4_agg_5m ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.schema_migrations_v2
CREATE TABLE signoz_metrics.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_metrics.time_series_v2
CREATE TABLE signoz_metrics.time_series_v2 ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `timestamp_ms` Int64 CODEC(DoubleDelta, LZ4),
    `labels` String CODEC(ZSTD(5)),
    `temporality` LowCardinality(String) DEFAULT 'Unspecified' CODEC(ZSTD(5)),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    INDEX temporality_index temporality TYPE SET(3) GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp_ms / 1000)
ORDER BY (metric_name, fingerprint)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_metrics.time_series_v4
CREATE TABLE signoz_metrics.time_series_v4 ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.time_series_v4_1day
CREATE TABLE signoz_metrics.time_series_v4_1day ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.time_series_v4_1week
CREATE TABLE signoz_metrics.time_series_v4_1week ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.time_series_v4_6hrs
CREATE TABLE signoz_metrics.time_series_v4_6hrs ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (env, temporality, metric_name, fingerprint, unix_milli)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(2592000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_metrics.updated_metadata
CREATE TABLE signoz_metrics.updated_metadata ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String) CODEC(ZSTD(1)),
    `temporality` LowCardinality(String) CODEC(ZSTD(1)),
    `is_monotonic` Bool CODEC(ZSTD(1)),
    `type` LowCardinality(String) CODEC(ZSTD(1)),
    `description` LowCardinality(String) CODEC(ZSTD(1)),
    `unit` LowCardinality(String) CODEC(ZSTD(1)),
    `created_at` Int64 CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY metric_name
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_metrics.usage
CREATE TABLE signoz_metrics.usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tenant, collector_id, exporter_id, timestamp)
TTL timestamp + toIntervalDay(3)
SETTINGS index_granularity = 8192
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_metrics.distributed_exp_hist
CREATE TABLE signoz_metrics.distributed_exp_hist ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `count` UInt64 CODEC(ZSTD(1)),
    `sum` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `min` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `max` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `sketch` AggregateFunction(quantilesDD(0.01, 0.5, 0.75, 0.9, 0.95, 0.99), UInt64) CODEC(ZSTD(1)),
    `flags` UInt32 DEFAULT 0 CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'exp_hist', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_metadata
CREATE TABLE signoz_metrics.distributed_metadata ON CLUSTER '{cluster}'
(
    `temporality` LowCardinality(String) CODEC(ZSTD(1)),
    `metric_name` LowCardinality(String) CODEC(ZSTD(1)),
    `description` String CODEC(ZSTD(1)),
    `unit` LowCardinality(String) CODEC(ZSTD(1)),
    `type` LowCardinality(String) CODEC(ZSTD(1)),
    `is_monotonic` Bool CODEC(ZSTD(1)),
    `attr_name` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_type` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_datatype` LowCardinality(String) CODEC(ZSTD(1)),
    `attr_string_value` String CODEC(ZSTD(1)),
    `first_reported_unix_milli` SimpleAggregateFunction(min, UInt64) CODEC(ZSTD(1)),
    `last_reported_unix_milli` SimpleAggregateFunction(max, UInt64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'metadata', rand())
;

-- Table Schema: signoz_metrics.distributed_samples_v2
CREATE TABLE signoz_metrics.distributed_samples_v2 ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `timestamp_ms` Int64 CODEC(DoubleDelta, LZ4),
    `value` Float64 CODEC(Gorilla(8), LZ4)
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'samples_v2', cityHash64(metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_samples_v4
CREATE TABLE signoz_metrics.distributed_samples_v4 ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `value` Float64 CODEC(Gorilla(8), ZSTD(1)),
    `flags` UInt32 DEFAULT 0 CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'samples_v4', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_samples_v4_agg_30m
CREATE TABLE signoz_metrics.distributed_samples_v4_agg_30m ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'samples_v4_agg_30m', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_samples_v4_agg_5m
CREATE TABLE signoz_metrics.distributed_samples_v4_agg_5m ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `last` SimpleAggregateFunction(anyLast, Float64) CODEC(ZSTD(1)),
    `min` SimpleAggregateFunction(min, Float64) CODEC(ZSTD(1)),
    `max` SimpleAggregateFunction(max, Float64) CODEC(ZSTD(1)),
    `sum` SimpleAggregateFunction(sum, Float64) CODEC(ZSTD(1)),
    `count` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'samples_v4_agg_5m', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_schema_migrations_v2
CREATE TABLE signoz_metrics.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'schema_migrations_v2', rand())
;

-- Table Schema: signoz_metrics.distributed_time_series_v2
CREATE TABLE signoz_metrics.distributed_time_series_v2 ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64 CODEC(ZSTD(1)),
    `timestamp_ms` Int64 CODEC(DoubleDelta, LZ4),
    `labels` String CODEC(ZSTD(5)),
    `temporality` LowCardinality(String) DEFAULT 'Unspecified' CODEC(ZSTD(5)),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'time_series_v2', cityHash64(metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_time_series_v4
CREATE TABLE signoz_metrics.distributed_time_series_v4 ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1)),
    `inserted_at_unix_milli` Int64 CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'time_series_v4', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_time_series_v4_1day
CREATE TABLE signoz_metrics.distributed_time_series_v4_1day ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'time_series_v4_1day', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_time_series_v4_1week
CREATE TABLE signoz_metrics.distributed_time_series_v4_1week ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'time_series_v4_1week', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_time_series_v4_6hrs
CREATE TABLE signoz_metrics.distributed_time_series_v4_6hrs ON CLUSTER '{cluster}'
(
    `env` LowCardinality(String) DEFAULT 'default',
    `temporality` LowCardinality(String) DEFAULT 'Unspecified',
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `unit` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `type` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `is_monotonic` Bool DEFAULT false CODEC(ZSTD(1)),
    `fingerprint` UInt64 CODEC(Delta(8), ZSTD(1)),
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `labels` String CODEC(ZSTD(5)),
    `attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `scope_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `resource_attrs` Map(LowCardinality(String), String) DEFAULT map() CODEC(ZSTD(1)),
    `__normalized` Bool DEFAULT true CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'time_series_v4_6hrs', cityHash64(env, temporality, metric_name, fingerprint))
;

-- Table Schema: signoz_metrics.distributed_updated_metadata
CREATE TABLE signoz_metrics.distributed_updated_metadata ON CLUSTER '{cluster}'
(
    `metric_name` LowCardinality(String) CODEC(ZSTD(1)),
    `temporality` LowCardinality(String) CODEC(ZSTD(1)),
    `is_monotonic` Bool CODEC(ZSTD(1)),
    `type` LowCardinality(String) CODEC(ZSTD(1)),
    `description` LowCardinality(String) CODEC(ZSTD(1)),
    `unit` LowCardinality(String) CODEC(ZSTD(1)),
    `created_at` Int64 CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'updated_metadata', cityHash64(metric_name))
;

-- Table Schema: signoz_metrics.distributed_usage
CREATE TABLE signoz_metrics.distributed_usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_metrics', 'usage', cityHash64(rand()))
;

-- ---> Phase 3: Materialized Views
-- View Schema: signoz_metrics.samples_v4_agg_30m_mv
CREATE MATERIALIZED VIEW signoz_metrics.samples_v4_agg_30m_mv ON CLUSTER '{cluster}' TO signoz_metrics.samples_v4_agg_30m
(
    `env` LowCardinality(String),
    `temporality` LowCardinality(String),
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64,
    `unix_milli` Int64,
    `last` SimpleAggregateFunction(anyLast, Float64),
    `min` SimpleAggregateFunction(min, Float64),
    `max` SimpleAggregateFunction(max, Float64),
    `sum` Float64,
    `count` UInt64
)
AS SELECT
    env,
    temporality,
    metric_name,
    fingerprint,
    intDiv(unix_milli, 1800000) * 1800000 AS unix_milli,
    anyLast(last) AS last,
    min(min) AS min,
    max(max) AS max,
    sum(sum) AS sum,
    sum(count) AS count
FROM signoz_metrics.samples_v4_agg_5m
GROUP BY
    env,
    temporality,
    metric_name,
    fingerprint,
    unix_milli
;

-- View Schema: signoz_metrics.samples_v4_agg_5m_mv
CREATE MATERIALIZED VIEW signoz_metrics.samples_v4_agg_5m_mv ON CLUSTER '{cluster}' TO signoz_metrics.samples_v4_agg_5m
(
    `env` LowCardinality(String),
    `temporality` LowCardinality(String),
    `metric_name` LowCardinality(String),
    `fingerprint` UInt64,
    `unix_milli` Int64,
    `last` Float64,
    `min` Float64,
    `max` Float64,
    `sum` Float64,
    `count` UInt64
)
AS SELECT
    env,
    temporality,
    metric_name,
    fingerprint,
    intDiv(unix_milli, 300000) * 300000 AS unix_milli,
    anyLast(value) AS last,
    min(value) AS min,
    max(value) AS max,
    sum(value) AS sum,
    count(*) AS count
FROM signoz_metrics.samples_v4
WHERE bitAnd(flags, 1) = 0
GROUP BY
    env,
    temporality,
    metric_name,
    fingerprint,
    unix_milli
;

-- View Schema: signoz_metrics.time_series_v4_1day_mv
CREATE MATERIALIZED VIEW signoz_metrics.time_series_v4_1day_mv ON CLUSTER '{cluster}' TO signoz_metrics.time_series_v4_1day
(
    `env` LowCardinality(String),
    `temporality` LowCardinality(String),
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String),
    `unit` LowCardinality(String),
    `type` LowCardinality(String),
    `is_monotonic` Bool,
    `fingerprint` UInt64,
    `unix_milli` Float64,
    `labels` String,
    `attrs` Map(LowCardinality(String), String),
    `scope_attrs` Map(LowCardinality(String), String),
    `resource_attrs` Map(LowCardinality(String), String),
    `__normalized` Bool
)
AS SELECT
    env,
    temporality,
    metric_name,
    description,
    unit,
    type,
    is_monotonic,
    fingerprint,
    floor(unix_milli / 86400000) * 86400000 AS unix_milli,
    labels,
    attrs,
    scope_attrs,
    resource_attrs,
    __normalized
FROM signoz_metrics.time_series_v4_6hrs
;

-- View Schema: signoz_metrics.time_series_v4_1week_mv
CREATE MATERIALIZED VIEW signoz_metrics.time_series_v4_1week_mv ON CLUSTER '{cluster}' TO signoz_metrics.time_series_v4_1week
(
    `env` LowCardinality(String),
    `temporality` LowCardinality(String),
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String),
    `unit` LowCardinality(String),
    `type` LowCardinality(String),
    `is_monotonic` Bool,
    `fingerprint` UInt64,
    `unix_milli` Float64,
    `labels` String,
    `attrs` Map(LowCardinality(String), String),
    `scope_attrs` Map(LowCardinality(String), String),
    `resource_attrs` Map(LowCardinality(String), String),
    `__normalized` Bool
)
AS SELECT
    env,
    temporality,
    metric_name,
    description,
    unit,
    type,
    is_monotonic,
    fingerprint,
    floor(unix_milli / 604800000) * 604800000 AS unix_milli,
    labels,
    attrs,
    scope_attrs,
    resource_attrs,
    __normalized
FROM signoz_metrics.time_series_v4_1day
;

-- View Schema: signoz_metrics.time_series_v4_6hrs_mv
CREATE MATERIALIZED VIEW signoz_metrics.time_series_v4_6hrs_mv ON CLUSTER '{cluster}' TO signoz_metrics.time_series_v4_6hrs
(
    `env` LowCardinality(String),
    `temporality` LowCardinality(String),
    `metric_name` LowCardinality(String),
    `description` LowCardinality(String),
    `unit` LowCardinality(String),
    `type` LowCardinality(String),
    `is_monotonic` Bool,
    `fingerprint` UInt64,
    `unix_milli` Float64,
    `labels` String,
    `attrs` Map(LowCardinality(String), String),
    `scope_attrs` Map(LowCardinality(String), String),
    `resource_attrs` Map(LowCardinality(String), String),
    `__normalized` Bool
)
AS SELECT
    env,
    temporality,
    metric_name,
    description,
    unit,
    type,
    is_monotonic,
    fingerprint,
    floor(unix_milli / 21600000) * 21600000 AS unix_milli,
    labels,
    attrs,
    scope_attrs,
    resource_attrs,
    __normalized
FROM signoz_metrics.time_series_v4
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_metrics.distributed_schema_migrations_v2
INSERT INTO `signoz_metrics`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1, 'finished', '', '2026-05-26 19:37:56.000000000', '1970-01-01 00:00:00.000000000'), (2, 'finished', '', '2026-05-26 19:37:57.000000000', '1970-01-01 00:00:00.000000000'), (3, 'finished', '', '2026-05-26 19:37:58.000000000', '1970-01-01 00:00:00.000000000'), (4, 'finished', '', '2026-05-26 19:37:59.000000000', '1970-01-01 00:00:00.000000000'), (5, 'finished', '', '2026-05-26 19:38:01.000000000', '1970-01-01 00:00:00.000000000'), (6, 'finished', '', '2026-05-26 19:38:02.000000000', '1970-01-01 00:00:00.000000000'), (7, 'finished', '', '2026-05-26 19:38:03.000000000', '1970-01-01 00:00:00.000000000'), (8, 'finished', '', '2026-05-26 19:38:04.000000000', '1970-01-01 00:00:00.000000000'), (9, 'finished', '', '2026-05-26 19:38:06.000000000', '1970-01-01 00:00:00.000000000'), (10, 'finished', '', '2026-05-26 19:38:06.000000000', '1970-01-01 00:00:00.000000000'), (11, 'finished', '', '2026-05-26 19:38:08.000000000', '1970-01-01 00:00:00.000000000'), (12, 'finished', '', '2026-05-26 19:38:09.000000000', '1970-01-01 00:00:00.000000000'), (13, 'finished', '', '2026-05-26 19:38:10.000000000', '1970-01-01 00:00:00.000000000'), (14, 'finished', '', '2026-05-26 19:38:11.000000000', '1970-01-01 00:00:00.000000000'), (15, 'finished', '', '2026-05-26 19:38:13.000000000', '1970-01-01 00:00:00.000000000'), (16, 'finished', '', '2026-05-26 19:38:14.000000000', '1970-01-01 00:00:00.000000000'), (17, 'finished', '', '2026-05-26 19:38:15.000000000', '1970-01-01 00:00:00.000000000'), (18, 'finished', '', '2026-05-26 19:38:16.000000000', '1970-01-01 00:00:00.000000000'), (19, 'finished', '', '2026-05-26 19:38:17.000000000', '1970-01-01 00:00:00.000000000'), (20, 'finished', '', '2026-05-26 19:38:19.000000000', '1970-01-01 00:00:00.000000000'), (21, 'finished', '', '2026-05-26 19:38:21.000000000', '1970-01-01 00:00:00.000000000'), (22, 'finished', '', '2026-05-26 19:38:22.000000000', '1970-01-01 00:00:00.000000000'), (23, 'finished', '', '2026-05-26 19:38:23.000000000', '1970-01-01 00:00:00.000000000'), (24, 'finished', '', '2026-05-26 19:38:23.000000000', '1970-01-01 00:00:00.000000000'), (25, 'finished', '', '2026-05-26 19:38:24.000000000', '1970-01-01 00:00:00.000000000'), (26, 'finished', '', '2026-05-26 19:38:26.000000000', '1970-01-01 00:00:00.000000000'), (27, 'finished', '', '2026-05-26 19:38:28.000000000', '1970-01-01 00:00:00.000000000'), (28, 'finished', '', '2026-05-26 19:38:32.000000000', '1970-01-01 00:00:00.000000000'), (1000, 'finished', '', '2026-05-26 19:42:14.000000000', '1970-01-01 00:00:00.000000000'), (1001, 'finished', '', '2026-05-26 19:42:35.000000000', '1970-01-01 00:00:00.000000000'), (1002, 'finished', '', '2026-05-26 19:42:39.000000000', '1970-01-01 00:00:00.000000000'), (1003, 'finished', '', '2026-05-26 19:42:47.000000000', '1970-01-01 00:00:00.000000000'), (1004, 'finished', '', '2026-05-26 19:42:50.000000000', '1970-01-01 00:00:00.000000000'), (1005, 'finished', '', '2026-05-26 19:43:55.000000000', '1970-01-01 00:00:00.000000000'), (1006, 'finished', '', '2026-05-26 19:44:04.000000000', '1970-01-01 00:00:00.000000000'), (1007, 'finished', '', '2026-05-26 19:43:00.000000000', '1970-01-01 00:00:00.000000000');


-- ==========================================
-- DATABASE: signoz_traces
-- ==========================================
CREATE DATABASE signoz_traces ON CLUSTER '{cluster}'
ENGINE = Atomic
;

-- ---> Phase 1: Base Tables
-- Table Schema: signoz_traces.dependency_graph_minutes_v2
CREATE TABLE signoz_traces.dependency_graph_minutes_v2 ON CLUSTER '{cluster}'
(
    `src` LowCardinality(String) CODEC(ZSTD(1)),
    `dest` LowCardinality(String) CODEC(ZSTD(1)),
    `duration_quantiles_state` AggregateFunction(quantiles(0.5, 0.75, 0.9, 0.95, 0.99), Float64) CODEC(Default),
    `error_count` SimpleAggregateFunction(sum, UInt64) CODEC(T64, ZSTD(1)),
    `total_count` SimpleAggregateFunction(sum, UInt64) CODEC(T64, ZSTD(1)),
    `timestamp` DateTime CODEC(DoubleDelta, LZ4),
    `deployment_environment` LowCardinality(String) CODEC(ZSTD(1)),
    `k8s_cluster_name` LowCardinality(String) CODEC(ZSTD(1)),
    `k8s_namespace_name` LowCardinality(String) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY (timestamp, src, dest, deployment_environment, k8s_cluster_name, k8s_namespace_name)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_traces.durationSort
CREATE TABLE signoz_traces.durationSort ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `spanID` String CODEC(ZSTD(1)),
    `parentSpanID` String CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `kind` Int8 CODEC(T64, ZSTD(1)),
    `durationNano` UInt64 CODEC(T64, ZSTD(1)),
    `statusCode` Int16 CODEC(T64, ZSTD(1)),
    `httpMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `httpUrl` LowCardinality(String) CODEC(ZSTD(1)),
    `httpRoute` LowCardinality(String) CODEC(ZSTD(1)),
    `httpHost` LowCardinality(String) CODEC(ZSTD(1)),
    `hasError` Bool CODEC(T64, ZSTD(1)),
    `rpcSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcService` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `responseStatusCode` LowCardinality(String) CODEC(ZSTD(1)),
    `stringTagMap` Map(String, String) CODEC(ZSTD(1)),
    `numberTagMap` Map(String, Float64) CODEC(ZSTD(1)),
    `boolTagMap` Map(String, Bool) CODEC(ZSTD(1)),
    `isRemote` LowCardinality(String) CODEC(ZSTD(1)),
    `statusMessage` String CODEC(ZSTD(1)),
    `statusCodeString` String CODEC(ZSTD(1)),
    `spanKind` String CODEC(ZSTD(1)),
    INDEX idx_service serviceName TYPE bloom_filter GRANULARITY 4,
    INDEX idx_name name TYPE bloom_filter GRANULARITY 4,
    INDEX idx_kind kind TYPE minmax GRANULARITY 4,
    INDEX idx_duration durationNano TYPE minmax GRANULARITY 1,
    INDEX idx_hasError hasError TYPE set(2) GRANULARITY 1,
    INDEX idx_httpRoute httpRoute TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpUrl httpUrl TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpHost httpHost TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpMethod httpMethod TYPE bloom_filter GRANULARITY 4,
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1,
    INDEX idx_rpcMethod rpcMethod TYPE bloom_filter GRANULARITY 4,
    INDEX idx_responseStatusCode responseStatusCode TYPE set(0) GRANULARITY 1
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY (durationNano, timestamp)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.schema_migrations_v2
CREATE TABLE signoz_traces.schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PRIMARY KEY migration_id
ORDER BY migration_id
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_traces.signoz_error_index_v2
CREATE TABLE signoz_traces.signoz_error_index_v2 ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `errorID` FixedString(32) CODEC(ZSTD(1)),
    `groupID` FixedString(32) CODEC(ZSTD(1)),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `spanID` String CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `exceptionType` LowCardinality(String) CODEC(ZSTD(1)),
    `exceptionMessage` String CODEC(ZSTD(1)),
    `exceptionStacktrace` String CODEC(ZSTD(1)),
    `exceptionEscaped` Bool CODEC(T64, ZSTD(1)),
    `resourceTagsMap` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    INDEX idx_error_id errorID TYPE bloom_filter GRANULARITY 4,
    INDEX idx_resourceTagsMapKeys mapKeys(resourceTagsMap) TYPE bloom_filter(0.01) GRANULARITY 64,
    INDEX idx_resourceTagsMapValues mapValues(resourceTagsMap) TYPE bloom_filter(0.01) GRANULARITY 64
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY (timestamp, groupID)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.signoz_index_v2
CREATE TABLE signoz_traces.signoz_index_v2 ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `spanID` String CODEC(ZSTD(1)),
    `parentSpanID` String CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `kind` Int8 CODEC(T64, ZSTD(1)),
    `durationNano` UInt64 CODEC(T64, ZSTD(1)),
    `statusCode` Int16 CODEC(T64, ZSTD(1)),
    `externalHttpMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `externalHttpUrl` LowCardinality(String) CODEC(ZSTD(1)),
    `dbSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `dbName` LowCardinality(String) CODEC(ZSTD(1)),
    `dbOperation` LowCardinality(String) CODEC(ZSTD(1)),
    `peerService` LowCardinality(String) CODEC(ZSTD(1)),
    `events` Array(String) CODEC(ZSTD(2)),
    `httpMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `httpUrl` LowCardinality(String) CODEC(ZSTD(1)),
    `httpRoute` LowCardinality(String) CODEC(ZSTD(1)),
    `httpHost` LowCardinality(String) CODEC(ZSTD(1)),
    `msgSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `msgOperation` LowCardinality(String) CODEC(ZSTD(1)),
    `hasError` Bool CODEC(T64, ZSTD(1)),
    `rpcSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcService` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `responseStatusCode` LowCardinality(String) CODEC(ZSTD(1)),
    `stringTagMap` Map(String, String) CODEC(ZSTD(1)),
    `numberTagMap` Map(String, Float64) CODEC(ZSTD(1)),
    `boolTagMap` Map(String, Bool) CODEC(ZSTD(1)),
    `resourceTagsMap` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `isRemote` LowCardinality(String) CODEC(ZSTD(1)),
    `statusMessage` String CODEC(ZSTD(1)),
    `statusCodeString` String CODEC(ZSTD(1)),
    `spanKind` String CODEC(ZSTD(1)),
    INDEX idx_service serviceName TYPE bloom_filter GRANULARITY 4,
    INDEX idx_name name TYPE bloom_filter GRANULARITY 4,
    INDEX idx_kind kind TYPE minmax GRANULARITY 4,
    INDEX idx_duration durationNano TYPE minmax GRANULARITY 1,
    INDEX idx_hasError hasError TYPE set(2) GRANULARITY 1,
    INDEX idx_httpRoute httpRoute TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpUrl httpUrl TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpHost httpHost TYPE bloom_filter GRANULARITY 4,
    INDEX idx_httpMethod httpMethod TYPE bloom_filter GRANULARITY 4,
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1,
    INDEX idx_rpcMethod rpcMethod TYPE bloom_filter GRANULARITY 4,
    INDEX idx_responseStatusCode responseStatusCode TYPE set(0) GRANULARITY 1,
    INDEX idx_resourceTagsMapKeys mapKeys(resourceTagsMap) TYPE bloom_filter(0.01) GRANULARITY 64,
    INDEX idx_resourceTagsMapValues mapValues(resourceTagsMap) TYPE bloom_filter(0.01) GRANULARITY 64,
    INDEX idx_statusCodeString statusCodeString TYPE set(3) GRANULARITY 4,
    INDEX idx_spanKind spanKind TYPE set(5) GRANULARITY 4,
    INDEX idx_stringTagMapKeys mapKeys(stringTagMap) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_stringTagMapValues mapValues(stringTagMap) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    INDEX idx_numberTagMapKeys mapKeys(numberTagMap) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_numberTagMapValues mapValues(numberTagMap) TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_boolTagMapKeys mapKeys(boolTagMap) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_resourceTagMapKeys mapKeys(resourceTagsMap) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX idx_resourceTagMapValues mapValues(resourceTagsMap) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    PROJECTION timestampSort
    (
        SELECT *
        ORDER BY timestamp
    )
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
PRIMARY KEY (serviceName, hasError, toStartOfHour(timestamp), name)
ORDER BY (serviceName, hasError, toStartOfHour(timestamp), name, timestamp)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.signoz_index_v3
CREATE TABLE signoz_traces.signoz_index_v3 ON CLUSTER '{cluster}'
(
    `ts_bucket_start` UInt64 CODEC(DoubleDelta, LZ4),
    `resource_fingerprint` String CODEC(ZSTD(1)),
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `trace_id` FixedString(32) CODEC(ZSTD(1)),
    `span_id` String CODEC(ZSTD(1)),
    `trace_state` String CODEC(ZSTD(1)),
    `parent_span_id` String CODEC(ZSTD(1)),
    `flags` UInt32 CODEC(T64, ZSTD(1)),
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `kind` Int8 CODEC(T64, ZSTD(1)),
    `kind_string` String CODEC(ZSTD(1)),
    `duration_nano` UInt64 CODEC(T64, ZSTD(1)),
    `status_code` Int16 CODEC(T64, ZSTD(1)),
    `status_message` String CODEC(ZSTD(1)),
    `status_code_string` String CODEC(ZSTD(1)),
    `attributes_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `attributes_number` Map(LowCardinality(String), Float64) CODEC(ZSTD(1)),
    `attributes_bool` Map(LowCardinality(String), Bool) CODEC(ZSTD(1)),
    `resources_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `events` Array(String) CODEC(ZSTD(2)),
    `links` String CODEC(ZSTD(1)),
    `response_status_code` LowCardinality(String) CODEC(ZSTD(1)),
    `external_http_url` LowCardinality(String) CODEC(ZSTD(1)),
    `http_url` LowCardinality(String) CODEC(ZSTD(1)),
    `external_http_method` LowCardinality(String) CODEC(ZSTD(1)),
    `http_method` LowCardinality(String) CODEC(ZSTD(1)),
    `http_host` LowCardinality(String) CODEC(ZSTD(1)),
    `db_name` LowCardinality(String) CODEC(ZSTD(1)),
    `db_operation` LowCardinality(String) CODEC(ZSTD(1)),
    `has_error` Bool CODEC(T64, ZSTD(1)),
    `is_remote` LowCardinality(String) CODEC(ZSTD(1)),
    `resource_string_service$$name` LowCardinality(String) DEFAULT resources_string['service.name'] CODEC(ZSTD(1)),
    `attribute_string_http$$route` LowCardinality(String) DEFAULT attributes_string['http.route'] CODEC(ZSTD(1)),
    `attribute_string_messaging$$system` LowCardinality(String) DEFAULT attributes_string['messaging.system'] CODEC(ZSTD(1)),
    `attribute_string_messaging$$operation` LowCardinality(String) DEFAULT attributes_string['messaging.operation'] CODEC(ZSTD(1)),
    `attribute_string_db$$system` LowCardinality(String) DEFAULT attributes_string['db.system'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$system` LowCardinality(String) DEFAULT attributes_string['rpc.system'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$service` LowCardinality(String) DEFAULT attributes_string['rpc.service'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$method` LowCardinality(String) DEFAULT attributes_string['rpc.method'] CODEC(ZSTD(1)),
    `attribute_string_peer$$service` LowCardinality(String) DEFAULT attributes_string['peer.service'] CODEC(ZSTD(1)),
    `traceID` FixedString(32) ALIAS trace_id,
    `spanID` String ALIAS span_id,
    `parentSpanID` String ALIAS parent_span_id,
    `spanKind` String ALIAS kind_string,
    `durationNano` UInt64 ALIAS duration_nano,
    `statusCode` Int16 ALIAS status_code,
    `statusMessage` String ALIAS status_message,
    `statusCodeString` String ALIAS status_code_string,
    `references` String ALIAS links,
    `responseStatusCode` LowCardinality(String) ALIAS response_status_code,
    `externalHttpUrl` LowCardinality(String) ALIAS external_http_url,
    `httpUrl` LowCardinality(String) ALIAS http_url,
    `externalHttpMethod` LowCardinality(String) ALIAS external_http_method,
    `httpMethod` LowCardinality(String) ALIAS http_method,
    `httpHost` LowCardinality(String) ALIAS http_host,
    `dbName` LowCardinality(String) ALIAS db_name,
    `dbOperation` LowCardinality(String) ALIAS db_operation,
    `hasError` Bool ALIAS has_error,
    `isRemote` LowCardinality(String) ALIAS is_remote,
    `serviceName` LowCardinality(String) ALIAS `resource_string_service$$name`,
    `httpRoute` LowCardinality(String) ALIAS `attribute_string_http$$route`,
    `msgSystem` LowCardinality(String) ALIAS `attribute_string_messaging$$system`,
    `msgOperation` LowCardinality(String) ALIAS `attribute_string_messaging$$operation`,
    `dbSystem` LowCardinality(String) ALIAS `attribute_string_db$$system`,
    `rpcSystem` LowCardinality(String) ALIAS `attribute_string_rpc$$system`,
    `rpcService` LowCardinality(String) ALIAS `attribute_string_rpc$$service`,
    `rpcMethod` LowCardinality(String) ALIAS `attribute_string_rpc$$method`,
    `peerService` LowCardinality(String) ALIAS `attribute_string_peer$$service`,
    `resource_string_service$$name_exists` Bool DEFAULT if(mapContains(resources_string, 'service.name') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_http$$route_exists` Bool DEFAULT if(mapContains(attributes_string, 'http.route') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_messaging$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'messaging.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_messaging$$operation_exists` Bool DEFAULT if(mapContains(attributes_string, 'messaging.operation') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_db$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'db.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$service_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.service') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$method_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.method') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_peer$$service_exists` Bool DEFAULT if(mapContains(attributes_string, 'peer.service') != 0, true, false) CODEC(ZSTD(1)),
    `resource` JSON(max_dynamic_paths = 100) CODEC(ZSTD(1)),
    `scope` JSON(max_dynamic_paths = 0, attributes JSON(max_dynamic_paths = 0), name String, version String) CODEC(ZSTD(1)),
    INDEX idx_trace_id trace_id TYPE tokenbf_v1(10000, 5, 0) GRANULARITY 1,
    INDEX idx_span_id span_id TYPE tokenbf_v1(5000, 5, 0) GRANULARITY 1,
    INDEX idx_duration duration_nano TYPE minmax GRANULARITY 1,
    INDEX idx_name name TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    INDEX idx_kind kind TYPE minmax GRANULARITY 4,
    INDEX idx_http_route `attribute_string_http$$route` TYPE bloom_filter GRANULARITY 4,
    INDEX idx_http_url http_url TYPE bloom_filter GRANULARITY 4,
    INDEX idx_http_host http_host TYPE bloom_filter GRANULARITY 4,
    INDEX idx_http_method http_method TYPE bloom_filter GRANULARITY 4,
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1,
    INDEX idx_rpc_method `attribute_string_rpc$$method` TYPE bloom_filter GRANULARITY 4,
    INDEX idx_response_statusCode response_status_code TYPE set(0) GRANULARITY 1,
    INDEX idx_status_code_string status_code_string TYPE set(3) GRANULARITY 4,
    INDEX idx_kind_string kind_string TYPE set(5) GRANULARITY 4,
    INDEX attributes_string_idx_key mapKeys(attributes_string) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX attributes_string_idx_val mapValues(attributes_string) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1,
    INDEX attributes_number_idx_key mapKeys(attributes_number) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX attributes_number_idx_val mapValues(attributes_number) TYPE bloom_filter GRANULARITY 1,
    INDEX attributes_bool_idx_key mapKeys(attributes_bool) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX resources_string_idx_key mapKeys(resources_string) TYPE tokenbf_v1(1024, 2, 0) GRANULARITY 1,
    INDEX resources_string_idx_val mapValues(resources_string) TYPE ngrambf_v1(4, 5000, 2, 0) GRANULARITY 1
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY (ts_bucket_start, resource_fingerprint, has_error, name, timestamp)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.signoz_spans
CREATE TABLE signoz_traces.signoz_spans ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `model` String CODEC(ZSTD(9))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY traceID
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 1024, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.span_attributes
CREATE TABLE signoz_traces.span_attributes ON CLUSTER '{cluster}'
(
    `timestamp` DateTime CODEC(DoubleDelta, ZSTD(1)),
    `tagKey` LowCardinality(String) CODEC(ZSTD(1)),
    `tagType` Enum8('tag' = 1, 'resource' = 2) CODEC(ZSTD(1)),
    `dataType` Enum8('string' = 1, 'bool' = 2, 'float64' = 3) CODEC(ZSTD(1)),
    `stringTagValue` String CODEC(ZSTD(1)),
    `float64TagValue` Nullable(Float64) CODEC(ZSTD(1)),
    `isColumn` Bool CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tagKey, tagType, dataType, stringTagValue, float64TagValue, isColumn)
TTL toDateTime(timestamp) + toIntervalSecond(172800)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, allow_nullable_key = 1
;

-- Table Schema: signoz_traces.span_attributes_keys
CREATE TABLE signoz_traces.span_attributes_keys ON CLUSTER '{cluster}'
(
    `tagKey` LowCardinality(String) CODEC(ZSTD(1)),
    `tagType` Enum8('tag' = 1, 'resource' = 2, 'scope' = 3) CODEC(ZSTD(1)),
    `dataType` Enum8('string' = 1, 'bool' = 2, 'float64' = 3) CODEC(ZSTD(1)),
    `isColumn` Bool CODEC(ZSTD(1)),
    `timestamp` DateTime DEFAULT toDateTime(now())
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tagKey, tagType, dataType, isColumn)
TTL timestamp + toIntervalDay(15)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_traces.tag_attributes_v2
CREATE TABLE signoz_traces.tag_attributes_v2 ON CLUSTER '{cluster}'
(
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `tag_key` String CODEC(ZSTD(1)),
    `tag_type` LowCardinality(String) CODEC(ZSTD(1)),
    `tag_data_type` LowCardinality(String) CODEC(ZSTD(1)),
    `string_value` String CODEC(ZSTD(1)),
    `number_value` Nullable(Float64) CODEC(ZSTD(1)),
    INDEX string_value_index string_value TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1,
    INDEX number_value_index number_value TYPE minmax GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(unix_milli / 1000)
ORDER BY (tag_key, tag_type, tag_data_type, string_value, number_value)
TTL toDateTime(unix_milli / 1000) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, allow_nullable_key = 1
;

-- Table Schema: signoz_traces.top_level_operations
CREATE TABLE signoz_traces.top_level_operations ON CLUSTER '{cluster}'
(
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `time` DateTime DEFAULT now() CODEC(ZSTD(1))
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (serviceName, name)
TTL time + toIntervalMonth(1)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_traces.trace_summary
CREATE TABLE signoz_traces.trace_summary ON CLUSTER '{cluster}'
(
    `trace_id` String CODEC(ZSTD(1)),
    `start` SimpleAggregateFunction(min, DateTime64(9)) CODEC(ZSTD(1)),
    `end` SimpleAggregateFunction(max, DateTime64(9)) CODEC(ZSTD(1)),
    `num_spans` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = ReplicatedAggregatingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(end)
ORDER BY trace_id
TTL toDateTime(end) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- Table Schema: signoz_traces.traces_v3_resource
CREATE TABLE signoz_traces.traces_v3_resource ON CLUSTER '{cluster}'
(
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` String CODEC(ZSTD(1)),
    `seen_at_ts_bucket_start` Int64 CODEC(Delta(8), ZSTD(1)),
    INDEX idx_labels lower(labels) TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1,
    INDEX idx_labels_v1 labels TYPE ngrambf_v1(4, 1024, 3, 0) GRANULARITY 1
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(seen_at_ts_bucket_start)
ORDER BY (labels, fingerprint, seen_at_ts_bucket_start)
TTL (toDateTime(seen_at_ts_bucket_start) + toIntervalSecond(1296000)) + toIntervalSecond(1800)
SETTINGS ttl_only_drop_parts = 1, index_granularity = 8192
;

-- Table Schema: signoz_traces.usage
CREATE TABLE signoz_traces.usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
ORDER BY (tenant, collector_id, exporter_id, timestamp)
TTL timestamp + toIntervalDay(3)
SETTINGS index_granularity = 8192
;

-- Table Schema: signoz_traces.usage_explorer
CREATE TABLE signoz_traces.usage_explorer ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `service_name` LowCardinality(String) CODEC(ZSTD(1)),
    `count` UInt64 CODEC(T64, ZSTD(1))
)
ENGINE = ReplicatedSummingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toDate(timestamp)
ORDER BY (timestamp, service_name)
TTL toDateTime(timestamp) + toIntervalSecond(1296000)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1
;

-- ---> Phase 2: Distributed Tables
-- Table Schema: signoz_traces.distributed_dependency_graph_minutes_v2
CREATE TABLE signoz_traces.distributed_dependency_graph_minutes_v2 ON CLUSTER '{cluster}'
(
    `src` LowCardinality(String) CODEC(ZSTD(1)),
    `dest` LowCardinality(String) CODEC(ZSTD(1)),
    `duration_quantiles_state` AggregateFunction(quantiles(0.5, 0.75, 0.9, 0.95, 0.99), Float64) CODEC(Default),
    `error_count` SimpleAggregateFunction(sum, UInt64) CODEC(T64, ZSTD(1)),
    `total_count` SimpleAggregateFunction(sum, UInt64) CODEC(T64, ZSTD(1)),
    `timestamp` DateTime CODEC(DoubleDelta, LZ4),
    `deployment_environment` LowCardinality(String) CODEC(ZSTD(1)),
    `k8s_cluster_name` LowCardinality(String) CODEC(ZSTD(1)),
    `k8s_namespace_name` LowCardinality(String) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'dependency_graph_minutes_v2', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_schema_migrations_v2
CREATE TABLE signoz_traces.distributed_schema_migrations_v2 ON CLUSTER '{cluster}'
(
    `migration_id` UInt64,
    `status` String,
    `error` String,
    `created_at` DateTime64(9),
    `updated_at` DateTime64(9)
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'schema_migrations_v2', rand())
;

-- Table Schema: signoz_traces.distributed_signoz_error_index_v2
CREATE TABLE signoz_traces.distributed_signoz_error_index_v2 ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `errorID` FixedString(32) CODEC(ZSTD(1)),
    `groupID` FixedString(32) CODEC(ZSTD(1)),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `spanID` String CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `exceptionType` LowCardinality(String) CODEC(ZSTD(1)),
    `exceptionMessage` String CODEC(ZSTD(1)),
    `exceptionStacktrace` String CODEC(ZSTD(1)),
    `exceptionEscaped` Bool CODEC(T64, ZSTD(1)),
    `resourceTagsMap` Map(LowCardinality(String), String) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'signoz_error_index_v2', cityHash64(groupID))
;

-- Table Schema: signoz_traces.distributed_signoz_index_v2
CREATE TABLE signoz_traces.distributed_signoz_index_v2 ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `spanID` String CODEC(ZSTD(1)),
    `parentSpanID` String CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `kind` Int8 CODEC(T64, ZSTD(1)),
    `durationNano` UInt64 CODEC(T64, ZSTD(1)),
    `statusCode` Int16 CODEC(T64, ZSTD(1)),
    `externalHttpMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `externalHttpUrl` LowCardinality(String) CODEC(ZSTD(1)),
    `dbSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `dbName` LowCardinality(String) CODEC(ZSTD(1)),
    `dbOperation` LowCardinality(String) CODEC(ZSTD(1)),
    `peerService` LowCardinality(String) CODEC(ZSTD(1)),
    `events` Array(String) CODEC(ZSTD(2)),
    `httpMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `httpUrl` LowCardinality(String) CODEC(ZSTD(1)),
    `httpRoute` LowCardinality(String) CODEC(ZSTD(1)),
    `httpHost` LowCardinality(String) CODEC(ZSTD(1)),
    `msgSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `msgOperation` LowCardinality(String) CODEC(ZSTD(1)),
    `hasError` Bool CODEC(T64, ZSTD(1)),
    `rpcSystem` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcService` LowCardinality(String) CODEC(ZSTD(1)),
    `rpcMethod` LowCardinality(String) CODEC(ZSTD(1)),
    `responseStatusCode` LowCardinality(String) CODEC(ZSTD(1)),
    `stringTagMap` Map(String, String) CODEC(ZSTD(1)),
    `numberTagMap` Map(String, Float64) CODEC(ZSTD(1)),
    `boolTagMap` Map(String, Bool) CODEC(ZSTD(1)),
    `resourceTagsMap` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `isRemote` LowCardinality(String) CODEC(ZSTD(1)),
    `statusMessage` String CODEC(ZSTD(1)),
    `statusCodeString` String CODEC(ZSTD(1)),
    `spanKind` String CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'signoz_index_v2', cityHash64(traceID))
;

-- Table Schema: signoz_traces.distributed_signoz_index_v3
CREATE TABLE signoz_traces.distributed_signoz_index_v3 ON CLUSTER '{cluster}'
(
    `ts_bucket_start` UInt64 CODEC(DoubleDelta, LZ4),
    `resource_fingerprint` String CODEC(ZSTD(1)),
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `trace_id` FixedString(32) CODEC(ZSTD(1)),
    `span_id` String CODEC(ZSTD(1)),
    `trace_state` String CODEC(ZSTD(1)),
    `parent_span_id` String CODEC(ZSTD(1)),
    `flags` UInt32 CODEC(T64, ZSTD(1)),
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `kind` Int8 CODEC(T64, ZSTD(1)),
    `kind_string` String CODEC(ZSTD(1)),
    `duration_nano` UInt64 CODEC(T64, ZSTD(1)),
    `status_code` Int16 CODEC(T64, ZSTD(1)),
    `status_message` String CODEC(ZSTD(1)),
    `status_code_string` String CODEC(ZSTD(1)),
    `attributes_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `attributes_number` Map(LowCardinality(String), Float64) CODEC(ZSTD(1)),
    `attributes_bool` Map(LowCardinality(String), Bool) CODEC(ZSTD(1)),
    `resources_string` Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    `events` Array(String) CODEC(ZSTD(2)),
    `links` String CODEC(ZSTD(1)),
    `response_status_code` LowCardinality(String) CODEC(ZSTD(1)),
    `external_http_url` LowCardinality(String) CODEC(ZSTD(1)),
    `http_url` LowCardinality(String) CODEC(ZSTD(1)),
    `external_http_method` LowCardinality(String) CODEC(ZSTD(1)),
    `http_method` LowCardinality(String) CODEC(ZSTD(1)),
    `http_host` LowCardinality(String) CODEC(ZSTD(1)),
    `db_name` LowCardinality(String) CODEC(ZSTD(1)),
    `db_operation` LowCardinality(String) CODEC(ZSTD(1)),
    `has_error` Bool CODEC(T64, ZSTD(1)),
    `is_remote` LowCardinality(String) CODEC(ZSTD(1)),
    `resource_string_service$$name` LowCardinality(String) DEFAULT resources_string['service.name'] CODEC(ZSTD(1)),
    `attribute_string_http$$route` LowCardinality(String) DEFAULT attributes_string['http.route'] CODEC(ZSTD(1)),
    `attribute_string_messaging$$system` LowCardinality(String) DEFAULT attributes_string['messaging.system'] CODEC(ZSTD(1)),
    `attribute_string_messaging$$operation` LowCardinality(String) DEFAULT attributes_string['messaging.operation'] CODEC(ZSTD(1)),
    `attribute_string_db$$system` LowCardinality(String) DEFAULT attributes_string['db.system'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$system` LowCardinality(String) DEFAULT attributes_string['rpc.system'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$service` LowCardinality(String) DEFAULT attributes_string['rpc.service'] CODEC(ZSTD(1)),
    `attribute_string_rpc$$method` LowCardinality(String) DEFAULT attributes_string['rpc.method'] CODEC(ZSTD(1)),
    `attribute_string_peer$$service` LowCardinality(String) DEFAULT attributes_string['peer.service'] CODEC(ZSTD(1)),
    `traceID` FixedString(32) ALIAS trace_id,
    `spanID` String ALIAS span_id,
    `parentSpanID` String ALIAS parent_span_id,
    `spanKind` String ALIAS kind_string,
    `durationNano` UInt64 ALIAS duration_nano,
    `statusCode` Int16 ALIAS status_code,
    `statusMessage` String ALIAS status_message,
    `statusCodeString` String ALIAS status_code_string,
    `references` String ALIAS links,
    `responseStatusCode` LowCardinality(String) ALIAS response_status_code,
    `externalHttpUrl` LowCardinality(String) ALIAS external_http_url,
    `httpUrl` LowCardinality(String) ALIAS http_url,
    `externalHttpMethod` LowCardinality(String) ALIAS external_http_method,
    `httpMethod` LowCardinality(String) ALIAS http_method,
    `httpHost` LowCardinality(String) ALIAS http_host,
    `dbName` LowCardinality(String) ALIAS db_name,
    `dbOperation` LowCardinality(String) ALIAS db_operation,
    `hasError` Bool ALIAS has_error,
    `isRemote` LowCardinality(String) ALIAS is_remote,
    `serviceName` LowCardinality(String) ALIAS `resource_string_service$$name`,
    `httpRoute` LowCardinality(String) ALIAS `attribute_string_http$$route`,
    `msgSystem` LowCardinality(String) ALIAS `attribute_string_messaging$$system`,
    `msgOperation` LowCardinality(String) ALIAS `attribute_string_messaging$$operation`,
    `dbSystem` LowCardinality(String) ALIAS `attribute_string_db$$system`,
    `rpcSystem` LowCardinality(String) ALIAS `attribute_string_rpc$$system`,
    `rpcService` LowCardinality(String) ALIAS `attribute_string_rpc$$service`,
    `rpcMethod` LowCardinality(String) ALIAS `attribute_string_rpc$$method`,
    `peerService` LowCardinality(String) ALIAS `attribute_string_peer$$service`,
    `resource_string_service$$name_exists` Bool DEFAULT if(mapContains(resources_string, 'service.name') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_http$$route_exists` Bool DEFAULT if(mapContains(attributes_string, 'http.route') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_messaging$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'messaging.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_messaging$$operation_exists` Bool DEFAULT if(mapContains(attributes_string, 'messaging.operation') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_db$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'db.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$system_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.system') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$service_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.service') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_rpc$$method_exists` Bool DEFAULT if(mapContains(attributes_string, 'rpc.method') != 0, true, false) CODEC(ZSTD(1)),
    `attribute_string_peer$$service_exists` Bool DEFAULT if(mapContains(attributes_string, 'peer.service') != 0, true, false) CODEC(ZSTD(1)),
    `resource` JSON(max_dynamic_paths = 100) CODEC(ZSTD(1)),
    `scope` JSON(max_dynamic_paths = 0, attributes JSON(max_dynamic_paths = 0), name String, version String) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'signoz_index_v3', cityHash64(trace_id))
;

-- Table Schema: signoz_traces.distributed_signoz_spans
CREATE TABLE signoz_traces.distributed_signoz_spans ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `traceID` FixedString(32) CODEC(ZSTD(1)),
    `model` String CODEC(ZSTD(9))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'signoz_spans', cityHash64(traceID))
;

-- Table Schema: signoz_traces.distributed_span_attributes
CREATE TABLE signoz_traces.distributed_span_attributes ON CLUSTER '{cluster}'
(
    `timestamp` DateTime CODEC(DoubleDelta, ZSTD(1)),
    `tagKey` LowCardinality(String) CODEC(ZSTD(1)),
    `tagType` Enum8('tag' = 1, 'resource' = 2) CODEC(ZSTD(1)),
    `dataType` Enum8('string' = 1, 'bool' = 2, 'float64' = 3) CODEC(ZSTD(1)),
    `stringTagValue` String CODEC(ZSTD(1)),
    `float64TagValue` Nullable(Float64) CODEC(ZSTD(1)),
    `isColumn` Bool CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'span_attributes', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_span_attributes_keys
CREATE TABLE signoz_traces.distributed_span_attributes_keys ON CLUSTER '{cluster}'
(
    `tagKey` LowCardinality(String) CODEC(ZSTD(1)),
    `tagType` Enum8('tag' = 1, 'resource' = 2, 'scope' = 3) CODEC(ZSTD(1)),
    `dataType` Enum8('string' = 1, 'bool' = 2, 'float64' = 3) CODEC(ZSTD(1)),
    `isColumn` Bool CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'span_attributes_keys', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_tag_attributes_v2
CREATE TABLE signoz_traces.distributed_tag_attributes_v2 ON CLUSTER '{cluster}'
(
    `unix_milli` Int64 CODEC(Delta(8), ZSTD(1)),
    `tag_key` String CODEC(ZSTD(1)),
    `tag_type` LowCardinality(String) CODEC(ZSTD(1)),
    `tag_data_type` LowCardinality(String) CODEC(ZSTD(1)),
    `string_value` String CODEC(ZSTD(1)),
    `number_value` Nullable(Float64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'tag_attributes_v2', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_top_level_operations
CREATE TABLE signoz_traces.distributed_top_level_operations ON CLUSTER '{cluster}'
(
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `serviceName` LowCardinality(String) CODEC(ZSTD(1)),
    `time` DateTime DEFAULT now() CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'top_level_operations', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_trace_summary
CREATE TABLE signoz_traces.distributed_trace_summary ON CLUSTER '{cluster}'
(
    `trace_id` String CODEC(ZSTD(1)),
    `start` SimpleAggregateFunction(min, DateTime64(9)) CODEC(ZSTD(1)),
    `end` SimpleAggregateFunction(max, DateTime64(9)) CODEC(ZSTD(1)),
    `num_spans` SimpleAggregateFunction(sum, UInt64) CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'trace_summary', cityHash64(trace_id))
;

-- Table Schema: signoz_traces.distributed_traces_v3_resource
CREATE TABLE signoz_traces.distributed_traces_v3_resource ON CLUSTER '{cluster}'
(
    `labels` String CODEC(ZSTD(5)),
    `fingerprint` String CODEC(ZSTD(1)),
    `seen_at_ts_bucket_start` Int64 CODEC(Delta(8), ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'traces_v3_resource', cityHash64(labels, fingerprint))
;

-- Table Schema: signoz_traces.distributed_usage
CREATE TABLE signoz_traces.distributed_usage ON CLUSTER '{cluster}'
(
    `tenant` String CODEC(ZSTD(1)),
    `collector_id` String CODEC(ZSTD(1)),
    `exporter_id` String CODEC(ZSTD(1)),
    `timestamp` DateTime CODEC(ZSTD(1)),
    `data` String CODEC(ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'usage', cityHash64(rand()))
;

-- Table Schema: signoz_traces.distributed_usage_explorer
CREATE TABLE signoz_traces.distributed_usage_explorer ON CLUSTER '{cluster}'
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `service_name` LowCardinality(String) CODEC(ZSTD(1)),
    `count` UInt64 CODEC(T64, ZSTD(1))
)
ENGINE = Distributed('{cluster}', 'signoz_traces', 'usage_explorer', cityHash64(rand()))
;

-- ---> Phase 3: Materialized Views
-- View Schema: signoz_traces.dependency_graph_minutes_db_calls_mv_v2
CREATE MATERIALIZED VIEW signoz_traces.dependency_graph_minutes_db_calls_mv_v2 ON CLUSTER '{cluster}' TO signoz_traces.dependency_graph_minutes_v2
(
    `src` LowCardinality(String),
    `dest` LowCardinality(String),
    `duration_quantiles_state` AggregateFunction(quantiles(0.5, 0.75, 0.9, 0.95, 0.99), Float64),
    `error_count` UInt64,
    `total_count` UInt64,
    `timestamp` DateTime,
    `deployment_environment` String,
    `k8s_cluster_name` String,
    `k8s_namespace_name` String
)
AS SELECT
    `resource_string_service$$name` AS src,
    `attribute_string_db$$system` AS dest,
    quantilesState(0.5, 0.75, 0.9, 0.95, 0.99)(toFloat64(duration_nano)) AS duration_quantiles_state,
    countIf(status_code = 2) AS error_count,
    count(*) AS total_count,
    toStartOfMinute(timestamp) AS timestamp,
    resources_string['deployment.environment'] AS deployment_environment,
    resources_string['k8s.cluster.name'] AS k8s_cluster_name,
    resources_string['k8s.namespace.name'] AS k8s_namespace_name
FROM signoz_traces.signoz_index_v3
WHERE (dest != '') AND (kind != 2)
GROUP BY
    timestamp,
    src,
    dest,
    deployment_environment,
    k8s_cluster_name,
    k8s_namespace_name
;

-- View Schema: signoz_traces.dependency_graph_minutes_messaging_calls_mv_v2
CREATE MATERIALIZED VIEW signoz_traces.dependency_graph_minutes_messaging_calls_mv_v2 ON CLUSTER '{cluster}' TO signoz_traces.dependency_graph_minutes_v2
(
    `src` LowCardinality(String),
    `dest` LowCardinality(String),
    `duration_quantiles_state` AggregateFunction(quantiles(0.5, 0.75, 0.9, 0.95, 0.99), Float64),
    `error_count` UInt64,
    `total_count` UInt64,
    `timestamp` DateTime,
    `deployment_environment` String,
    `k8s_cluster_name` String,
    `k8s_namespace_name` String
)
AS SELECT
    `resource_string_service$$name` AS src,
    `attribute_string_messaging$$system` AS dest,
    quantilesState(0.5, 0.75, 0.9, 0.95, 0.99)(toFloat64(duration_nano)) AS duration_quantiles_state,
    countIf(status_code = 2) AS error_count,
    count(*) AS total_count,
    toStartOfMinute(timestamp) AS timestamp,
    resources_string['deployment.environment'] AS deployment_environment,
    resources_string['k8s.cluster.name'] AS k8s_cluster_name,
    resources_string['k8s.namespace.name'] AS k8s_namespace_name
FROM signoz_traces.signoz_index_v3
WHERE (dest != '') AND (kind != 2)
GROUP BY
    timestamp,
    src,
    dest,
    deployment_environment,
    k8s_cluster_name,
    k8s_namespace_name
;

-- View Schema: signoz_traces.dependency_graph_minutes_service_calls_mv_v2
CREATE MATERIALIZED VIEW signoz_traces.dependency_graph_minutes_service_calls_mv_v2 ON CLUSTER '{cluster}' TO signoz_traces.dependency_graph_minutes_v2
(
    `src` LowCardinality(String),
    `dest` LowCardinality(String),
    `duration_quantiles_state` AggregateFunction(quantiles(0.5, 0.75, 0.9, 0.95, 0.99), Float64),
    `error_count` UInt64,
    `total_count` UInt64,
    `timestamp` DateTime,
    `deployment_environment` String,
    `k8s_cluster_name` String,
    `k8s_namespace_name` String
)
AS SELECT
    A.`resource_string_service$$name` AS src,
    B.`resource_string_service$$name` AS dest,
    quantilesState(0.5, 0.75, 0.9, 0.95, 0.99)(toFloat64(B.duration_nano)) AS duration_quantiles_state,
    countIf(B.status_code = 2) AS error_count,
    count(*) AS total_count,
    toStartOfMinute(B.timestamp) AS timestamp,
    B.resources_string['deployment.environment'] AS deployment_environment,
    B.resources_string['k8s.cluster.name'] AS k8s_cluster_name,
    B.resources_string['k8s.namespace.name'] AS k8s_namespace_name
FROM signoz_traces.signoz_index_v3 AS A, signoz_traces.signoz_index_v3 AS B
WHERE (A.`resource_string_service$$name` != B.`resource_string_service$$name`) AND (A.span_id = B.parent_span_id) AND (B.span_id != '') AND (A.span_id != '')
GROUP BY
    timestamp,
    src,
    dest,
    deployment_environment,
    k8s_cluster_name,
    k8s_namespace_name
;

-- View Schema: signoz_traces.root_operations
CREATE MATERIALIZED VIEW signoz_traces.root_operations ON CLUSTER '{cluster}' TO signoz_traces.top_level_operations
(
    `name` LowCardinality(String),
    `serviceName` LowCardinality(String)
)
AS SELECT DISTINCT
    name,
    `resource_string_service$$name` AS serviceName
FROM signoz_traces.signoz_index_v3
WHERE parent_span_id = ''
;

-- View Schema: signoz_traces.sub_root_operations
CREATE MATERIALIZED VIEW signoz_traces.sub_root_operations ON CLUSTER '{cluster}' TO signoz_traces.top_level_operations
(
    `name` LowCardinality(String),
    `serviceName` LowCardinality(String)
)
AS SELECT DISTINCT
    name,
    `resource_string_service$$name` AS serviceName
FROM signoz_traces.signoz_index_v3 AS A, signoz_traces.signoz_index_v3 AS B
WHERE (A.`resource_string_service$$name` != B.`resource_string_service$$name`) AND (A.parent_span_id = B.span_id) AND (B.span_id != '') AND (A.span_id != '')
;

-- View Schema: signoz_traces.trace_summary_mv
CREATE MATERIALIZED VIEW signoz_traces.trace_summary_mv ON CLUSTER '{cluster}' TO signoz_traces.trace_summary
(
    `trace_id` FixedString(32),
    `start` DateTime64(9),
    `end` DateTime64(9),
    `num_spans` UInt64
)
AS SELECT
    trace_id,
    min(timestamp) AS start,
    max(timestamp) AS end,
    toUInt64(count()) AS num_spans
FROM signoz_traces.signoz_index_v3
GROUP BY trace_id
;

-- View Schema: signoz_traces.usage_explorer_mv
CREATE MATERIALIZED VIEW signoz_traces.usage_explorer_mv ON CLUSTER '{cluster}' TO signoz_traces.usage_explorer
(
    `timestamp` DateTime64(9) CODEC(DoubleDelta, LZ4),
    `service_name` LowCardinality(String) CODEC(ZSTD(1)),
    `count` UInt64 CODEC(T64, ZSTD(1))
)
AS SELECT
    toStartOfHour(timestamp) AS timestamp,
    serviceName AS service_name,
    count() AS count
FROM signoz_traces.signoz_index_v2
GROUP BY
    timestamp,
    serviceName
;

-- ---> Phase 4: Data Inserts
-- Table Data: signoz_traces.distributed_schema_migrations_v2
INSERT INTO `signoz_traces`.`distributed_schema_migrations_v2` (`migration_id`, `status`, `error`, `created_at`, `updated_at`) VALUES (1, 'finished', '', '2026-05-26 19:38:36.000000000', '1970-01-01 00:00:00.000000000'), (2, 'finished', '', '2026-05-26 19:38:42.000000000', '1970-01-01 00:00:00.000000000'), (3, 'finished', '', '2026-05-26 19:39:43.000000000', '1970-01-01 00:00:00.000000000'), (4, 'finished', '', '2026-05-26 19:39:44.000000000', '1970-01-01 00:00:00.000000000'), (5, 'finished', '', '2026-05-26 19:39:45.000000000', '1970-01-01 00:00:00.000000000'), (6, 'finished', '', '2026-05-26 19:39:47.000000000', '1970-01-01 00:00:00.000000000'), (7, 'finished', '', '2026-05-26 19:39:48.000000000', '1970-01-01 00:00:00.000000000'), (8, 'finished', '', '2026-05-26 19:39:50.000000000', '1970-01-01 00:00:00.000000000'), (9, 'finished', '', '2026-05-26 19:39:50.000000000', '1970-01-01 00:00:00.000000000'), (10, 'finished', '', '2026-05-26 19:39:52.000000000', '1970-01-01 00:00:00.000000000'), (11, 'finished', '', '2026-05-26 19:39:53.000000000', '1970-01-01 00:00:00.000000000'), (12, 'finished', '', '2026-05-26 19:39:54.000000000', '1970-01-01 00:00:00.000000000'), (13, 'finished', '', '2026-05-26 19:39:56.000000000', '1970-01-01 00:00:00.000000000'), (14, 'finished', '', '2026-05-26 19:39:56.000000000', '1970-01-01 00:00:00.000000000'), (15, 'finished', '', '2026-05-26 19:39:58.000000000', '1970-01-01 00:00:00.000000000'), (16, 'finished', '', '2026-05-26 19:39:59.000000000', '1970-01-01 00:00:00.000000000'), (17, 'finished', '', '2026-05-26 19:40:00.000000000', '1970-01-01 00:00:00.000000000'), (18, 'finished', '', '2026-05-26 19:40:02.000000000', '1970-01-01 00:00:00.000000000'), (19, 'finished', '', '2026-05-26 19:40:03.000000000', '1970-01-01 00:00:00.000000000'), (20, 'finished', '', '2026-05-26 19:40:04.000000000', '1970-01-01 00:00:00.000000000'), (21, 'finished', '', '2026-05-26 19:40:05.000000000', '1970-01-01 00:00:00.000000000'), (22, 'finished', '', '2026-05-26 19:40:07.000000000', '1970-01-01 00:00:00.000000000'), (23, 'finished', '', '2026-05-26 19:40:08.000000000', '1970-01-01 00:00:00.000000000'), (24, 'finished', '', '2026-05-26 19:40:09.000000000', '1970-01-01 00:00:00.000000000'), (25, 'finished', '', '2026-05-26 19:40:10.000000000', '1970-01-01 00:00:00.000000000'), (26, 'finished', '', '2026-05-26 19:40:12.000000000', '1970-01-01 00:00:00.000000000'), (27, 'finished', '', '2026-05-26 19:40:15.000000000', '1970-01-01 00:00:00.000000000'), (1000, 'finished', '', '2026-05-26 19:40:23.000000000', '1970-01-01 00:00:00.000000000'), (1001, 'finished', '', '2026-05-26 19:43:31.000000000', '1970-01-01 00:00:00.000000000'), (1002, 'finished', '', '2026-05-26 19:40:26.000000000', '1970-01-01 00:00:00.000000000'), (1003, 'finished', '', '2026-05-26 19:43:36.000000000', '1970-01-01 00:00:00.000000000'), (1004, 'finished', '', '2026-05-26 19:40:28.000000000', '1970-01-01 00:00:00.000000000'), (1005, 'finished', '', '2026-05-26 19:41:00.000000000', '1970-01-01 00:00:00.000000000'), (1006, 'finished', '', '2026-05-26 19:41:03.000000000', '1970-01-01 00:00:00.000000000'), (1007, 'finished', '', '2026-05-26 19:41:05.000000000', '1970-01-01 00:00:00.000000000'), (1008, 'finished', '', '2026-05-26 19:41:08.000000000', '1970-01-01 00:00:00.000000000'), (1009, 'finished', '', '2026-05-26 19:41:11.000000000', '1970-01-01 00:00:00.000000000'), (1010, 'finished', '', '2026-05-26 19:43:39.000000000', '1970-01-01 00:00:00.000000000');


