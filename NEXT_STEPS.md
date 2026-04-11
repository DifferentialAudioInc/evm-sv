# EVM — Next Steps & Known Issues

## Immediate Next: NIC Example Project (example2)
A complete TX NIC DUT + full EVM verification environment demonstrating the entire framework in a realistic IP scenario. Use `example2/` directory following the established layout from `example1/`.

---

## Known Issues / Future Fixes

### 1. AXI4 Full Agent — Vivado Package Compatibility
**Status:** `evm_axi4_full_driver.sv`, `evm_axi4_full_monitor.sv`, `evm_axi4_full_agent.sv` excluded from `evm_vkit_pkg.sv`

**Root cause:** `evm_axi4_full_agent` uses a **direct** `virtual evm_axi4_full_if vif` member. Vivado xvlog cannot resolve non-parameterized virtual interface types inside packages.

**Fix needed:** Refactor to extend the parameterized base class, matching the working AXI-Lite pattern:
```systemverilog
// Current (broken in Vivado pkg context):
class evm_axi4_full_master_agent extends evm_component;
    virtual evm_axi4_full_if vif;  // ← direct member

// Fix (matches evm_axi_lite_master_agent pattern):
class evm_axi4_full_master_agent extends evm_agent#(virtual evm_axi4_full_if, evm_axi4_full_write_txn);
// VIF becomes a type parameter → Vivado accepts this
```

### 2. CSR Generator — `status` Naming Collision Bug
**Status:** Manually patched in `example1/csr/generated/axi_data_xform/axi_data_xform_reg_model.sv`

**Root cause:** `gen_csr.py` generates `task read_status(output bit status)` where the output parameter `status` shadows the member `evm_reg status`. This causes `status.read(val64, status)` to resolve incorrectly.

**Fix needed:** In `gen_csr.py`, rename generated task output parameters from `status` to `rw_ok` or `ok` to avoid collision with register member names.

### 3. Streaming Agent — CLK/RST/ADC/PCIe Agents Not Verified in Vivado
**Status:** These agents are included in `evm_vkit_pkg.sv` but not tested in Vivado simulation yet.

**Potential issues:** Same virtual interface pattern as AXI4 Full if they use direct `virtual <if> vif` members rather than parameterized base class.

### 4. EVM Vivado Compatibility Summary (lessons learned)
- No `reg` as variable name (use `csr`)
- No `disable` as method name (use `set_disabled`)
- No `#delay` inside functions
- All local variable declarations must be at the TOP of task/function body (before any statements)
- No `automatic` keyword on variables inside class methods (already implicit)
- `EVM_REGISTER_TEST` macro (contains `initial`) must be at MODULE scope, NOT inside packages
- `virtual class` cannot be instantiated with `new()` — use concrete subclass
- Variables in module `initial` blocks need `automatic` qualifier
- Non-parameterized virtual interfaces inside packages fail elaboration — use type parameter pattern

---

## example1 Compilation Status
- **Compilation:** PASSES (all warnings, no errors)
- **Elaboration:** In progress (fixing API mismatches)
- **Simulation:** Not yet reached

## Future Examples
- `example2/` — NIC TX path with AXI4-Lite CSR + AXI4 Full data plane
- `example3/` — ADC/DAC streaming with Python integration
