package model

import "time"

type Span struct {
	ID            string            `json:"id,omitempty"`
	LicenseKey    string            `json:"-"`
	TraceID       string            `json:"trace_id"`
	SpanID        string            `json:"span_id"`
	ParentSpanID  string            `json:"parent_span_id,omitempty"`
	OperationName string            `json:"operation_name"`
	ServiceName   string            `json:"service_name"`
	SpanKind      string            `json:"span_kind"`
	StartTime     time.Time         `json:"start_time"`
	EndTime       time.Time         `json:"end_time"`
	Status        string            `json:"status"`
	Tags          map[string]string `json:"tags,omitempty"`
	Events        []SpanEvent       `json:"events,omitempty"`
	CreatedAt     time.Time         `json:"created_at,omitempty"`
}

func (s *Span) DurationMs() float64 {
	return s.EndTime.Sub(s.StartTime).Seconds() * 1000
}

type SpanEvent struct {
	Timestamp time.Time         `json:"timestamp"`
	Name      string            `json:"name"`
	Tags      map[string]string `json:"tags,omitempty"`
}

type TraceRequest struct {
	TraceID string `json:"trace_id" binding:"required"`
	Spans   []Span `json:"spans" binding:"required"`
}
