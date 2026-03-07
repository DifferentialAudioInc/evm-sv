# EVM Framework - Next Steps & Action Items

**Date:** 2026-03-07  
**Status:** 75% Complete  
**Target:** 100% in 3-4 weeks  

---

## Quick Summary

✅ **What's Working:**
- Core framework complete and solid
- Transaction model fully functional
- Documentation excellent
- CSR generator production-ready
- Python tools high quality

⚠️ **What Needs Work:**
- Complete streaming file I/O implementation
- Add diverse test examples
- Integrate sequencer with AXI-Lite agent
- Automate Python workflow

---

## Priority 1: Critical Path Items 🔴

### 1.1 Complete Streaming Driver File I/O
**Effort:** 1-2 days  
**Impact:** HIGH - Enables entire streaming model  

**Tasks:**
- [ ] Implement `load_stimulus()` in `evm_stream_driver.sv`
- [ ] Parse text format: `time, ch0, ch1, ...`
- [ ] Handle multi-channel data
- [ ] Support loop mode
- [ ] Add error handling for file not found

**File:** `evm/vkit/src/evm_stream_driver.sv`

---

### 1.2 Complete Streaming Monitor File Capture
**Effort:** 1-2 days  
**Impact:** HIGH - Completes streaming model  

**Tasks:**
- [ ] Implement `main_phase()` file writing in `evm_stream_monitor.sv`
- [ ] Write header with metadata
- [ ] Capture samples every clock cycle
- [ ] Format: `time, data`
- [ ] Close file in `final_phase()`

**File:** `evm/vkit/src/evm_stream_monitor.sv`

---

### 1.3 Create Complete Streaming Test Example
**Effort:** 1 day  
**Impact:** HIGH - Demonstrates streaming model  

**Tasks:**
- [ ] Create `streaming_test.sv` in `fpga/ip/dv/tests/`
- [ ] Generate stimulus with Python pre-simulation
- [ ] Stream through DUT
- [ ] Capture output
- [ ] Analyze with Python post-simulation
- [ ] Add to test factory in `tb_top.sv`

**New File:** `fpga/ip/dv/tests/streaming_test.sv`

---

### 1.4 Enable Python System Calls
**Effort:** 1 hour  
**Impact:** MEDIUM - Automates workflow  

**Tasks:**
- [ ] Uncomment `$system()` calls in `evm_stream_agent.sv`
- [ ] Test on Windows/Linux
- [ ] Add error checking
- [ ] Update documentation

**File:** `evm/vkit/src/evm_stream_agent.sv`

---

## Priority 2: High Value Enhancements 🟡

### 2.1 Add Sequencer to AXI-Lite Agent
**Effort:** 2 days  
**Impact:** MEDIUM - Improves consistency  

**Tasks:**
- [ ] Add `evm_sequencer` member to `evm_axi_lite_agent`
- [ ] Create sequencer in `build_phase()`
- [ ] Connect to driver
- [ ] Keep backward compatibility with direct task calls
- [ ] Add convenience method to execute sequences

**File:** `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/evm_axi_lite_agent.sv`

---

### 2.2 Create AXI Sequence Library
**Effort:** 1 day  
**Impact:** MEDIUM - Enables reusable patterns  

**Tasks:**
- [ ] Create `evm_axi_lite_sequence.sv`
- [ ] Extend `evm_csr_sequence` or create new base
- [ ] Add burst read/write sequences
- [ ] Add configuration sequences
- [ ] Add register dump sequence

**New File:** `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/evm_axi_lite_sequence.sv`

---

### 2.3 Create Mixed Test Example
**Effort:** 1 day  
**Impact:** MEDIUM - Shows both models together  

**Tasks:**
- [ ] Create `mixed_test.sv`
- [ ] Use AXI sequences for configuration
- [ ] Use streaming for data flow
- [ ] Demonstrate concurrent operation
- [ ] Add detailed comments

**New File:** `fpga/ip/dv/tests/mixed_test.sv`

---

### 2.4 Create Python Workflow Test
**Effort:** 1 day  
**Impact:** MEDIUM - Demonstrates automation  

**Tasks:**
- [ ] Create `python_workflow_test.sv`
- [ ] Call Python to generate stimulus in `pre_main_phase()`
- [ ] Run simulation with streaming
- [ ] Call Python to analyze in `final_phase()`
- [ ] Validate results in test

**New File:** `fpga/ip/dv/tests/python_workflow_test.sv`

---

## Priority 3: Polish & Documentation 🟢

### 3.1 Create Quick-Start Guide
**Effort:** 2 days  
**Impact:** HIGH for adoption  

**Tasks:**
- [ ] Write `QUICKSTART.md`
- [ ] 15-minute tutorial
- [ ] Step-by-step with code snippets
- [ ] Minimal working example
- [ ] Common gotchas section

**New File:** `evm/QUICKSTART.md`

---

### 3.2 Create TCL Automation Scripts
**Effort:** 1 day  
**Impact:** MEDIUM - Ease of use  

**Tasks:**
- [ ] Create `run_with_python.tcl`
- [ ] Orchestrate: generate → compile → simulate → analyze
- [ ] Support multiple tests
- [ ] Add command-line options
- [ ] Document usage

**New File:** `fpga/ip/dv/run_amd/run_with_python.tcl`

---

### 3.3 Add Makefile
**Effort:** 1 day  
**Impact:** MEDIUM - Developer convenience  

**Tasks:**
- [ ] Create `Makefile` in `fpga/ip/dv/`
- [ ] Targets: compile, sim, clean, help
- [ ] Support TEST= parameter
- [ ] Add Python integration
- [ ] Document usage

**New File:** `fpga/ip/dv/Makefile`

---

### 3.4 Create Troubleshooting Guide
**Effort:** 1 day  
**Impact:** MEDIUM - Reduces support burden  

**Tasks:**
- [ ] Create `TROUBLESHOOTING.md`
- [ ] Common errors and solutions
- [ ] Simulator-specific issues
- [ ] Python integration issues
- [ ] FAQ section

**New File:** `evm/TROUBLESHOOTING.md`

---

## Priority 4: Nice-to-Have Features 🔵

### 4.1 Create DAC Stream Agent
**Effort:** 2 days  
**Impact:** LOW - Specific use case  

**Tasks:**
- [ ] Create `evm_dac_stream_agent` (passive only)
- [ ] Monitor-based capture
- [ ] Similar to ADC but output-focused
- [ ] Add example usage

**New Files:** `evm/vkit/docs/evm_vkit/evm_dac_agent/*`

---

### 4.2 Generate API Documentation
**Effort:** 3 days  
**Impact:** LOW - Reference only  

**Tasks:**
- [ ] Set up doxygen/naturaldocs
- [ ] Add doc comments to all classes
- [ ] Generate HTML
- [ ] Add to documentation

---

### 4.3 Add Coverage Examples
**Effort:** 2 days  
**Impact:** LOW - Advanced feature  

**Tasks:**
- [ ] Create coverage utility classes
- [ ] Add functional coverage example
- [ ] Document coverage workflow
- [ ] Integrate with simulator

---

## Suggested 4-Week Plan

### Week 1: Complete Streaming Model 🔴
- **Mon-Tue:** Stream driver file I/O
- **Wed-Thu:** Stream monitor capture
- **Fri:** Complete streaming test example
- **Deliverable:** Fully functional streaming model with example

### Week 2: Enhanced Transaction Model 🟡
- **Mon-Tue:** Add sequencer to AXI agent
- **Wed:** Create AXI sequence library
- **Thu:** Example sequence-based test
- **Fri:** Update documentation
- **Deliverable:** Transaction model with sequencer support

### Week 3: Example Gallery 🟡
- **Mon:** Mixed test (transaction + streaming)
- **Tue:** Python workflow test
- **Wed:** Polish and test all examples
- **Thu-Fri:** Review and documentation updates
- **Deliverable:** 4+ diverse, well-commented examples

### Week 4: Polish & Distribution 🟢
- **Mon-Tue:** Quick-start guide and tutorial
- **Wed:** TCL automation and Makefile
- **Thu:** Troubleshooting guide
- **Fri:** Final review and release prep
- **Deliverable:** Polished, ready-to-distribute framework

---

## Success Metrics

### After Week 1
- ✅ User can run file-based streaming test
- ✅ Python integration works end-to-end
- ✅ Streaming example in test suite

### After Week 2
- ✅ AXI transactions support both sequences and direct calls
- ✅ Sequence library available for reuse
- ✅ Documentation updated

### After Week 3
- ✅ 4+ diverse examples available
- ✅ Both models demonstrated
- ✅ Mixed usage shown

### After Week 4
- ✅ New user productive in 15 minutes
- ✅ Automated build/run system
- ✅ Common issues documented
- ✅ Framework ready for broad adoption

---

## Files to Modify

### High Priority
1. `evm/vkit/src/evm_stream_driver.sv` - Add file reading
2. `evm/vkit/src/evm_stream_monitor.sv` - Add file writing
3. `evm/vkit/src/evm_stream_agent.sv` - Enable $system()
4. `fpga/ip/dv/tests/` - Add new test examples

### Medium Priority
5. `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/evm_axi_lite_agent.sv` - Add sequencer
6. `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/` - Add sequence library
7. `fpga/ip/dv/run_amd/` - Add automation scripts
8. `fpga/ip/dv/` - Add Makefile

### Low Priority
9. `evm/` - Add QUICKSTART.md, TROUBLESHOOTING.md
10. Various files - Add doxygen comments

---

## New Files to Create

### Tests (Priority 1-2)
- `fpga/ip/dv/tests/streaming_test.sv`
- `fpga/ip/dv/tests/mixed_test.sv`
- `fpga/ip/dv/tests/python_workflow_test.sv`
- `fpga/ip/dv/tests/sequence_based_test.sv`

### VKit Extensions (Priority 2)
- `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/evm_axi_lite_sequence.sv`
- `evm/vkit/docs/evm_vkit/evm_axi_lite_agent/evm_axi_lite_sequence_item.sv`

### Documentation (Priority 3)
- `evm/QUICKSTART.md`
- `evm/TROUBLESHOOTING.md`

### Build System (Priority 3)
- `fpga/ip/dv/Makefile`
- `fpga/ip/dv/run_amd/run_with_python.tcl`

---

## Quick Wins (< 1 day each)

1. ✅ **Enable `$system()` calls** - 1 hour, high impact
2. ✅ **Create streaming test** - 4 hours, proves concept
3. ✅ **Add Makefile** - 3 hours, convenience
4. ✅ **Create quick-start** - 6 hours, adoption

Start with quick wins to show immediate progress!

---

## Dependencies

```
Streaming Driver ─┬─> Streaming Test ──> Python Workflow Test
                  │
Streaming Monitor─┘

AXI Sequencer ────> AXI Sequence Lib ──> Sequence Test ──> Mixed Test

All Examples ─────> Quick-Start Guide
```

**Critical Path:** Streaming I/O → Example Test → Validation

---

## Resources Needed

- **Developer time:** 1 person, 3-4 weeks full-time
- **Testing:** Access to simulator (VCS/Xcelium/Questa/Vivado)
- **Python:** Python 3.6+, numpy, scipy, matplotlib
- **Documentation:** Markdown editor, optional doxygen

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| File I/O performance issues | Test with large files, optimize if needed |
| Simulator compatibility | Test on multiple simulators early |
| Python path issues | Document setup clearly, provide scripts |
| Backward compatibility | Keep existing interfaces working |

---

## Contact for Questions

- Framework questions: Review EVM_RULES.md and EVM_ARCHITECTURE.md
- Implementation questions: Check STREAMING_GUIDE.md
- CSR generator: See csr_gen/README.md

---

## Conclusion

**The framework is 75% complete and production-ready for transaction-based verification.**

Focus on **Priority 1 items (Week 1)** to unlock the streaming model and deliver the framework's unique value proposition. The remaining work is primarily about adding examples, polish, and documentation to enable broad adoption.

**Recommended approach:** Execute the 4-week plan sequentially, validating each week's deliverables before proceeding.

---

*Last Updated: 2026-03-07*
