# Ambient Animation Language — Foundations

A shared expressive vocabulary for the whole house (Home Assistant based). It starts with
light and must work on anything that emits it — a single bulb, a strip, a small panel, a
large screen — and extends to sound, haptics, text notifications and spoken
announcements (section 12).

**Goal: coherence in concept, varying fidelity.** Like Siri across Apple Watch → Apple TV,
form and detail change with the device. The idea, palette and temperament never do.

This document defines *meaning and behaviour*. How each device renders it is deliberately
left open, because target technologies differ wildly.

---

## 1. Core principles

1. **Calm is the ground everything stands on.** The house can get excited, but the way a
   calm person does: the voice lifts, and it's still warm and steady underneath.
2. **Represent, don't plot.** Animations express what something *means*, not raw data.
3. **The house has feelings, not settings.** Whenever it is awake, it is expressing a
   mood rather than sitting neutral. Only sleep and alarm read as neutral.
4. **Character lives in motion.** Moods differ by rhythm and contour, not just colour.
   That makes them fundamentals: even a single bulb can show them.
5. **Predictable, never uncanny.** Every pattern repeats and resolves. Nothing random,
   nothing that looks like a fault.
6. **One temperament everywhere.** Timing, easing and colour behaviour are identical on
   every device. People recognise a system by how it moves, not by its resolution.
7. **Fidelity adds detail, never meaning.** A richer device may say the same thing more
   beautifully or more specifically. It may never say something different from a simpler
   device.
8. **Silence is a message.** When nothing needs attention, nothing asks for it.
9. **Playful, never annoying.** Personality is seasoning. It never delays a response,
   obscures a meaning, or repeats itself into a tic.
10. **Relevance fades with distance.** Things matter most where they happen. The house
    responds like a ripple: fullest at the source, softer further away, and only as far
    as it needs to reach.

**Coherence test:** blur and shrink the richest rendering down to the simplest device. It
should look like what the simple device shows. If not, the rich version has become a
different concept.

**Bulb test:** three seconds on a single bulb should be enough for someone who knows the
house to name the mood and roughly how excited it is.

---

## 2. The model: mood × excitement × locality

The whole language is three dimensions.

- **Mood** is *what kind* of feeling: Jubilant, Tender, Thoughtful, Concerned, and so on.
- **Excitement** is *how much*: a single scale from asleep to alarm.
- **Locality** is *where*: every trigger has an origin and a blast radius, so the same
  trigger affects different places differently.

Each room therefore has its own mood and excitement. A trigger arrives in each room at
the strength its distance from the origin allows (see section 6).

Everything else in the house maps onto these:

| Input | Effect |
|---|---|
| **Events / reactions** (doorbell, light switched, arrival, message) | An excitement impulse that decays back to baseline; may also set the mood |
| **Information urgency** (supply low, device broken, door open) | A sustained excitement contribution, usually with the Concerned mood |
| **Active tasks** (work, relaxing, cooking, exercise, sleep, eating) | Set the mood and the baseline excitement |
| **Passive tasks** (laundry, dishes, charging) | A quiet background texture within the current level; no excitement of their own until they need attention |
| **Context** (time of day, sun, presence, weather, health) | Mostly moves the baseline; can bias which mood is chosen |

### How much mood shows depends on excitement

- **Near zero** there is barely enough energy to express anything, so sleep reads as
  neutral calm.
- **In the middle band** mood is most visible: the house is awake, expressive, at ease.
- **At the top** urgency takes over from flavour, so Alarm reads as its own clear,
  steady signal.

No special neutral states are needed; neutrality falls out of the scale.

---

## 3. The calm undertone

These rules apply to every mood, at every excitement level.

- **The breath never stops.** A slow, resting-pace breath runs beneath everything.
  Excitement rides on top of it; when excitement fades, the breath is what remains. This
  continuity is the core reassurance.
- **Soft edges everywhere.** Curves ease in and out, peaks are rounded, and nothing stops
  abruptly. Precision means "settles exactly," not "stops dead."
- **Excitement shows through rhythm and warmth more than brightness.** Intensity has a
  ceiling, so high excitement never becomes glaring.
- **Tempo has a ceiling.** Nothing approaches strobing; stay well under the three
  flashes per second that photosensitivity guidelines warn about.
- **No dips below baseline.** Sudden drops in brightness read as an electrical fault.
- **Every episode resolves.** Patterns repeat predictably and end with an exhale back to
  calm.
- **The palette leans warm.** Even cool colours are softened, never clinical or grey.
- **Human actions are answered instantly.** Every mood's character lives in how a
  response settles, never in a delay before it starts.

---

## 4. Moods

Each mood has a distinct **motion signature**, so moods stay separable even without
colour and even at high excitement. At low excitement every mood is a quiet version of
itself; at high excitement its signature is at its fullest, still within the calm
undertone.

| Mood | Motion signature | Colour | Quiet (low excitement) | Full (high excitement) | Examples |
|---|---|---|---|---|---|
| **Jubilant** | Gentle cushioned bounces, like a happy hum | Gold to warm white | A light lilt in the breath | Joyful bounces, each landing softly | You arrive home; team scores |
| **Triumphant** | One slow gracious swell, then a warm hold | Deep amber to full | A proud, fuller breath | A single broad crescendo and hold | Workout goal hit; big task finished |
| **Sassy** | A playful off-beat, then an easy settle; an affectionate wink | Coral and soft magenta | An occasional sly beat | A theatrical little flourish, quickly settled | Laundry done ages ago and still ignored |
| **Tender** | Large, slow, rounded blooms, like an embrace | Rose-amber | Soft, deep breathing | Warm blooms that fill the space | Partner arrives; goodnight; comfort |
| **Curious** | Unhurried, attentive glances that pause and look | Soft teal | An occasional gentle look towards something | Calm directional sweeps towards the source | Motion outside; package at the door |
| **Resolute** | Steady, even, soft-edged pulses; a calm competent guide | Softened cool white | A steady, measured breath | Clear, even pulses: "I've got this" | Timer ending; departure countdown |
| **Thoughtful** | A slow, continuous flow that circulates inward, like turning an idea over; no beats | Dusky violet, warmed | Quiet musing drift | Deeper, slightly quicker flow, still unhurried | Voice assistant thinking; waiting on an answer |
| **Concerned** | A gentle double pulse, like a considerate tap on the shoulder, repeating patiently; glances towards the problem | Steady amber-yellow | An occasional soft double tap | Firmer taps on a quicker but regular cycle | Something broken; door left open too long |

### How the moods stay distinct

- **Rhythm:** bounces, one swell, off-beat, slow blooms, glances, even pulses, continuous
  flow, double taps. Each is recognisable on a single bulb.
- **Direction** (an overtone, on spatial devices only): Tender and Jubilant expand outward, Curious looks
  outward towards something, Thoughtful gathers inward, Concerned keeps returning towards
  the problem.
- **Spend of energy:** Jubilant spends it in many beats, Triumphant in one, Tender
  spreads it slowly, Resolute holds it evenly, Thoughtful keeps it circulating.
- **Close neighbours:** Sassy is off-beat and expansive; Concerned is regular and
  contained. Resolute is confident even pulses; Concerned is a softer double tap with a
  pause.

### Mood notes

**Thoughtful** is the house attending to *you*, in the foreground, with someone waiting.
It never counts time in a readable way, so it avoids "spinner anxiety." It resolves with
an "aha": the flow gathers to a point and blooms into whatever mood the answer carries —
Jubilant for good news, Concerned if something needs attention. A long wait stays
Thoughtful; a genuine failure hands off honestly to Concerned rather than looping forever.

**Concerned** must never be uncanny. Its pattern is identical every cycle, it holds a
stable warm caution colour, and it never flickers or dims below baseline. It says "this
needs you," not "panic." When the problem is resolved, it ends with a slow relief exhale.

**Sassy** is teasing between friends. Its surprises are rationed and varied so they
stay delightful, and it yields to Concerned or Resolute once something becomes
important.

---

## 5. Excitement

### Bands

A continuous scale, with named bands so every device can show a clear level even without
a smooth gradient.

| Band | Meaning | Mood visibility |
|---|---|---|
| **Asleep** | Night, sleep, empty house | Almost none; just the resting breath |
| **Calm** | Occupied, at ease | Gentle, quiet form of the mood |
| **Attentive** | Something is happening | Mood clearly expressed |
| **Heightened** | Needs attention now | Mood at its fullest |
| **Alarm** | Safety | Mood yields to a clear, steady alarm signal |

### Rules

- **Baseline plus one contribution.** Context sets the resting level. Events and
  information add a contribution on top of it; event impulses decay back to baseline,
  and this decay is the house's gravity back to calm.
- **The largest contribution wins; contributions don't add up.** When several are active,
  only the largest counts, so three minor notices never add up to an alarm.
- **Rise promptly, fall slowly.** Responses to people feel instant; calming down is
  gradual and cools as it goes.
- **Hysteresis.** Bands don't flicker back and forth around a threshold.
- **Sleep is protected.** A room where someone is asleep is shielded: only direct human
  action in that room and safety can raise its excitement. Everything else waits until
  morning. (Empty rooms also rest in the Asleep band, but that is simply low baseline,
  not protection.)
- **Alarm is calm authority.** Unmistakable, bright and directive, but steady rather than
  frantic, like a calm pilot announcement. It supports dedicated smoke and CO alarms,
  which always remain the primary warning.

---

## 6. Locality and blast radius

Every trigger happens *somewhere* and matters to *some* places. Locality decides which
rooms respond and how strongly.

### Origin and radius

- **Origin** is where the trigger happens: the front door, the laundry room, the speaking
  device, the switch.
- **Blast radius** is how far it reaches.

| Radius | Reaches | Example |
|---|---|---|
| **Point** | Only the thing itself | Coffee machine low on beans |
| **Room** | The room it happens in | Light switched on; oven preheated |
| **Zone** | Neighbouring rooms, a floor, an open-plan area | Laundry done; kettle boiled |
| **House** | Every occupied room | Doorbell; someone arrives home |
| **Everywhere** | Every room, occupied or not, including sleeping rooms | Smoke, leak |
| **Person** | Follows one person to wherever they are | Their timer, their message, their wellbeing nudge |

### How it spreads

- **Falloff.** A room receives the trigger at excitement that drops with each step away
  from the origin. The origin gets the full expression; neighbours a softer one; the
  edge of the radius only the quiet form.
- **Mood travels further than excitement.** Distant rooms may only take on a gentle tint
  of the mood, with almost no rise in excitement.
- **A ripple, not a broadcast.** Rooms respond in order of distance, with a slight delay
  outward. Even with plain bulbs, the sequence tells you where it came from.
- **Distance is how people experience the home, not metres.** Open-plan spaces are close;
  a room behind a closed door upstairs is far.
- **Resolution contracts.** When a trigger resolves, it exhales from the edges inward,
  finishing at the origin.

### Rules

- **Most things stay local.** Small radius is the default; a trigger earns a wider radius
  through urgency or by genuinely concerning everyone.
- **Presence shapes the radius.** Wide radii only light up occupied rooms. There is no
  point expressing something to an empty room (except safety).
- **Sleeping rooms are walls.** They absorb everything except direct action within them
  and Critical triggers.
- **Escalation widens the radius.** An ignored item grows gradually: point, then room,
  then zone, then house, with urgency rising alongside.
- **Personal things stay personal.** Person-scoped triggers — health nudges, private
  messages, personal reminders — follow their owner and never spread to shared rooms when
  others are present.
- **Rooms combine by the same rule as excitement.** Each room keeps its own baseline, and
  of all the triggers reaching it, only the largest contribution counts.
- **Mood at a distance defers to local context.** A distant trigger can raise a room's
  excitement and tint it, but it only changes that room's mood if it's strong enough to
  matter there.

### Examples

- **Doorbell:** entry hall at full Curious; the living room Attentive with a Curious
  tint; a quiet tint in the kitchen; nothing in the bedroom where someone sleeps.
- **Laundry done:** a brief impulse in the laundry room's current mood, and a faint echo
  for the person responsible, wherever they are. If ignored, it widens slowly and turns Sassy,
  then Concerned.
- **Leak:** Alarm at the source, spreading everywhere, sleeping rooms included.

---

## 7. Mood changes

- **Moods crossfade, they don't switch.** A change of mood is a blend of motion and
  colour.
- **Events can change mood promptly.** An arrival can bring Jubilant or Tender straight
  away; a problem brings Concerned.
- **Context changes mood slowly.** Evening, weather or a new task shift the mood over
  minutes; you notice the room has changed, not the moment it changed.
- **Moods persist.** A mood holds until something gives it a reason to change. Reactions
  often change only excitement, not mood.
- **Origin matters.** Event-driven changes start where the cause is — the switch, the door,
  the speaking device — and spread only as far as their blast radius (section 6).
- **One change at a time per room.** New events retarget a change in progress rather
  than stacking.

---

## 8. Tasks

### Active tasks — what someone is doing

| Task | Mood tendency | Baseline excitement |
|---|---|---|
| Work | Resolute | Calm |
| Relaxation | Tender or Sassy | Calm, low |
| Sleep | — | Asleep |
| Eating | Tender or Jubilant (with company) | Calm |
| Cooking | Jubilant or Sassy | Attentive |
| Exercise | Resolute, then Triumphant at the finish | Attentive to Heightened |

### Passive tasks — what the house is doing

Laundry, dishes, charging, a print job. These are **undercurrents**: a quiet background
texture within the current level that says "something is working" without asking for
attention. They add no excitement until they need someone.

```
running        →  quiet background texture
done           →  a brief impulse in the current mood
ignored        →  becomes information at low urgency (a Sassy nudge suits low stakes)
still ignored  →  urgency slowly rises; Sassy gives way to Concerned
```

A sassy house might give the finished laundry a pointed little nudge. It stops teasing
once the matter becomes important — for example, a freezer left open or a leak. This lifecycle is the template for escalation across
the system: gently, and only when warranted.

---

## 9. Information

State of the world that stays true until something changes: supplies running low, a
device offline, a door left open, a filter due. Information usually carries the
**Concerned** mood (low-stakes items may use Sassy instead); urgency sets its excitement.

| Urgency | Example | Excitement at origin | Blast radius |
|---|---|---|---|
| **Ambient** | Coffee running low | Calm | Point: only at the thing |
| **Notice** | Filter due today | Attentive | Room, plus the responsible person |
| **Warning** | Freezer offline, door open too long | Heightened | Occupied rooms, house-wide |
| **Critical** | Smoke, leak | Alarm | Everywhere, including sleeping rooms |

- **Urgency widens the radius.** As information escalates, it reaches further as well as
  getting more excited.
- **Persistent, not re-notifying.** It is one continuous expression until resolved
  (Concerned's patient double pulse), never a series of fresh alerts.
- **Resolution ends with relief.** Fixing the problem gets a slow exhale back to calm.

---

## 10. Context and wellbeing

- **Time of day and sun:** the baseline follows the day, low at night and rising through
  the morning; warmth follows the sun.
- **Presence:** people present raise the baseline slightly; nobody home lowers it
  towards Asleep.
- **Weather:** can bias mood choice and softness, never urgency.
- **Health and wellbeing:** poor sleep or low energy lowers the baseline and favours
  gentler moods such as Tender.

Health principles: opt-in only, private, never labelled, never shown in shared spaces when
others are present, and always a nudge, never a verdict.

---

## 11. Fidelity

Detail is additive, like harmonics on a fundamental.

- **Fundamentals:** what every device can show — the resting breath, each mood's rhythm,
  its colour path and the excitement level. Identical everywhere.
- **Overtones:** extra detail richer devices add — more strokes, texture, depth, direction
  and spatial movement. They follow the fundamentals and never move independently.
- **Normalise energy.** More detail means richer, not brighter or busier.
- **Form follows the container.** A round display, a strip, a wall of light and a screen
  can each take a different shape, as long as meaning, rhythm, palette and the calm
  undertone hold.

If a room can't express something, it falls back to another device in the same room, or
within the blast radius.

**Locality between rooms is a fundamental; direction within a device is an overtone.**
Which rooms respond, how strongly and in what order can be shown by plain bulbs. Pointing
or sweeping towards a source inside one display is extra detail.

---

## 12. Modalities and orchestration

### The fundamental is a score, not light

Mood (rhythm and envelope in time), excitement (intensity) and locality (place) form a
**score**. Light is the first instrument to play it. Other devices are further
instruments reading the same score, each contributing the overtones it's capable of.

| Instrument | What it can play |
|---|---|
| **Dimmable bulb** | The envelope only |
| **Strip, panel, screen** | + space, form, texture |
| **Slow actuators** (blinds, fan, heating) | Only the slowest parts: the day's arc, gradual warm-up |
| **Speaker (non-verbal)** | + timbre and pitch |
| **Haptics** (watch, phone) | + touch, private to the wearer |
| **Text notification** | + specific words |
| **Spoken announcement (TTS)** | + words, voice and delivery |

Composition is orchestration: the same phrase, voiced by whatever instruments are in
range.

### Principles

- **Richer instruments add specificity, never a different message.** A bulb says
  "Concerned, near the kitchen"; the phone says "Freezer door open." Words must never
  contradict the light — no cheerful phrasing under a Concerned glow.
- **Every modality passes its own bulb test.** Concerned's double tap should read as two
  soft notes, two wrist taps, or two amber pulses, each on its own.
- **Map by contour.** A rise in brightness is a rise in pitch; a bounce is a springy
  pluck; Thoughtful's continuous flow is a sustained swell; Tender's bloom is a warm pad.
- **One family per modality.** One sonic family, one haptic language and one voice across
  every mood, so everything is recognisably the same house.
- **One clock.** When modalities fire together, they land together. Sound, light and touch
  fuse into a single event only when closely synchronised (on the order of 100 ms or
  less), so sync matters more than any individual curve.

### Excitement recruits modalities

Modalities differ in intrusiveness: light is ambient, touch is personal, sound is shared
and carries through walls. So excitement doesn't just intensify the signal — it recruits
channels as it climbs.

| Band | Channels |
|---|---|
| **Calm** | Light; silent text (can be batched into a digest) |
| **Attentive** | + haptic and text for the person concerned |
| **Heightened** | + non-verbal sound or spoken announcement in occupied rooms |
| **Alarm** | Everything, everywhere |

This is the calm undertone applied to the senses, and it makes "silence is a message"
literal. The ambient breath stays visual: sound and haptics fatigue far faster than
light, so they belong to events, not the background.

### Locality and modalities

- **Haptics and text are the purest Person-radius channels.** Only the owner feels or
  reads them.
- **Sound has a large, leaky radius.** It passes through walls, so it needs strict
  budgeting and respects sleeping-room walls even more carefully than light.
- **Speak where it matters:** at the origin or wherever the relevant person is, louder
  near the origin than further away.
- **Detail scales with privacy.** A shared room hears "There's a message for Simon";
  Simon's phone shows the message itself. Health nudges are only ever text to the person.

### Language: text and voice

Words are the richest instrument. Mood sets the tone; excitement sets length, directness
and channel; locality sets who hears and how much detail.

**Mood sets the voice**

| Mood | Text tone | Spoken delivery |
|---|---|---|
| **Jubilant** | Bright, warm, brief | Lifted pitch, lively pace |
| **Triumphant** | Proud, affirming | Warm, fuller, unhurried |
| **Sassy** | Wry, affectionate teasing | Playful intonation, a knowing pause |
| **Tender** | Gentle, no pressure | Softer, slower, lower volume |
| **Curious** | Observational, open | A slight questioning lift |
| **Resolute** | Plain, crisp, confident | Even, clear pace |
| **Thoughtful** | Considered: "Let me check…" | Measured, with natural pauses |
| **Concerned** | Calm, clear, caring | Slightly slower and steady, never tense |

Example — laundry done:

- **Resolute:** "Laundry's done."
- **Tender:** "Your laundry's finished, whenever you're ready."
- **Jubilant:** "Laundry's done — fresh and ready."
- **Sassy (ignored):** "The laundry's been waiting a while. It's starting to feel
  forgotten."
- **Concerned (long ignored):** "Laundry's been sitting for three hours — worth moving it
  soon."

**Excitement sets length and directness**

- **Calm:** loose and friendly; may be batched.
- **Attentive:** the point in the first few words.
- **Heightened:** short and actionable — what, where, what to do.
- **Alarm:** plain and directive, no personality. "Smoke detected in the kitchen. Please
  leave the house now."
- **Resolution always closes the loop:** "Freezer's closed again — all good."

**Words and light move as one**

The room enters the mood first, like an intake of breath, and the voice follows almost
immediately. The announcement rides the mood's envelope, and a text's arrival haptic taps
in the mood's rhythm.

**The calm undertone for language**

- Warm and plain: no shouting, no exclamation spam, no "WARNING."
- Reassuring even when concerned: say what's wrong and what to do, never just that
  something is wrong.
- One consistent persona and voice across text, speech and devices.
- Predictable phrasing: the same situation is said the same way; variety is limited to
  rationed Sassy touches.
- Humour never touches bad news, safety, or anyone's health or body.
- Escalation raises urgency, not snark. Never guilt-tripping or nagging.
- Meaning is always in the words; tone never has to carry it alone.

### Accessibility and preference

Multiple modalities are an accessibility gift: someone who can't hear gets touch and
light; someone who can't see gets sound and voice. Each person can choose which
instruments play for them, and the score still comes through.

---

## 13. Open questions

- The one-sentence visual motif every device renders.
- The palette: one colour family covering all moods and urgency.
- The resting mood: what the house expresses when nothing specific has set a mood.
- Exact rhythm, tempo and colour values per mood, and at each excitement band.
- Excitement thresholds, decay rates and ceilings for brightness and tempo.
- How often Sassy surprises are allowed, and how they vary.
- The home's adjacency map: which rooms count as near each other (open plan, doors,
  floors), and which rooms form zones.
- Default blast radius for each trigger type, and falloff per step of distance.
- Propagation delay between rooms.
- Which devices carry which parts, and fallback rules.
- How active tasks are detected; health opt-in scope and privacy boundaries.
- The sonic family: the house's non-verbal sound palette and how each mood's contour
  maps to it.
- Haptic patterns per mood, per wearable or phone.
- The voice persona: name (if any), TTS voice, and wording templates per mood and
  excitement band. (Drafted by Claude Code, tuned by ear.)
- Per-person modality preferences and accessibility defaults.
- Digest rules: what gets batched at Calm, and when digests are delivered.
