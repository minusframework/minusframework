package store

import (
    "context"
    "github.com/jackc/pgx/v5/pgxpool"
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
        return nil, err
    }
    return &Store{pool: pool}, nil
}

func (s *Store) Close() {
    s.pool.Close()
}
