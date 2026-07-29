package main

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
)

// Detector turns a batch of shots into a deduplicated plate.
type Detector struct {
	client *openRouterClient
	cfg    Config
}

func NewDetector(cfg Config, client *openRouterClient) *Detector {
	return &Detector{client: client, cfg: cfg}
}

// Detect sends the whole batch and returns one entry per distinct physical food
// item across all of it.
//
// A reply that does not parse is resent exactly once, because a schema slip is
// usually a sampling accident and a second draw usually fixes it. A network,
// timeout or HTTP failure is never resent: those are not going to answer
// differently inside the same request, and the app already offers a retry
// control the user drives.
//
// Both attempts share one wall-clock budget, so a resend cannot push the total
// past what the app is prepared to wait for.
func (d *Detector) Detect(
	ctx context.Context,
	model string,
	shots [][]byte,
	plate []PlateItem,
) ([]Detection, error) {
	if !d.cfg.Configured() {
		return nil, errNotConfigured
	}
	if len(shots) == 0 {
		return nil, errors.New("detect: no shots")
	}

	ctx, cancel := context.WithTimeout(ctx, d.cfg.UpstreamBudget)
	defer cancel()

	userText := buildUserText(len(shots), plate)

	var lastErr error
	for attempt := 0; attempt < 2; attempt++ {
		content, err := d.client.complete(ctx, model, userText, shots)
		if err == nil {
			items, perr := parseReply(content, len(shots), plate)
			if perr == nil {
				return items, nil
			}
			err = perr
		}
		// Only an unreadable reply earns the resend.
		if !errors.Is(err, errUnreadable) {
			return nil, err
		}
		lastErr = err
	}
	return nil, lastErr
}

// parseReply validates the model's content string and normalises it.
func parseReply(content string, shotCount int, plate []PlateItem) ([]Detection, error) {
	var reply modelReply
	if err := json.Unmarshal([]byte(stripCodeFence(content)), &reply); err != nil {
		return nil, errUnreadable
	}
	if reply.Items == nil {
		return nil, errUnreadable
	}

	raw := *reply.Items
	items := normalizeDetections(raw, shotCount, plate)

	// An empty answer is a real answer: no food in these shots. But rows that all
	// fail normalisation mean the model produced the right shape with unusable
	// contents, which is exactly what a resend can fix.
	if len(raw) > 0 && len(items) == 0 {
		return nil, errUnreadable
	}
	return items, nil
}

// stripCodeFence unwraps a ```json ... ``` block. Structured outputs should
// never produce one, but a provider that quietly ignores response_format often
// does, and unwrapping is cheaper than a resend that hits the same provider.
func stripCodeFence(s string) string {
	t := strings.TrimSpace(s)
	if !strings.HasPrefix(t, "```") {
		return t
	}
	if i := strings.IndexByte(t, '\n'); i >= 0 {
		t = t[i+1:]
	} else {
		t = strings.TrimPrefix(t, "```")
	}
	if i := strings.LastIndex(t, "```"); i >= 0 {
		t = t[:i]
	}
	return strings.TrimSpace(t)
}
