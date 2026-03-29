# EVM Critical Changes Summary

**Implementation Priority: CRITICAL**  
**Date:** 2026-03-28  
**Status:** READY TO IMPLEMENT

---

## Overview

This document summarizes the 6 critical changes needed to make EVM production-ready. These changes address fundamental gaps in object manipulation, component communication, and debugging.

---

## Critical Changes Required

### 1. ✅ Add Copy/Clone to evm_object
**File:** `vkit/src/evm_object.sv`

**Functions to Add:**
- `copy(evm_object rhs)` - Copy fields from another object
- `clone()` - Create new instance and copy
- `do_copy(evm_object rhs)` - Virtual hook for field copying

**Why Critical:**
- Reference models need to duplicate transactions
- Scoreboards need expected transaction copies
- Debugging requires object snapshots

**Impact:** Enables object duplication throughout framework

---

### 2. ✅ Add Compare to evm_object
**File:** `vkit/src/evm_object.sv`

**Functions to Add:**
- `compare(evm_object rhs)` - Deep comparison with error reporting
- `do_compare(evm_object rhs)` - Virtual hook for field comparison

**Why Critical:**
- Scoreboards need deep object comparison
- Cannot verify correctness without comparison
- Essential for regression testing

**Impact:** Enables proper verification comparison

---

### 3. ✅ Add Child Tracking to evm_component
**File:** `vkit/src/evm_component.sv`

**Functions to Add:**
- `get_child(string name)` - Get child by name
- `get_num_children()` - Count children
- `print_topology()` - Print hierarchy tree
- Internal child tracking arrays

**Why Critical:**
- Cannot debug testbench hierarchy
- Cannot query component structure
- No visibility into component tree

**Impact:** Enables hierarchy debugging and introspection

---

### 4. ✅ Add TLM Analysis Port
**Files:** `vkit/src/evm_tlm.sv` (NEW), `vkit/src/evm_monitor.sv`

**Classes to Add:**
- `evm_analysis_port#(type T)` - Broadcast port
- `evm_analysis_imp#(type T)` - Receive implementation
- `evm_analysis_export#(type T)` - Export for hierarchy

**Why Critical:**
- Monitors cannot broadcast to multiple subscribers
- No standard 1-to-many communication
- Cannot connect to scoreboard + coverage + checker simultaneously

**Impact:** Enables standard component communication pattern

---

### 5. ✅ Add Sequence Item Port to evm_driver
**Files:** `vkit/src/evm_tlm.sv`, `vkit/src/evm_driver.sv`

**Classes/Methods to Add:**
- `evm_seq_item_pull_port#(REQ, RSP)` - Driver port
- `evm_seq_item_pull_export#(REQ, RSP)` - Sequencer export
- `get_next_item(output REQ req)` - Blocking get
- `try_next_item(output REQ req)` - Non-blocking get  
- `item_done(RSP rsp = null)` - Completion signal

**Why Critical:**
- No standard driver-sequencer communication
- Drivers cannot properly pull sequences
- REQ/RSP protocol missing

**Impact:** Enables proper sequence-based stimulus generation

---

### 6. ✅ Add Sequencer to evm_agent
**File:** `vkit/src/evm_agent.sv`

**Changes Required:**
- Add sequencer property
- Create sequencer in build_phase
- Connect driver.seq_item_port to sequencer.seq_item_export

**Why Critical:**
- Agents incomplete without sequencer
- No sequence coordination
- Cannot run layered sequences

**Impact:** Completes the agent architecture

---

## Implementation Order

### Phase 1: Foundation (2-3 hours)
1. Add copy/clone to evm_object
2. Add compare to evm_object
3. Add child tracking to evm_component
4. Add print_topology to evm_component

### Phase 2: TLM Infrastructure (3-4 hours)
5. Create evm_tlm.sv with analysis port
6. Add analysis_port to evm_monitor
7. Create seq_item_pull_port/export

### Phase 3: Integration (1-2 hours)
8. Add seq_item_port to evm_driver
9. Update evm_sequencer with export
10. Add sequencer to evm_agent
11. Update evm_pkg.sv

**Total Time:** 6-9 hours

---

## Success Criteria

After implementation, EVM will have:
- ✅ Full object lifecycle (create, copy, compare)
- ✅ Debuggable component hierarchy
- ✅ Standard TLM communication (analysis ports)
- ✅ Proper sequence architecture (driver ↔ sequencer)
- ✅ Production-ready verification framework

---

## Files to Modify

1. ✏️ `vkit/src/evm_object.sv` - Add copy/compare
2. ✏️ `vkit/src/evm_component.sv` - Add child tracking
3. 🆕 `vkit/src/evm_tlm.sv` - NEW - TLM infrastructure
4. ✏️ `vkit/src/evm_monitor.sv` - Add analysis_port
5. ✏️ `vkit/src/evm_driver.sv` - Add seq_item_port
6. ✏️ `vkit/src/evm_sequencer.sv` - Add export
7. ✏️ `vkit/src/evm_agent.sv` - Add sequencer
8. ✏️ `vkit/src/evm_pkg.sv` - Include new TLM file

---

## Testing Plan

After implementation:
1. Test copy/clone with transaction objects
2. Test compare with scoreboard
3. Test print_topology with simple_counter example
4. Test analysis_port with monitor → scoreboard
5. Test seq_item_port with driver → sequencer
6. Run full simple_counter simulation

---

**READY TO IMPLEMENT - All changes are well-defined and ready to code.**
