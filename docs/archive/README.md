# Documentation Archive

**Historical analysis and planning documents**

---

## Purpose

This folder contains analysis, comparison, and planning documents that were created during EVM development. They provided valuable insights for architectural decisions but are not needed for daily use of EVM.

---

## Contents

### UVM Comparison Documents

| Document | Purpose |
|----------|---------|
| **UVM_vs_EVM_ANALYSIS.md** | Comprehensive UVM vs EVM comparison, feature analysis |
| **UVM_EVM_GAP_ANALYSIS.md** | Detailed gap analysis, implementation recommendations |
| **EVM_UVM_FEATURE_COMPARISON.md** | Feature-by-feature comparison matrix |

### Implementation Planning

| Document | Purpose |
|----------|---------|
| **EVM_CRITICAL_FEATURES_ANALYSIS.md** | Critical feature identification and priorities |
| **EVM_MISSING_FEATURES.md** | Features not yet implemented |
| **CRITICAL_CHANGES_SUMMARY.md** | Summary of major changes during development |

### Design Decision Documents

| Document | Purpose |
|----------|---------|
| **EVM_CONFIG_OVERRIDE_PATTERN.md** | Config pattern alternatives (decided: direct VIF) |
| **EVM_FIELD_MACROS_ALTERNATIVE.md** | Field macro alternatives (decided: manual methods) |

---

## Key Takeaways (Already Incorporated)

The analysis in these documents led to EVM's current design:

### ✅ Adopted from UVM
- 12-phase methodology (simplified from UVM's 13)
- Objection mechanism
- TLM 1.0 (analysis ports)
- Severity levels (INFO, WARNING, ERROR, FATAL)
- Component hierarchy

### ❌ Intentionally Simplified
- **No Config DB** → Direct VIF assignment (simpler)
- **No Factory Pattern** → Direct instantiation (less complexity)
- **No Field Macros** → Manual methods (more explicit)
- **No Full RAL** → CSR generator tool (sufficient for embedded)

### ➕ Unique to EVM
- Quiescence Counter (automatic test completion)
- Built-in scoreboard with 3 modes
- Direct virtual interface pattern
- Simplified reporting

---

## Should You Read These?

**If you're a user:**
- ❌ No, focus on the guides in `docs/`

**If you're curious about design decisions:**
- ✅ Yes, read UVM_vs_EVM_ANALYSIS.md for the big picture

**If you're extending EVM:**
- ✅ Yes, UVM_EVM_GAP_ANALYSIS.md shows what could be added

**If you're porting from UVM:**
- ✅ Yes, the comparison docs explain the differences

---

## Active Documentation

For current, user-facing documentation, see:
- **[docs/README.md](../README.md)** - Documentation index
- **[docs/QUICK_START.md](../QUICK_START.md)** - Get started in 5 minutes

---

**These documents are historical references - the decisions have already been made and implemented in EVM!**
