package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/model"
)

type Store struct {
	pool *pgxpool.Pool
}

func NewPostgres(ctx context.Context, dsn string) (*Store, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return &Store{pool: pool}, nil
}

func (s *Store) Close() {
	s.pool.Close()
}

func (s *Store) ValidateLicenseKey(ctx context.Context, licenseKey string) (bool, error) {
	var exists bool
	err := s.pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM licenses WHERE license_key = $1 AND status = 'active')`,
		licenseKey,
	).Scan(&exists)
	return exists, err
}

func (s *Store) BatchInsertSpans(ctx context.Context, spans []model.Span) error {
	batch := &pgx.Batch{}
	for _, span := range spans {
		batch.Queue(
			`INSERT INTO spans (license_key, trace_id, span_id, parent_span_id, operation_name,
             service_name, span_kind, start_time, end_time, status, tags, events)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
			span.LicenseKey, span.TraceID, span.SpanID, span.ParentSpanID,
			span.OperationName, span.ServiceName, span.SpanKind,
			span.StartTime, span.EndTime, span.Status,
			span.Tags, span.Events,
		)
	}
	br := s.pool.SendBatch(ctx, batch)
	defer br.Close()
	for i := 0; i < len(spans); i++ {
		if _, err := br.Exec(); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) InsertMetric(ctx context.Context, m *model.Metric) error {
	_, err := s.pool.Exec(ctx,
		`INSERT INTO metrics (license_key, metric_name, metric_type, value, tags, timestamp)
         VALUES ($1, $2, $3, $4, $5, $6)`,
		m.LicenseKey, m.MetricName, m.MetricType, m.Value, m.Tags, m.Timestamp,
	)
	return err
}

func (s *Store) QuerySpans(ctx context.Context, licenseKey string, since, until time.Time, limit int) ([]*model.Span, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, trace_id, span_id, parent_span_id, operation_name, service_name,
                span_kind, start_time, end_time, status, tags, events, created_at
         FROM spans
         WHERE license_key = $1 AND start_time >= $2 AND start_time <= $3
         ORDER BY start_time DESC LIMIT $4`,
		licenseKey, since, until, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var spans []*model.Span
	for rows.Next() {
		s := &model.Span{}
		if err := rows.Scan(&s.ID, &s.TraceID, &s.SpanID, &s.ParentSpanID,
			&s.OperationName, &s.ServiceName, &s.SpanKind,
			&s.StartTime, &s.EndTime, &s.Status, &s.Tags, &s.Events, &s.CreatedAt); err != nil {
			return nil, err
		}
		spans = append(spans, s)
	}
	return spans, nil
}

func (s *Store) GetDashboardSummary(ctx context.Context, licenseKey string) (map[string]interface{}, error) {
	var activeServices int
	var spansLastHour int
	var errorRate float64

	if err := s.pool.QueryRow(ctx,
		`SELECT COUNT(DISTINCT service_name) FROM spans
         WHERE license_key = $1 AND start_time > now() - interval '1 hour'`,
		licenseKey,
	).Scan(&activeServices); err != nil {
		return nil, err
	}

	if err := s.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM spans
         WHERE license_key = $1 AND start_time > now() - interval '1 hour'`,
		licenseKey,
	).Scan(&spansLastHour); err != nil {
		return nil, err
	}

	if err := s.pool.QueryRow(ctx,
		`SELECT COALESCE(
            (SELECT COUNT(*) FILTER (WHERE status = 'error')::float / NULLIF(COUNT(*), 0) * 100
             FROM spans
             WHERE license_key = $1 AND start_time > now() - interval '1 hour'),
         0)`,
		licenseKey,
	).Scan(&errorRate); err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"active_services": activeServices,
		"spans_last_hour": spansLastHour,
		"error_rate":      errorRate,
	}, nil
}

func (s *Store) GetLicenseKeyByUserID(ctx context.Context, userID string) (string, error) {
	var licenseKey string
	err := s.pool.QueryRow(ctx,
		`SELECT license_key FROM licenses WHERE user_id = $1 AND status = 'active' LIMIT 1`,
		userID,
	).Scan(&licenseKey)
	return licenseKey, err
}

func (s *Store) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
	tag, err := s.pool.Exec(ctx, sql, args...)
	return tag.RowsAffected(), err
}

func (s *Store) Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error) {
	return s.pool.Query(ctx, sql, args...)
}
