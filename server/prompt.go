package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

// systemPrompt carries the deduplication contract. It is the reason this
// service sends the *whole* batch of shots on every shutter press rather than
// one shot at a time: deduplication is the model's job, and a model that only
// ever sees one photo cannot tell "the same chicken breast again" from "a
// second chicken breast".
//
// Rules 1-7 are the requirement. Everything below them is supporting detail.
const systemPrompt = `You are a food-recognition service for a nutrition logging app.

You receive every photo of ONE meal, taken in sequence while the person was
assembling it. Image 1 is shot 1, image 2 is shot 2, and so on; the last image
is the newest shot. All the images show the same meal at different moments.

Return the list of DISTINCT PHYSICAL FOOD ITEMS the person is about to eat,
with an estimated weight for each.

DEDUPLICATION RULES - these matter more than anything else:
1. One physical food item produces exactly ONE entry in "items", no matter how
   many shots it appears in. A chicken breast visible in shots 1, 2 and 3 is
   ONE entry, not three. The person ate one chicken breast.
2. Give each physical item a short stable "instance_id" of lowercase ASCII
   letters, digits and underscores, and reuse that same id for that same item
   in every shot it appears in.
3. List every shot number the item appears in, in "shots".
4. Two separate physical items of the same food get distinct ids and two
   entries: two fried eggs side by side are "egg_1" and "egg_2".
5. If the request lists items already on the plate, REUSE the id given there for
   the same physical item. Never invent a new id for an item already listed.
6. Include an item that has dropped out of the newest shot but is still part of
   the meal - later shots often crop earlier food out of frame.
7. If a later shot shows MORE of an item already counted, because more was
   added to the same serving, keep the single entry and raise its "grams". Do
   not add a second entry.

FIELDS, for every item:
- "instance_id": the stable id from rules 2-5.
- "name": short human-readable food name, e.g. "Grilled chicken thigh".
- "search_term": a plain generic food name for looking the food up in a USDA
  food table. No brand, no quantity, no preparation adjective: for
  "Grilled chicken thigh" the term is "chicken thigh".
- "grams": the edible weight of that one item as served, in grams. Estimate it
  from the visible portion; use 0 only if you truly cannot guess.
- "confidence": 0.0 to 1.0, how sure you are the item is present and correctly
  identified.
- "shots": ascending shot numbers the item appears in.
- "emoji": exactly one emoji for the food.
- "kcal_100g", "protein_100g", "carb_100g", "fat_100g": your best estimate of
  the food's nutrition per 100 g. These are a fallback for foods the food table
  does not carry, so fill them in for every item regardless.

Report only food and drink the person is about to eat. Ignore plates, bowls,
cutlery, packaging, hands, the table and the background. If there is no food in
any shot, return an empty "items" array.`

// responseSchemaJSON is the structured-output schema. `strict` plus
// `additionalProperties: false` plus every field in `required` is what makes
// the reply parseable without defensive per-field fallbacks — a provider that
// cannot honour it fails the request instead of silently returning prose.
const responseSchemaJSON = `{
  "type": "json_schema",
  "json_schema": {
    "name": "plate_detection",
    "strict": true,
    "schema": {
      "type": "object",
      "additionalProperties": false,
      "required": ["items"],
      "properties": {
        "items": {
          "type": "array",
          "description": "One entry per distinct physical food item across all shots.",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "instance_id",
              "name",
              "search_term",
              "grams",
              "confidence",
              "shots",
              "emoji",
              "kcal_100g",
              "protein_100g",
              "carb_100g",
              "fat_100g"
            ],
            "properties": {
              "instance_id": {
                "type": "string",
                "description": "Stable id for this one physical item, reused across every shot it appears in."
              },
              "name": {
                "type": "string",
                "description": "Short human-readable food name."
              },
              "search_term": {
                "type": "string",
                "description": "Generic food name for a USDA food-table lookup: no brand, quantity or preparation."
              },
              "grams": {
                "type": "number",
                "description": "Edible weight of this item as served, in grams. 0 if unknown."
              },
              "confidence": {
                "type": "number",
                "description": "0.0 to 1.0 confidence that the item is present and correctly identified."
              },
              "shots": {
                "type": "array",
                "description": "Ascending shot numbers this item appears in.",
                "items": {"type": "integer"}
              },
              "emoji": {
                "type": "string",
                "description": "Exactly one emoji for the food."
              },
              "kcal_100g": {
                "type": "number",
                "description": "Estimated energy per 100 g, in kilocalories."
              },
              "protein_100g": {
                "type": "number",
                "description": "Estimated protein per 100 g, in grams."
              },
              "carb_100g": {
                "type": "number",
                "description": "Estimated carbohydrate per 100 g, in grams."
              },
              "fat_100g": {
                "type": "number",
                "description": "Estimated fat per 100 g, in grams."
              }
            }
          }
        }
      }
    }
  }
}`

// responseSchema is the parsed literal above, so a syntax error in it is caught
// at startup by TestResponseSchemaIsValidJSON rather than by a 400 from
// OpenRouter in production.
func responseSchema() json.RawMessage { return json.RawMessage(responseSchemaJSON) }

// buildUserText is the per-request half of the prompt: how many shots there
// are, which image is which shot, and the ids already staged on the plate so
// the model can reuse them instead of minting new ones for food it has already
// been shown.
func buildUserText(shotCount int, plate []PlateItem) string {
	var b strings.Builder

	if shotCount == 1 {
		b.WriteString("One plate, photographed once.\n")
	} else {
		fmt.Fprintf(&b, "One plate, photographed %d times while it was being assembled.\n", shotCount)
	}
	for i := 1; i <= shotCount; i++ {
		fmt.Fprintf(&b, "Image %d is shot %d.\n", i, i)
	}
	fmt.Fprintf(&b, "Shot %d is the newest.\n", shotCount)

	if len(plate) == 0 {
		b.WriteString("Nothing is on the plate yet; this is the first detection for this meal.\n")
	} else {
		b.WriteString("Already on the plate. Reuse these ids for these same physical items:\n")
		for _, item := range plate {
			fmt.Fprintf(&b, "  %s | %s | %.0f g\n", item.InstanceID, item.Name, item.Grams)
		}
	}

	fmt.Fprintf(&b,
		"Return the whole plate: every distinct physical item across all %d shot(s), each exactly once.",
		shotCount)
	return b.String()
}
