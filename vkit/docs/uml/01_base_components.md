# EVM Base Components

## Core Base Classes

```mermaid
classDiagram
    %% Base Object Hierarchy
    class evm_object {
        <<abstract>>
        +string name
        +new(name)
        +log_info(msg, verbosity)
        +log_warning(msg)
        +log_error(msg)
        +log_debug(msg)
        +convert2string() string
        +get_type_name() string
    }
    
    class evm_log {
        <<singleton>>
        +evm_verbosity_e verbosity
        +int error_count
        +int warning_count
        +set_verbosity(level)
        +report(msg, severity)
        +print_summary()
    }
    
    %% Component Hierarchy
    class evm_component {
        <<abstract>>
        +string name
        +evm_component parent
        +evm_component children[$]
        +build_phase()
        +connect_phase()
        +run_phase()
        +main_phase()
        +final_phase()
        +set_parent(parent)
        +add_child(child)
    }
    
    class evm_root {
        +evm_component top
        +bit simulation_finished
        +run_test()
        +end_of_test()
        +report_phase()
    }
    
    class evm_base_test {
        +evm_root root
        +virtual run()
        +virtual configure()
        +raise_objection()
        +drop_objection()
    }
    
    %% Inheritance
    evm_component --|> evm_object : extends
    evm_root --|> evm_component : extends
    evm_base_test --|> evm_component : extends
    
    %% Relationships
    evm_object ..> evm_log : uses
    evm_root o-- evm_component : contains top
    evm_base_test o-- evm_root : contains
```

## Verbosity Levels

```mermaid
graph LR
    A[EVM_NONE] --> B[EVM_LOW]
    B --> C[EVM_MED]
    C --> D[EVM_HIGH]
    D --> E[EVM_FULL]
    E --> F[EVM_DEBUG]
```

## Phase Execution Flow

```mermaid
sequenceDiagram
    participant Test
    participant Root
    participant Component
    
    Test->>Root: run_test()
    Root->>Component: build_phase()
    Note over Component: Create sub-components
    
    Root->>Component: connect_phase()
    Note over Component: Connect interfaces
    
    Root->>Component: run_phase()
    activate Component
    Component->>Component: main_phase()
    Note over Component: Main execution
    deactivate Component
    
    Root->>Component: final_phase()
    Note over Component: Cleanup & reporting
    
    Root->>Test: report_phase()
```

## Key Features

### evm_object
- Base class for all EVM objects
- Provides logging infrastructure
- String conversion for debugging
- Type identification

### evm_component  
- Phased execution model
- Hierarchical structure (parent/children)
- Build, connect, run, final phases
- Supports component reuse

### evm_log
- Centralized logging system
- Configurable verbosity levels
- Error and warning counters
- Summary reporting

### evm_base_test
- Test base class
- Objection mechanism
- Configuration hooks
- Test orchestration

### evm_root
- Top-level simulation controller
- Phase coordinator
- Manages test lifecycle
- End-of-test handling
