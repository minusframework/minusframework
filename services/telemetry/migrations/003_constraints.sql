ALTER TABLE spans_hourly ADD UNIQUE (hour, license_key, service_name, operation_name);
ALTER TABLE metrics_hourly ADD UNIQUE (hour, license_key, metric_name, metric_type);
