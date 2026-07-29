package main

import (
	"encoding/json"
	"strings"
	"testing"
)

// The schema is a string literal, so nothing but a test stops a stray comma from
// reaching production as a 400 from OpenRouter.
func TestResponseSchemaIsValidAndComplete(t *testing.T) {
	var format struct {
		Type       string `json:"type"`
		JSONSchema struct {
			Name   string `json:"name"`
			Strict bool   `json:"strict"`
			Schema struct {
				Properties struct {
					Items struct {
						Items struct {
							Required             []string `json:"required"`
							AdditionalProperties *bool    `json:"additionalProperties"`
							Properties           map[string]struct {
								Type string `json:"type"`
							} `json:"properties"`
						} `json:"items"`
					} `json:"items"`
				} `json:"properties"`
			} `json:"schema"`
		} `json:"json_schema"`
	}

	if err := json.Unmarshal([]byte(responseSchemaJSON), &format); err != nil {
		t.Fatalf("response schema is not valid JSON: %v", err)
	}
	if format.Type != "json_schema" || !format.JSONSchema.Strict {
		t.Fatalf("format = %q strict = %v", format.Type, format.JSONSchema.Strict)
	}

	item := format.JSONSchema.Schema.Properties.Items.Items
	if item.AdditionalProperties == nil || *item.AdditionalProperties {
		t.Error("item additionalProperties must be false")
	}

	// Every field the client reads must be required, or a strict-mode reply can
	// omit it and the Dart model has to invent a default for it.
	want := []string{
		"instance_id", "name", "search_term", "grams", "confidence", "shots",
		"emoji", "kcal_100g", "protein_100g", "carb_100g", "fat_100g",
	}
	required := map[string]bool{}
	for _, r := range item.Required {
		required[r] = true
	}
	for _, field := range want {
		if !required[field] {
			t.Errorf("%q is not in required", field)
		}
		if _, ok := item.Properties[field]; !ok {
			t.Errorf("%q has no property definition", field)
		}
	}
	if len(item.Required) != len(want) {
		t.Errorf("required has %d fields, want exactly %d", len(item.Required), len(want))
	}
}

// The dedup contract is prompt text, so it is worth asserting it is actually in
// the prompt: a refactor that drops it produces triple-logged chicken and no
// test failure anywhere else.
func TestSystemPromptCarriesTheDeduplicationRules(t *testing.T) {
	for _, fragment := range []string{
		"exactly ONE entry",
		"instance_id",
		"reuse that same id",
		"REUSE the id given there",
		"distinct ids",
		"shots",
	} {
		if !strings.Contains(systemPrompt, fragment) {
			t.Errorf("system prompt is missing %q", fragment)
		}
	}
}

func TestBuildUserTextMapsImagesToShots(t *testing.T) {
	got := buildUserText(3, nil)

	for _, want := range []string{
		"photographed 3 times",
		"Image 1 is shot 1.",
		"Image 2 is shot 2.",
		"Image 3 is shot 3.",
		"Shot 3 is the newest.",
		"Nothing is on the plate yet",
		"across all 3 shot(s), each exactly once",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("user text is missing %q\n---\n%s", want, got)
		}
	}
}

func TestBuildUserTextListsEveryStagedItem(t *testing.T) {
	plate := []PlateItem{
		{InstanceID: "chicken_1", Name: "Chicken thigh", Grams: 140},
		{InstanceID: "salad_1", Name: "Mixed leaf salad", Grams: 85.4},
	}

	got := buildUserText(2, plate)

	if !strings.Contains(got, "Reuse these ids") {
		t.Error("user text does not ask the model to reuse staged ids")
	}
	for _, want := range []string{
		"chicken_1 | Chicken thigh | 140 g",
		"salad_1 | Mixed leaf salad | 85 g",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("user text is missing %q\n---\n%s", want, got)
		}
	}
}

func TestBuildUserTextHandlesASingleShot(t *testing.T) {
	got := buildUserText(1, nil)
	if !strings.Contains(got, "photographed once") {
		t.Errorf("single-shot text reads oddly:\n%s", got)
	}
	if !strings.Contains(got, "Shot 1 is the newest.") {
		t.Error("single-shot text does not name the newest shot")
	}
}
