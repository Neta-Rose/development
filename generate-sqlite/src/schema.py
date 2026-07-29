"""Pydantic models + the JSON schemas enforced on LLM output.

Each schema is sent to OpenRouter via ``response_format`` (json_schema, strict)
and, for models that don't support structured outputs, reused as the parameter
schema of a forced tool call. Every response is additionally validated with the
matching pydantic model before anything is persisted.

Two passes, two shapes:

* **Stage 3b-1** (:class:`CanonResult` / :class:`CanonBatch`) asks what a food
  *is* — one answer per USDA row, many rows per request. This runs before
  clustering, and its ``base`` field is what clustering groups on.
* **Stage 4** (:class:`GroupResult`) asks how to *present* an item once it has
  been grouped — one item per request.

Both address their subjects by a 0-based index the model echoes back, never by
fdc_id: the model never handles a 7-digit number it could mangle, and the echo
turns a mis-mapped answer into a re-send instead of silently putting one food's
answer on another.
"""
from __future__ import annotations

import unicodedata
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from . import config


ZWJ = "‍"


def is_emoji(value: str) -> bool:
    """True for a single emoji — one grapheme cluster, nothing ASCII.

    Guards the one free-text enum-ish field: the model is asked for one food
    emoji and will occasionally answer with a word, an ASCII fallback like
    ":)", or two emoji. Checked with unicodedata rather than a hand-maintained
    codepoint-range table, because the ranges move with every Unicode release.

    Presentation machinery is stripped before counting, so a valid emoji is
    never rejected on its written form alone: skin-tone modifiers, variation
    selectors and other combining/format marks. A ZWJ sequence (👨‍🍳) is many
    codepoints but renders as one glyph, so each ZWJ-joined part is counted
    separately and all must be single emoji.

    Python has no grapheme segmentation in the stdlib and this does not need
    the `regex` dependency to approximate one for a 1-character field.
    """
    if not value:
        return False
    for part in value.split(ZWJ):
        stripped = "".join(
            c for c in part
            if unicodedata.category(c) not in ("Mn", "Me", "Cf")
            and not (0x1F3FB <= ord(c) <= 0x1F3FF)  # skin-tone modifiers
        )
        if len(stripped) != 1 or stripped.isascii():
            return False
    return True

PrepType = Literal[
    "raw", "cooked", "roasted", "baked", "boiled", "fried", "grilled",
    "steamed", "braised", "broiled", "dried", "canned", "frozen", "smoked",
    "toasted", "poached", "scrambled", "stewed", "microwaved", "sauteed",
    "blanched", "pickled", "cured", "breaded", "drained",
]

# Keep the Literal and the config enum in lockstep.
assert set(PrepType.__args__) == set(config.PREP_TYPES)


FoodKind = Literal["ingredient", "dish"]

assert set(FoodKind.__args__) == set(config.FOOD_KINDS)


class CanonResult(BaseModel):
    """What one USDA row *is*, extracted from its description (Stage 3b-1).

    The three fields are the three questions the old threshold-based clustering
    could not answer, and separating them is the whole design:

    * ``base`` is identity. Everything the description says about how the food
      was cooked, graded or trimmed has been removed, so two rows of the same
      food produce the same string however differently they were worded — and
      two different foods produce different strings however similar their
      wording. Clustering is then an exact match on it.
    * ``kind`` is the dish/ingredient split, which no amount of word overlap
      recovers. It is a hard guard on grouping, not a hint.
    * ``prep`` is the preparation, read off the description rather than
      inferred from a macro contrast. That inversion is what stops the same
      food recorded in two USDA databases with different macros from becoming
      two preparations nobody can name.
    """

    model_config = ConfigDict(extra="forbid")

    i: int = Field(ge=0)
    base: str = Field(min_length=1)
    kind: FoodKind
    prep: Optional[PrepType] = None

    @field_validator("base")
    @classmethod
    def _tidy(cls, v: str) -> str:
        """Collapse whitespace and drop stray punctuation.

        Cleaned rather than rejected: "Rice, white," is the right answer typed
        untidily, and re-sending 40 foods to get one comma back is paying twice
        for punctuation. Nothing left after tidying IS a wrong answer — checked
        here rather than by min_length, which sees the untidied value.
        """
        tidied = " ".join(v.split()).strip(" ,;")
        if not tidied:
            raise ValueError(f"no identity in {v!r}")
        return tidied


class CanonBatch(BaseModel):
    """One request's worth of canonicalizations.

    The batch is the unit because consistency is: the candidates in one request
    are description-adjacent, so the model sees "Rice, white, raw" beside
    "Rice, white, steamed" and writes one base name for both. Asking per food
    would be the same token count and would lose exactly that.
    """

    model_config = ConfigDict(extra="forbid")

    foods: list[CanonResult] = Field(min_length=1)


class GroupResult(BaseModel):
    """Validated LLM output for one merged item (Stage 4).

    Presentation only. Everything factual about the item was settled before
    this request was built: ``variable_fat`` is measured over the group,
    ``prep_type`` was read off each member's description in Stage 3b-1, and the
    membership itself is a base_name match. No ``merged_food_id`` either — the
    request carries exactly one item, so there is nothing to address.
    """

    model_config = ConfigDict(extra="forbid")

    display_name: str = Field(min_length=1)
    emoji: str = Field(min_length=1)
    commonness: float = Field(ge=0.0, le=1.0)
    keywords: list[str] = Field(min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)

    @field_validator("emoji")
    @classmethod
    def _one_emoji(cls, v: str) -> str:
        if not is_emoji(v):
            raise ValueError(f"expected a single food emoji, got {v!r}")
        return v

    @field_validator("keywords")
    @classmethod
    def _clean(cls, v: list[str]) -> list[str]:
        """Lowercase, trim, dedupe (dict preserves order), cap the count.

        Cleaned rather than rejected: a duplicate or a stray capital is not a
        wrong answer, and re-sending the item to get the same keywords back in
        lowercase would be paying twice for punctuation. A term longer than
        LONGEST_KEYWORD is a sentence, not a search term — that IS a wrong
        answer, so it is dropped.
        """
        out = list({
            kw.strip().lower(): None
            for kw in v
            if 0 < len(kw.strip()) <= config.LONGEST_KEYWORD
        })
        if not out:
            raise ValueError(f"no usable keywords in {v!r}")
        return out[: config.MAX_KEYWORDS]


# NOTE: strict structured-output mode (OpenAI-style, which OpenRouter proxies)
# requires every property to appear in "required", and rejects minItems /
# maxItems — the keyword count lives in the instructions and in _clean's cap
# instead. Nested objects are inlined rather than referenced: $ref is the one
# construct strict mode does not reliably accept.
GROUP_JSON_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "display_name": {"type": "string"},
        "emoji": {"type": "string"},
        "commonness": {"type": "number", "minimum": 0, "maximum": 1},
        "keywords": {"type": "array", "items": {"type": "string"}},
        "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    },
    "required": ["display_name", "emoji", "commonness", "keywords", "confidence"],
    "additionalProperties": False,
}

CANON_JSON_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "foods": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "i": {"type": "integer"},
                    "base": {"type": "string"},
                    "kind": {"type": "string", "enum": list(config.FOOD_KINDS)},
                    "prep": {
                        "type": ["string", "null"],
                        "enum": [*config.PREP_TYPES, None],
                    },
                },
                "required": ["i", "base", "kind", "prep"],
                "additionalProperties": False,
            },
        },
    },
    "required": ["foods"],
    "additionalProperties": False,
}


def _response_format(name: str, json_schema: dict) -> dict:
    return {
        "type": "json_schema",
        "json_schema": {"name": name, "strict": True, "schema": json_schema},
    }


def _tool(name: str, description: str, json_schema: dict) -> dict:
    """Fallback for models without json_schema support: a forced tool call
    whose parameters are the same schema."""
    return {
        "type": "function",
        "function": {
            "name": name, "description": description, "parameters": json_schema,
        },
    }


RESPONSE_FORMAT = _response_format("food_group_enrichment", GROUP_JSON_SCHEMA)
ENRICHMENT_TOOL = _tool(
    "record_enrichment", "Record the presentation fields for one food item.",
    GROUP_JSON_SCHEMA,
)

CANON_RESPONSE_FORMAT = _response_format("food_canonicalization", CANON_JSON_SCHEMA)
CANON_TOOL = _tool(
    "record_canonicalization",
    "Record the base name, kind and preparation of each food in the batch.",
    CANON_JSON_SCHEMA,
)
