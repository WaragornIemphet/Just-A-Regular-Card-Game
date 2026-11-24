# JARCG (Just A Regular Card Game)

A tactical card game built in **Godot (GDScript)**, digitized from an original physical **paper-and-calculator prototype** into a modular, event-driven digital battle system.

---

## Team & Role Breakdown

**JARCG** is a **2-person collaborative project** with a clear separation between systems engineering and visual presentation:

| Role | Contributor | Responsibilities |
| :--- | :--- | :--- |
| **Project Owner & Back-End Developer** | **Waragorn Iemphet** | System architecture, core battle loop, Finite State Machine (FSM), card/ability/passive/synergy managers, combat stance logic, debugging, and project management |
| **UI / Graphic & VFX Designer** | Teammate | Visual effects (VFX), graphic assets, card visuals, and UI/UX layout |

---

## Software Architecture & Engineering Highlights

- **Finite State Machine (FSM) Battle Flow:** Governs turn phases, player/AI actions, and combat state transitions cleanly without tangled conditional spaghetti.
- **Composition over Inheritance (`card.gd` & `abilitymanager.gd`):** Decouples card data from executable skills so new abilities and card effects can be composed modularly.
- **Event-Driven Observer Pattern (`base_passive.gd` & `passive_manager.gd`):** Listens for combat triggers and dispatches passive effects dynamically across active units.
- **Modular Combat Systems:**
  - `synergy_manager.gd` — Evaluates team/card combinations and applies dynamic synergy bonuses.
  - `ModeManager` — Handles multi-mode combat stances and mid-match stance switching.
  - **Trap / Hidden Card System** — Manages face-down/hidden triggers and reactive board states.
  - `battlelogic.gd` — Encapsulates shared rules and combat resolution inherited by both player and AI controllers (`enemy_ai.gd`).

---

## Documentation & Demo Videos

- **Project Documentation (10 pages):** *Paste Google Drive / PDF link here*
- **Demo & QA Testing Videos (4 videos):**
  - Gameplay & Core Mechanics: *Paste YouTube / Drive link here*
  - Code & Architecture Walkthrough: *Paste YouTube / Drive link here*
  - QA & Combat Edge-Case Testing: *Paste YouTube / Drive link here*
  - UI / VFX Integration Showcase: *Paste YouTube / Drive link here*

---

## Disclaimers & Attribution

### 1. AI-Assisted Development Disclosure
- **`enemy_ai.gd`:** Developed with heavy AI assistance (approximately **90% AI-generated** with minimal manual modification), extending my `battlelogic.gd` framework to handle automated opponent decision-making.
- **Core Back-End Systems:** All core game architecture, FSM design, `card.gd`, `abilitymanager.gd`, `passive_manager.gd`, `synergy_manager.gd`, `ModeManager`, and `battlelogic.gd` were designed and implemented by me, using AI selectively only as a supplementary coding and debugging reference.

### 2. Third-Party Media & Assets
This is a **non-commercial student portfolio project** created strictly for educational and university admissions purposes:
- **Music:** All background music and audio tracks belong to their respective original creators and copyright holders.
- **Images:** Certain card illustrations and placeholder images were sourced via Google Images and remain the property of their respective owners.
- **Sound Effects (SFX):** All sound effects used in this project are copyright-free / royalty-free.
