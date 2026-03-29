# UVM vs EVM Gap Analysis

**EVM - Embedded Verification Methodology**  
**Last Updated:** 2026-03-28  
**Version:** 1.0.0

---

## Executive Summary

This document identifies critical UVM functionality that is missing or simplified in EVM. It categorizes gaps by severity and provides recommendations for what should be added versus what can remain simplified for embedded verification.

---

## 1. evm_object vs uvm_object

### 🔴 CRITICAL Missing Features

#### 1.1 Copy/Clone Functionality
**UVM Has:**
```systemverilog
function uvm_object clone();
function void copy(uvm_object rhs);
virtual function void do_copy(uvm_object rhs);
```

**EVM Missing:**
- Deep copy support
- Clone creation
- Copy hooks

**Impact:** Cannot duplicate objects, critical for:
- Reference models
- Expected transaction generation
- Debugging snapshots

**Recommendation:** ✅ **ADD THIS** - Essential for verification

---

#### 1.2 Compare Functionality
**UVM Has:**
```systemverilog
function bit compare(uvm_object rhs, uvm_comparer comparer=null);
virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
```

**EVM Missing:**
- Deep comparison
- Field-by-field comparison
- Comparison policies

**Impact:** Cannot compare objects deeply, affects:
- Scoreboard comparison
- Golden model validation
- Regression comparison

**Recommendation:** ✅ **ADD THIS** - Essential for verification

---

#### 1.3 Pack/Unpack (Serialization)
**UVM Has:**
```systemverilog
function void pack(ref bit unsigned stream[]);
function void unpack(ref bit unsigned stream[]);
virtual function void do_pack(uvm_packer packer);
virtual function void do_unpack(uvm_packer packer);
```

**EVM Missing:**
- Serialization to bit streams
- Deserialization
- Packing policies

**Impact:** Cannot serialize for:
- File I/O
- Network transmission
- Waveform dumping

**Recommendation:** 🟡 **OPTIONAL** - Add if needed for file I/O

---

#### 1.4 Field Automation
**UVM Has:**
```systemverilog
`uvm_field_int(addr, UVM_DEFAULT)
`uvm_field_enum(operation_e, op, UVM_DEFAULT)
`uvm_object_utils(my_transaction)
```

**EVM Missing:**
- Field registration macros
- Automatic copy/compare/pack/unpack
- Automatic printing

**Impact:** More manual coding required

**Recommendation:** ❌ **SKIP** - Too complex, manual methods better for embedded

---

### 🟡 MEDIUM Priority Missing Features

#### 1.5 Print Functionality
**UVM Has:**
```systemverilog
function void print(uvm_printer printer=null);
virtual function void do_print(uvm_printer printer);
function string sprint(uvm_printer printer=null);
```

**EVM Has:**
```systemverilog
virtual function void print();
virtual function string convert2string();
```

**Gap:** No configurable printing policies

**Recommendation:** ✅ **ENHANCE** - Add sprint() and better formatting

---

### 🟢 LOW Priority / Acceptable Gaps

#### 1.6 Factory Creation
**UVM Has:**
- Factory registration
- Type override
- Instance override

**EVM Has:**
- Direct instantiation only

**Recommendation:** ❌ **SKIP** - Factory too complex for embedded

---

## 2. evm_component vs uvm_component

### 🔴 CRITICAL Missing Features

#### 2.1 Child Component Management
**UVM Has:**
```systemverilog
function uvm_component get_child(string name);
function int get_num_children();
function int get_first_child(ref string name);
function int get_next_child(ref string name);
function uvm_component lookup(string name);
```

**EVM Missing:**
- Child tracking
- Hierarchy traversal
- Component lookup by name

**Impact:** Cannot:
- Query hierarchy
- Debug component structure
- Implement hierarchical configuration

**Recommendation:** ✅ **ADD THIS** - Critical for debugging

---

#### 2.2 Topology Printing
**UVM Has:**
```systemverilog
function void print_topology(uvm_printer printer=null);
```

**EVM Missing:**
- Hierarchical structure printing
- Component tree visualization

**Impact:** Harder to debug testbench structure

**Recommendation:** ✅ **ADD THIS** - Essential for debugging

---

#### 2.3 Hierarchical Configuration
**UVM Has:**
```systemverilog
function void set_report_verbosity_level_hier(int verbosity);
function void set_report_id_verbosity_hier(string id, int verbosity);
```

**EVM Missing:**
- Hierarchical verbosity control
- Per-component ID filtering

**Impact:** Cannot selectively debug specific components

**Recommendation:** ✅ **ADD THIS** - Very useful for debugging

---

### 🟡 MEDIUM Priority Missing Features

#### 2.4 Configuration Database
**UVM Has:**
```systemverilog
uvm_config_db#(virtual my_if)::set(this, "agent*", "vif", vif);
uvm_config_db#(virtual my_if)::get(this, "", "vif", vif);
```

**EVM Has:**
- Direct virtual interface assignment via `set_vif()`

**Gap:** No hierarchical configuration passing

**Recommendation:** ❌ **SKIP** - Direct assignment simpler for embedded

---

## 3. evm_driver vs uvm_driver

### 🔴 CRITICAL Missing Features

#### 3.1 Sequence Item Port & Protocol
**UVM Has:**
```systemverilog
uvm_seq_item_pull_port#(REQ, RSP) seq_item_port;

task run_phase(uvm_phase phase);
    forever begin
        seq_item_port.get_next_item(req);
        drive_item(req);
        seq_item_port.item_done();
    end
endtask
```

**EVM Missing:**
- TLM port for sequencer connection
- get_next_item() / item_done() protocol
- try_next_item() non-blocking variant
- REQ/RSP protocol

**Impact:** No standard driver-sequencer communication

**Recommendation:** ✅ **ADD THIS** - Critical for sequence support

---

#### 3.2 Sequence Support
**UVM Has:**
```systemverilog
task get_next_item(output REQ req);
task try_next_item(output REQ req);
task item_done(input RSP rsp = null);
task wait_for_sequences();
```

**EVM Missing:**
- Sequencer protocol completely missing

**Recommendation:** ✅ **ADD THIS** - Essential for proper sequence flow

---

## 4. evm_monitor vs uvm_monitor

### 🔴 CRITICAL Missing Features

#### 4.1 Analysis Port
**UVM Has:**
```systemverilog
uvm_analysis_port#(my_transaction) analysis_port;

task run_phase(uvm_phase phase);
    my_transaction tr;
    forever begin
        collect_transaction(tr);
        analysis_port.write(tr);  // Broadcast to all subscribers
    end
endtask
```

**EVM Missing:**
- TLM analysis port for broadcasting
- Subscriber mechanism
- 1-to-many connection

**Impact:** Cannot broadcast to multiple components:
- Scoreboard
- Coverage collector
- Protocol checker
- Logger

**Recommendation:** ✅ **ADD THIS** - Critical for monitor functionality

---

## 5. evm_agent vs uvm_agent

### 🔴 CRITICAL Missing Features

#### 5.1 Sequencer Component
**UVM Has:**
```systemverilog
class my_agent extends uvm_agent;
    my_driver    driver;
    my_monitor   monitor;
    my_sequencer sequencer;  // MISSING IN EVM!
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = my_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            driver = my_driver::type_id::create("driver", this);
            sequencer = my_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass
```

**EVM Has:**
```systemverilog
// NO SEQUENCER!
evm_driver#(VIF) driver;
evm_monitor#(VIF) monitor;
```

**Impact:** No sequencer means:
- No sequence layering
- No virtual sequences
- No sequence coordination
- Driver must generate stimuli directly

**Recommendation:** ✅ **ADD THIS** - Critical for proper sequence architecture

---

## 6. evm_sequence vs uvm_sequence

### Current Status

**EVM Has:**
- Basic evm_sequence class
- evm_sequencer class
- evm_sequence_item class

**Needs Review:**
- Sequence item protocol integration
- Parent sequence support
- Sequence coordination

**Recommendation:** ✅ **REVIEW & ENHANCE** - Check compatibility with TLM ports

---

## 7. TLM Infrastructure

### 🔴 CRITICAL Missing Features

#### 7.1 TLM Ports & Exports
**UVM Has:**
```systemverilog
uvm_blocking_put_port#(T)
uvm_blocking_get_port#(T)
uvm_analysis_port#(T)
uvm_blocking_put_export#(T)
uvm_tlm_fifo#(T)
```

**EVM Missing:**
- Complete TLM 1.0 infrastructure
- Port/export mechanism
- FIFO channels
- Analysis ports/exports

**Impact:** Cannot:
- Connect components in standard way
- Use analysis ports for broadcasting
- Implement standard communication patterns

**Recommendation:** ✅ **ADD THIS** - Essential for component communication

---

## 8. Summary of Critical Gaps

### 🔴 MUST ADD (Critical for Functionality)

| Feature | Component | Priority | Complexity |
|---------|-----------|----------|------------|
| **copy() / clone()** | evm_object | 🔴 HIGH | Medium |
| **compare()** | evm_object | 🔴 HIGH | Medium |
| **get_child() / lookup()** | evm_component | 🔴 HIGH | Low |
| **print_topology()** | evm_component | 🔴 HIGH | Low |
| **Analysis Ports** | TLM | 🔴 HIGH | High |
| **seq_item_port** | evm_driver | 🔴 HIGH | Medium |
| **get_next_item()** | evm_driver | 🔴 HIGH | Medium |
| **Sequencer** | evm_agent | 🔴 HIGH | Medium |

### 🟡 SHOULD ADD (High Value)

| Feature | Component | Priority | Complexity |
|---------|-----------|----------|------------|
| **sprint()** | evm_object | 🟡 MEDIUM | Low |
| **Hierarchical verbosity** | evm_component | 🟡 MEDIUM | Low |
| **pack()/unpack()** | evm_object | 🟡 MEDIUM | High |

### 🟢 OPTIONAL / SKIP

| Feature | Component | Reason to Skip |
|---------|-----------|----------------|
| Field Automation | evm_object | Too complex, manual better |
| Factory Pattern | All | Too complex for embedded |
| Config DB | evm_component | Direct assignment simpler |

---

## 9. Implementation Recommendations

### Phase 1: Foundation (Week 1)
1. **Add copy/clone to evm_object**
   - Implement virtual do_copy()
   - Add copy() method
   - Add clone() method

2. **Add compare to evm_object**
   - Implement virtual do_compare()
   - Add compare() method with miscompare reporting

3. **Add child tracking to evm_component**
   - Track children in array
   - Implement get_child()
   - Implement get_num_children()

4. **Add print_topology()**
   - Print component hierarchy
   - Indent levels
   - Show types

### Phase 2: TLM Infrastructure (Week 2)
1. **Implement TLM Analysis Port**
   - evm_analysis_port#(T)
   - write() method
   - Subscriber list

2. **Add analysis_port to evm_monitor**
   - Create port in constructor
   - Document usage pattern

### Phase 3: Sequence Infrastructure (Week 3)
1. **Enhance evm_sequencer**
   - Add seq_item_export
   - Implement item FIFO
   - Add get_next_item/item_done protocol

2. **Enhance evm_driver**
   - Add seq_item_port
   - Add get_next_item() task
   - Add item_done() task
   - Add try_next_item() task

3. **Update evm_agent**
   - Add sequencer property
   - Create sequencer in build
   - Connect driver to sequencer

### Phase 4: Utilities (Week 4)
1. **Add hierarchical verbosity**
   - set_verbosity_hier()
   - Propagate to children

2. **Add sprint()**
   - Return formatted string
   - Support different formats

---

## 10. Detailed Function Specifications

### 10.1 copy() Implementation

```systemverilog
virtual class evm_object extends evm_log;
    
    // Copy from another object
    virtual function void copy(evm_object rhs);
        if (rhs == null) begin
            log_error("Attempting to copy from null object");
            return;
        end
        if (rhs.get_type_name() != this.get_type_name()) begin
            log_warning($sformatf("Type mismatch in copy: %s != %s",
                                 this.get_type_name(), rhs.get_type_name()));
        end
        do_copy(rhs);
    endfunction
    
    // Clone (create new and copy)
    virtual function evm_object clone();
        log_fatal("clone() must be overridden to create proper type");
        return null;
    endfunction
    
    // Override to implement field copying
    virtual function void do_copy(evm_object rhs);
        // Base class copies name
        m_name = rhs.get_name();
    endfunction
    
endclass
```

### 10.2 compare() Implementation

```systemverilog
virtual class evm_object extends evm_log;
    
    // Compare with another object
    virtual function bit compare(evm_object rhs);
        if (rhs == null) begin
            log_error("Comparing with null object");
            return 0;
        end
        if (rhs.get_type_name() != this.get_type_name()) begin
            log_error($sformatf("Type mismatch: %s != %s",
                               this.get_type_name(), rhs.get_type_name()));
            return 0;
        end
        return do_compare(rhs);
    endfunction
    
    // Override to implement field comparison
    virtual function bit do_compare(evm_object rhs);
        // Base implementation returns 1 (override in derived classes)
        return 1;
    endfunction
    
endclass
```

### 10.3 Child Management Implementation

```systemverilog
virtual class evm_component extends evm_object;
    
    // Child tracking
    protected evm_component m_children[$];
    protected string m_child_names[$];
    
    // Modified constructor to track children
    function new(string name = "evm_component", evm_component parent = null);
        super.new(name);
        m_parent = parent;
        
        // Register with parent
        if (parent != null) begin
            parent.add_child(name, this);
        end
        
        // Build full name...
    endfunction
    
    // Add child (called from child constructor)
    protected function void add_child(string name, evm_component child);
        m_child_names.push_back(name);
        m_children.push_back(child);
    endfunction
    
    // Get child by name
    virtual function evm_component get_child(string name);
        foreach (m_child_names[i]) begin
            if (m_child_names[i] == name) begin
                return m_children[i];
            end
        end
        log_warning($sformatf("Child '%s' not found", name));
        return null;
    endfunction
    
    // Get number of children
    virtual function int get_num_children();
        return m_children.size();
    endfunction
    
    // Lookup by hierarchical name
    virtual function evm_component lookup(string name);
        string names[$];
        evm_component current = this;
        int i;
        
        // Split name by '.'
        // ... implementation ...
        
        return current;
    endfunction
    
    // Print topology
    virtual function void print_topology(int indent = 0);
        string spaces = "";
        
        // Create indentation
        for (int i = 0; i < indent; i++) begin
            spaces = {spaces, "  "};
        end
        
        // Print this component
        $display("%s%s (%s)", spaces, get_name(), get_type_name());
        
        // Print children
        foreach (m_children[i]) begin
            m_children[i].print_topology(indent + 1);
        end
    endfunction
    
endclass
```

### 10.4 Analysis Port Implementation

```systemverilog
class evm_analysis_port #(type T = int);
    
    typedef evm_analysis_port#(T) this_type;
    
    // Subscribers
    local mailbox#(T) subscribers[$];
    local string m_name;
    
    function new(string name = "analysis_port");
        m_name = name;
    endfunction
    
    // Write to all subscribers
    function void write(T t);
        foreach (subscribers[i]) begin
            subscribers[i].put(t);
        end
    endfunction
    
    // Connect subscriber
    function void connect(mailbox#(T) subscriber);
        subscribers.push_back(subscriber);
    endfunction
    
endclass
```

### 10.5 Sequence Item Port Implementation

```systemverilog
class evm_seq_item_pull_port #(type REQ = int, type RSP = REQ);
    
    local mailbox#(REQ) req_fifo;
    local mailbox#(RSP) rsp_fifo;
    
    function new();
        req_fifo = new();
        rsp_fifo = new();
    endfunction
    
    // Get next item (blocking)
    task get_next_item(output REQ req);
        req_fifo.get(req);
    endtask
    
    // Try to get next item (non-blocking)
    task try_next_item(output REQ req);
        if (req_fifo.num() > 0) begin
            req_fifo.get(req);
        end else begin
            req = null;
        end
    endtask
    
    // Signal item done
    task item_done(input RSP rsp = null);
        if (rsp != null) begin
            rsp_fifo.put(rsp);
        end
    endtask
    
endclass
```

---

## 11. Conclusion

**Critical Gaps Identified:** 8 high-priority features  
**Implementation Time:** ~4 weeks  
**Impact:** Transforms EVM from basic to production-ready  

**Next Steps:**
1. Review and approve this gap analysis
2. Prioritize features based on project needs
3. Implement Phase 1 (Foundation)
4. Test with real verification scenarios
5. Iterate based on usage feedback

---

**End of Gap Analysis**
