# EVM Core Framework

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Full Class Hierarchy

```mermaid
classDiagram
    %% ── Object Layer ──────────────────────────────────────────────────────────
    class evm_object {
        <<abstract>>
        +string m_name
        +new(name)
        +get_name() string
        +log_info(msg, verbosity)
        +log_warning(msg)
        +log_error(msg)
        +log_debug(msg)
        +convert2string() string
        +get_type_name() string
    }

    %% ── Component Layer ───────────────────────────────────────────────────────
    class evm_component {
        <<abstract>>
        +evm_component m_parent
        +evm_component m_children[$]
        +event reset_asserted
        +event reset_deasserted
        +bit in_reset
        +build_phase()
        +connect_phase()
        +end_of_elaboration_phase()
        +start_of_simulation_phase()
        +reset_phase()
        +configure_phase()
        +run_phase()
        +main_phase()
        +shutdown_phase()
        +extract_phase()
        +check_phase()
        +report_phase()
        +final_phase()
        +assert_reset()
        +deassert_reset()
        +on_reset_assert()
        +on_reset_deassert()
        +print_topology(indent)
        +get_full_name() string
    }

    %% ── Environment ───────────────────────────────────────────────────────────
    class evm_env {
        +end_of_elaboration_phase()
        +get_type_name() string
    }

    %% ── Root / Test ───────────────────────────────────────────────────────────
    class evm_root {
        <<singleton>>
        -static evm_root m_inst
        +int objection_count
        +int default_timeout_us
        +static get() evm_root
        +static init(name) evm_root
        +raise_objection(description)
        +drop_objection(description)
        +wait_for_objections()
        +run_test(test)
        +run_test_by_name()
        +run_all_phases_with_test(test)
    }

    class evm_base_test {
        <<abstract>>
        +string test_name
        +evm_qc qc
        +bit enable_qc
        +int qc_threshold
        +build_phase()
        +main_phase()
        +report_phase()
        +raise_objection(description)
        +drop_objection(description)
        +enable_quiescence_counter(threshold)
        +disable_quiescence_counter()
        +get_test_result() bit
        +process_cmdline_args()
    }

    %% ── Inheritance ───────────────────────────────────────────────────────────
    evm_component --|> evm_object : extends
    evm_env       --|> evm_component : extends
    evm_root      --|> evm_component : extends
    evm_base_test --|> evm_component : extends

    %% ── Relationships ─────────────────────────────────────────────────────────
    evm_root ..> evm_test_registry : "calls create_test()"
    evm_base_test o-- evm_qc : "optional"
```

---

## Test Registry

```mermaid
classDiagram
    class evm_test_creator {
        <<abstract>>
        +create(name) evm_base_test*
        +get_type_name() string
    }

    class evm_test_creator_t~T~ {
        +create(name) evm_base_test
    }

    class evm_test_registry {
        <<static>>
        -evm_test_creator m_creators[string]
        +register(name, creator)$
        +create_test(name) evm_base_test$
        +test_exists(name) bit$
        +get_test_count() int$
        +list_tests()$
    }

    evm_test_creator_t --|> evm_test_creator : extends
    evm_test_registry ..> evm_test_creator : "stores"
```

**Macro** `EVM_REGISTER_TEST(TNAME)` — registers type at time 0 via `initial` block.

---

## 12-Phase System + Parallel run_phase

```mermaid
sequenceDiagram
    participant tb_top
    participant evm_root
    participant test
    participant run_phase_thread as "run_phase thread"
    participant seq_phases as "Sequential Phases"

    tb_top->>evm_root: run_test_by_name()
    Note over evm_root: reads +EVM_TESTNAME plusarg

    evm_root->>test: build_phase()
    evm_root->>test: connect_phase()
    evm_root->>test: end_of_elaboration_phase()
    evm_root->>test: start_of_simulation_phase()

    Note over evm_root: fork — runs in parallel
    evm_root-)run_phase_thread: run_phase() [forever]
    activate run_phase_thread
    Note over run_phase_thread: monitors, scoreboards, predictors

    evm_root->>seq_phases: reset_phase()
    evm_root->>seq_phases: configure_phase()
    evm_root->>seq_phases: main_phase() + objection wait
    evm_root->>seq_phases: shutdown_phase()
    Note over evm_root: join — waits for both branches

    deactivate run_phase_thread

    evm_root->>test: extract_phase()
    evm_root->>test: check_phase()
    evm_root->>test: report_phase()
    evm_root->>test: final_phase()
```

---

## Reset Sub-Phase Architecture

```mermaid
graph TD
    R[reset_phase]
    R --> PRE[pre_reset]
    PRE --> DO[reset]
    DO --> POST[post_reset]

    PRE -->|"Stop activities, save state"| PRE_ACT[" "]
    DO -->|"Clear queues, reset counters"| DO_ACT[" "]
    POST -->|"Reinitialize, prepare"| POST_ACT[" "]

    style PRE_ACT fill:none,stroke:none
    style DO_ACT fill:none,stroke:none
    style POST_ACT fill:none,stroke:none
```

---

## Mid-Simulation Reset Event Flow

```mermaid
sequenceDiagram
    participant test
    participant env
    participant monitor
    participant scoreboard
    participant driver
    participant sequencer

    test->>env: assert_reset()
    env->>monitor: propagate reset_asserted event
    env->>scoreboard: propagate reset_asserted event
    env->>driver: propagate reset_asserted event
    env->>sequencer: propagate reset_asserted event

    activate monitor
    Note over monitor: on_reset_assert()
    Note over monitor: flush partial txn
    deactivate monitor

    activate scoreboard
    Note over scoreboard: on_reset_assert()
    Note over scoreboard: flush expected/actual queues
    deactivate scoreboard

    activate driver
    Note over driver: on_reset_assert()
    Note over driver: idle bus outputs
    deactivate driver

    activate sequencer
    Note over sequencer: on_reset_assert()
    Note over sequencer: flush mailbox + FIFOs
    deactivate sequencer

    Note over env: (DUT reset in progress)

    test->>env: deassert_reset()
    env->>monitor: reset_deasserted event → resume
    env->>scoreboard: reset_deasserted event → ready
    env->>driver: reset_deasserted event → ready
    env->>sequencer: reset_deasserted event → ready
```

---

## Verbosity Levels

```mermaid
graph LR
    A[EVM_NONE<br/>Always shown] --> B[EVM_LOW]
    B --> C[EVM_MEDIUM]
    C --> D[EVM_HIGH]
    D --> E[EVM_DEBUG<br/>Most verbose]
```

---

## Quiescence Counter (QC) — Unique EVM Feature

```mermaid
classDiagram
    class evm_qc {
        +int threshold_cycles
        +bit enabled
        +bit objection_raised
        +set_threshold(cycles)
        +tick()
        +enable()
        +disable()
        +run_phase()
    }

    evm_qc --|> evm_component : extends
    evm_base_test o-- evm_qc : "optional (enable_qc=1)"
```

**Flow:**
```mermaid
graph TD
    T[tick called] -->|"first tick"| RO[raise_objection]
    T -->|"subsequent ticks"| RC[reset cycle counter]
    W[cycle counter >= threshold] -->|"no tick() for N cycles"| DO[drop_objection]
    DO --> END[test ends gracefully]
```
