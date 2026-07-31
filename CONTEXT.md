# Food logging

A calorie and macro tracker. The user logs what they ate by searching a food
catalogue, typing an entry by hand, photographing a plate, or scanning a
barcode.

## Language

### Foods

**Catalog food**:
A food from the read-only USDA catalogue shipped with the app. Carries a full
nutrient vector and its own measures.
_Avoid_: USDA food, stock food, library food

**Custom food**:
A food the user owns rather than one the catalogue supplies. Created by typing
one in, by materialising a detected or scanned food, or by building a recipe.
_Avoid_: saved food, user food, own food, my food

**Recipe**:
A custom food built from ingredients and steps. It is a custom food in every
other respect — it is logged, searched, and referenced the same way.
_Avoid_: meal, dish, composite food

**Unsaved food**:
A named food that carries macros but is not yet a custom food. Quick add, plate
detection and barcode scan all produce one; it becomes a custom food only when
the batch is logged.
_Avoid_: quick entry (names only one of the three producers), draft food,
temporary food, pending food

**Hit**:
One food as the search screen presents it — catalog food, custom food and
unsaved food alike, so the results list has a single row type. Recently logged
foods are also hits.
_Avoid_: result, match, search item

**Item**:
A food as a user recognizes it — one row in the search list, however many
catalogue records stand behind it. Chicken thigh is one item, not 56.
_Avoid_: merged food, group, family

**Preparation**:
One way a food is prepared — raw, boiled, roasted. An item has one or more; each
is a catalog food in its own right, with its own macros, serving and measures.
_Avoid_: variant, prep type, cooking method

### Logging

**Batch**:
The foods staged on the search screen, with their amounts, before anything is
written. Leaving the screen discards it.
_Avoid_: cart, basket, draft log, pending entries

**Portion**:
A chosen amount of one food — a quantity, a named unit, and the gram weight it
resolves to.
_Avoid_: serving (that is the food's own defined amount, not the user's choice),
measure, helping

**Serving**:
A food's own defined amount, as the packet or the catalogue states it. A food
may have none, in which case it reads as per 100 g.
_Avoid_: portion, default amount
