package model

import "time"

type Environment struct {
	ID         string    `json:"id"`
	LicenseKey string    `json:"-"`
	Name       string    `json:"name"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
