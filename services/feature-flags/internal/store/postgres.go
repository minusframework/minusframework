package store

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/model"
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

func (s *Store) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
	tag, err := s.pool.Exec(ctx, sql, args...)
	return tag.RowsAffected(), err
}

func (s *Store) Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error) {
	return s.pool.Query(ctx, sql, args...)
}

func (s *Store) ListEnvironments(ctx context.Context, licenseKey string) ([]*model.Environment, error) {
	rows, err := s.pool.Query(ctx, `SELECT id, license_key, name, created_at, updated_at FROM environments WHERE license_key = $1 ORDER BY name`, licenseKey)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var envs []*model.Environment
	for rows.Next() {
		e := &model.Environment{}
		rows.Scan(&e.ID, &e.LicenseKey, &e.Name, &e.CreatedAt, &e.UpdatedAt)
		envs = append(envs, e)
	}
	return envs, nil
}

func (s *Store) CreateEnvironment(ctx context.Context, e *model.Environment) error {
	return s.pool.QueryRow(ctx, `INSERT INTO environments (license_key, name) VALUES ($1, $2) RETURNING id, created_at, updated_at`, e.LicenseKey, e.Name).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (s *Store) DeleteEnvironment(ctx context.Context, id string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM environments WHERE id = $1`, id)
	return err
}

func (s *Store) GetLicenseKeyByUserID(ctx context.Context, userID string) (string, error) {
	var licenseKey string
	err := s.pool.QueryRow(ctx,
		`SELECT license_key FROM licenses WHERE user_id = $1 AND status = 'active' LIMIT 1`,
		userID,
	).Scan(&licenseKey)
	return licenseKey, err
}

func (s *Store) GetFlagByID(ctx context.Context, id string) (*model.Flag, error) {
	f := &model.Flag{}
	err := s.pool.QueryRow(ctx,
		`SELECT f.id, f.key, f.name, f.description, f.flag_type, f.default_variant, f.created_at, f.updated_at
		 FROM flags f WHERE f.id = $1`, id,
	).Scan(&f.ID, &f.Key, &f.Name, &f.Description, &f.FlagType, &f.DefaultVariant, &f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return f, nil
}

func (s *Store) ListFlags(ctx context.Context, licenseKey, environmentID string) ([]*model.Flag, error) {
	var rows pgx.Rows
	var err error
	if environmentID != "" {
		rows, err = s.pool.Query(ctx,
			`SELECT f.id, f.key, f.name, f.description, f.flag_type, f.default_variant, f.created_at, f.updated_at,
                    fv.id, fv.enabled, fv.variant_value, fv.rollout_percentage
             FROM flags f
             LEFT JOIN flag_values fv ON fv.flag_id = f.id AND fv.environment_id = $2
             WHERE f.license_key = $1
             ORDER BY f.key`, licenseKey, environmentID)
	} else {
		rows, err = s.pool.Query(ctx,
			`SELECT f.id, f.key, f.name, f.description, f.flag_type, f.default_variant, f.created_at, f.updated_at
			 FROM flags f WHERE f.license_key = $1 ORDER BY f.key`, licenseKey)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var flags []*model.Flag
	for rows.Next() {
		f := &model.Flag{}
		if environmentID != "" {
			var fvID *string
			var enabled *bool
			var variantValue *json.RawMessage
			var rollout *int
			rows.Scan(&f.ID, &f.Key, &f.Name, &f.Description, &f.FlagType, &f.DefaultVariant, &f.CreatedAt, &f.UpdatedAt,
				&fvID, &enabled, &variantValue, &rollout)
		} else {
			rows.Scan(&f.ID, &f.Key, &f.Name, &f.Description, &f.FlagType, &f.DefaultVariant, &f.CreatedAt, &f.UpdatedAt)
		}
		flags = append(flags, f)
	}
	return flags, nil
}

func (s *Store) CreateFlag(ctx context.Context, f *model.Flag) error {
	return s.pool.QueryRow(ctx, `INSERT INTO flags (license_key, key, name, description, flag_type, default_variant) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, created_at, updated_at`, f.LicenseKey, f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant).Scan(&f.ID, &f.CreatedAt, &f.UpdatedAt)
}

func (s *Store) UpdateFlag(ctx context.Context, f *model.Flag) error {
	_, err := s.pool.Exec(ctx, `UPDATE flags SET key=$1, name=$2, description=$3, flag_type=$4, default_variant=$5, updated_at=now() WHERE id=$6`, f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant, f.ID)
	return err
}

func (s *Store) DeleteFlag(ctx context.Context, id string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM flags WHERE id = $1`, id)
	return err
}

func (s *Store) UpsertFlagValue(ctx context.Context, fv *model.FlagValue) error {
	return s.pool.QueryRow(ctx, `INSERT INTO flag_values (flag_id, environment_id, enabled, variant_value, rollout_percentage) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (flag_id, environment_id) DO UPDATE SET enabled=EXCLUDED.enabled, variant_value=EXCLUDED.variant_value, rollout_percentage=EXCLUDED.rollout_percentage, updated_at=now() RETURNING id, created_at, updated_at`, fv.FlagID, fv.EnvironmentID, fv.Enabled, fv.VariantValue, fv.RolloutPercentage).Scan(&fv.ID, &fv.CreatedAt, &fv.UpdatedAt)
}

func (s *Store) CreateAuditLog(ctx context.Context, licenseKey string, actorID *string, action, resourceType, resourceID string, oldValue, newValue interface{}) error {
	_, err := s.pool.Exec(ctx, `INSERT INTO audit_log (license_key, actor_id, action, resource_type, resource_id, old_value, new_value) VALUES ($1,$2,$3,$4,$5,$6,$7)`, licenseKey, actorID, action, resourceType, resourceID, oldValue, newValue)
	return err
}

type AuditEntry struct {
	ID           string    `json:"id"`
	ActorID      *string   `json:"actor_id"`
	Action       string    `json:"action"`
	ResourceType string    `json:"resource_type"`
	ResourceID   string    `json:"resource_id"`
	CreatedAt    time.Time `json:"created_at"`
}

func (s *Store) QueryAuditLog(ctx context.Context, licenseKey string, limit int) ([]*AuditEntry, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, actor_id, action, resource_type, resource_id, created_at
         FROM audit_log WHERE license_key = $1 ORDER BY created_at DESC LIMIT $2`,
		licenseKey, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var logs []*AuditEntry
	for rows.Next() {
		e := &AuditEntry{}
		rows.Scan(&e.ID, &e.ActorID, &e.Action, &e.ResourceType, &e.ResourceID, &e.CreatedAt)
		logs = append(logs, e)
	}
	return logs, nil
}
