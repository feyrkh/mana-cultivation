class_name SpellFormResources

# User-focused resources
## Spent to progress research, perform spellcasting, etc. Consumed and regenerates relatively quickly.
const FOCUS := "focus"
## Spent to make forceful changes to spellforms, tweak spellform casts on the fly, or resist negative mental effects. Regenerates slowly.
const WILL := "will"
## Spent during research sessions on more powerful effects. Regenerates per session, and can be earned/spent using research actions.
const INTUITION := "intuit"


# Spellform focused resources
## How structurally sound a spellform is. Decreasing cohesion reduces the overall efficiency and effectiveness of a spell.
const COHESION := "cohesion"
## How refined a spellform is. Decreasing efficiency causes increased casting costs or will drain.
const EFFICIENCY := "efficiency"
## How unpredictable the spellform is. Increasing volatility makes the actual output less predictable, increases will costs for forceful changes to spell output at casting time.
const VOLATILITY := "volatility"

# Spellform-tile focused resources
## How firmly seated a tile is - increases reliability, decreases volatility, unlocks synergies with adjacent tiles
const INTEGRATION := "integration"
## Increases whenever tile integration is increased, making future changes more costly
const INERTIA := "inertia"
