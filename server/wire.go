package main

// Detection is one distinct physical food item. It is both what the model
// returns and what this service returns to the app — the field names are shared
// deliberately, so the schema, the normaliser and the client model cannot drift
// apart into three slightly different shapes.
type Detection struct {
	// InstanceID identifies one physical item across every shot of the batch.
	// It is the whole deduplication mechanism: the client merges a detection
	// into the plate row that already carries this id, and appends a new row
	// only when the id is new.
	InstanceID string `json:"instance_id"`

	Name       string `json:"name"`
	SearchTerm string `json:"search_term"`

	// Grams is 0 when the amount could not be estimated. The client then falls
	// back to the matched catalog food's serving weight, or to 100 g.
	Grams float64 `json:"grams"`

	Confidence float64 `json:"confidence"`

	// Shots are the ascending shot numbers this item appears in. Length > 1 is
	// what the plate row renders as `↺ N` and `shots 1·2·3, counted once`.
	Shots []int `json:"shots"`

	Emoji string `json:"emoji"`

	Kcal100g    float64 `json:"kcal_100g"`
	Protein100g float64 `json:"protein_100g"`
	Carb100g    float64 `json:"carb_100g"`
	Fat100g     float64 `json:"fat_100g"`
}

// PlateItem is one item the app already has staged, sent so the model reuses
// its id rather than minting a new one for food it has already been shown.
type PlateItem struct {
	InstanceID string  `json:"instance_id"`
	Name       string  `json:"name"`
	Grams      float64 `json:"grams"`
}

// modelReply is the JSON the model produces inside the completion's content
// string, validated against responseSchemaJSON.
//
// Items is a pointer so an absent or null `items` is distinguishable from an
// empty one. `[]` is a valid answer meaning "no food in these shots"; a missing
// field means the reply did not satisfy the schema and is worth one resend.
type modelReply struct {
	Items *[]Detection `json:"items"`
}

// detectRequest is the app's request body.
type detectRequest struct {
	// Shots are base64 JPEGs in shot order, shot 1 first. A data URL prefix is
	// tolerated and stripped.
	Shots []string `json:"shots"`

	// Plate is the currently staged plate, may be empty.
	Plate []PlateItem `json:"plate"`

	// Model is honoured only when ALLOW_MODEL_OVERRIDE is set.
	Model string `json:"model"`
}

// detectResponse is the app's success body. Model is echoed so a client log
// records which detector produced a plate.
type detectResponse struct {
	Model string      `json:"model"`
	Items []Detection `json:"items"`
}

// Error codes. The client switches on these rather than on the HTTP status,
// because several distinct failures share a status and each maps to different
// copy on the camera pane.
const (
	codeBadRequest    = "bad_request"
	codeUnauthorized  = "unauthorized"
	codeNotConfigured = "not_configured"
	codeNoConnection  = "no_connection"
	codeTimeout       = "timeout"
	codeUnreadable    = "unreadable"
	codeUpstreamError = "upstream_error"
	codeInternal      = "internal"
)

type errorBody struct {
	Error errorDetail `json:"error"`
}

type errorDetail struct {
	Code    string `json:"code"`
	Message string `json:"message"`

	// Status is the *upstream* status for codeUpstreamError, so the app can
	// render `detection failed · 429`. Absent otherwise.
	Status int `json:"status,omitempty"`
}
