package model

import (
	"encoding/json"
	"time"
)

type FlagType string

const (
	FlagTypeBoolean FlagType = "boolean"
	FlagTypeVariant FlagType = "variant"
)

type Flag struct {
	ID             string    `json:"id"`
	LicenseKey     string    `json:"-"`
	Key            string    `json:"key"`
	Name           string    `json:"name"`
	Description    string    `json:"description,omitempty"`
	FlagType       FlagType  `json:"flag_type"`
	DefaultVariant string    `json:"default_variant,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type FlagValue struct {
	ID                string          `json:"id"`
	FlagID            string          `json:"flag_id"`
	EnvironmentID     string          `json:"environment_id"`
	Enabled           bool            `json:"enabled"`
	VariantValue      json.RawMessage `json:"variant_value,omitempty"`
	RolloutPercentage int             `json:"rollout_percentage"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}

type CreateFlagRequest struct {
	Key            string   `json:"key" binding:"required"`
	Name           string   `json:"name" binding:"required"`
	Description    string   `json:"description,omitempty"`
	FlagType       FlagType `json:"flag_type" binding:"required"`
	DefaultVariant string   `json:"default_variant,omitempty"`
}
