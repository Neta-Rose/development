"""Pydantic models + the JSON schema enforced on LLM output (Stage 4).

The JSON schema is sent to OpenRouter via ``response_format`` (json_schema,
strict) and, for models that don't support structured outputs, reused as the
parameter schema of a forced tool call. Every response is additionally
validated with :class:`EnrichmentResult` before anything is persisted.
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
    "toasted",
]

# Keep the Literal and the config enum in lockstep.
assert set(PrepType.__args__) == set(config.PREP_TYPES)


class EnrichmentResult(BaseModel):
    """Validated LLM output for a single food item.

    No ``fdc_id``: the request carries exactly one food, so there is nothing to
    address and the model never handles a 7-digit number it could mangle. No
    ``notes`` either — the reviewer never saw them (they went to audit_log
    alone), so they were output tokens spent on nobody.
    """

    model_config = ConfigDict(extra="forbid")

    display_name: str = Field(min_length=1)
    emoji: str = Field(min_length=1)
    prep_type: Optional[PrepType] = None
    variable_fat: bool
    confidence: float = Field(ge=0.0, le=1.0)

    @field_validator("emoji")
    @classmethod
    def _one_emoji(cls, v: str) -> str:
        if not is_emoji(v):
            raise ValueError(f"expected a single food emoji, got {v!r}")
        return v


# NOTE: strict structured-output mode (OpenAI-style, which OpenRouter proxies)
# requires every property to appear in "required".
ENRICHMENT_JSON_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "display_name": {"type": "string"},
        "emoji": {"type": "string"},
        "prep_type": {
            "type": ["string", "null"],
            "enum": [*config.PREP_TYPES, None],
        },
        "variable_fat": {"type": "boolean"},
        "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    },
    "required": ["display_name", "emoji", "prep_type", "variable_fat", "confidence"],
    "additionalProperties": False,
}

RESPONSE_FORMAT: dict = {
    "type": "json_schema",
    "json_schema": {
        "name": "food_enrichment",
        "strict": True,
        "schema": ENRICHMENT_JSON_SCHEMA,
    },
}

# Fallback for models without json_schema support: force a tool call whose
# parameters are the same schema.
ENRICHMENT_TOOL: dict = {
    "type": "function",
    "function": {
        "name": "record_enrichment",
        "description": "Record the enrichment result for one food item.",
        "parameters": ENRICHMENT_JSON_SCHEMA,
    },
}

# --------------------------------------------------------------------------
# Stage 4b: the commonness pass — a separate, single-number enrichment
# --------------------------------------------------------------------------
class CommonnessResult(BaseModel):
    """How commonly a food is eaten / stocked in home kitchens, 0..1.

    The field is called ``c``, not ``commonness``: this is a one-number pass
    whose only job is to be cheap, and the key is repeated on every one of
    ~15k responses.
    """

    model_config = ConfigDict(extra="forbid")

    c: float = Field(ge=0.0, le=1.0)


COMMONNESS_JSON_SCHEMA: dict = {
    "type": "object",
    "properties": {"c": {"type": "number", "minimum": 0, "maximum": 1}},
    "required": ["c"],
    "additionalProperties": False,
}

COMMONNESS_RESPONSE_FORMAT: dict = {
    "type": "json_schema",
    "json_schema": {
        "name": "food_commonness",
        "strict": True,
        "schema": COMMONNESS_JSON_SCHEMA,
    },
}

COMMONNESS_TOOL: dict = {
    "type": "function",
    "function": {
        "name": "record_commonness",
        "description": "Record how commonly one food is eaten (0-1).",
        "parameters": COMMONNESS_JSON_SCHEMA,
    },
}

# --------------------------------------------------------------------------
# Stage 4c: the keywords pass — search terms, one list per food
# --------------------------------------------------------------------------
class KeywordsResult(BaseModel):
    """Search keywords for one food.

    The field is ``k`` for the same reason CommonnessResult's is ``c``: the key
    rides on every one of ~15k responses.
    """

    model_config = ConfigDict(extra="forbid")

    k: list[str] = Field(min_length=1)

    @field_validator("k")
    @classmethod
    def _clean(cls, v: list[str]) -> list[str]:
        """Lowercase, trim, dedupe (dict preserves order), cap the count.

        Cleaned rather than rejected: a duplicate or a stray capital is not a
        wrong answer, and re-sending the row to get the same keywords back in
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


# No minItems/maxItems: strict structured-output mode rejects them. The count
# is asked for in the instructions and capped in _clean above.
KEYWORDS_JSON_SCHEMA: dict = {
    "type": "object",
    "properties": {"k": {"type": "array", "items": {"type": "string"}}},
    "required": ["k"],
    "additionalProperties": False,
}

KEYWORDS_RESPONSE_FORMAT: dict = {
    "type": "json_schema",
    "json_schema": {
        "name": "food_keywords",
        "strict": True,
        "schema": KEYWORDS_JSON_SCHEMA,
    },
}

KEYWORDS_TOOL: dict = {
    "type": "function",
    "function": {
        "name": "record_keywords",
        "description": "Record the search keywords for one food.",
        "parameters": KEYWORDS_JSON_SCHEMA,
    },
}
