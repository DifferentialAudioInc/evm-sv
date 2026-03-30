# EVM Documentation

**Embedded Verification Methodology - User Guides**

---

## 📚 Getting Started

### [QUICK_START.md](QUICK_START.md) - **Start Here!**
Get up and running with EVM in 5 minutes. Covers:
- Basic structure (transaction, monitor, driver, scoreboard)
- The 12 phases
- Key patterns
- Complete examples

---

## 📖 Core Guides

### [EVM_PHASING_GUIDE.md](EVM_PHASING_GUIDE.md)
Complete guide to EVM's 12-phase methodology:
- Build, Connect, Elaboration, Start phases
- Reset, Configure, Main, Shutdown phases  
- Extract, Check, Report, Final phases
- Objection mechanism
- Phase execution order

### [EVM_LOGGING_COMPLETE_GUIDE.md](EVM_LOGGING_COMPLETE_GUIDE.md)
Comprehensive logging and reporting guide:
- 4 Severity levels (INFO, WARNING, ERROR, FATAL)
- 6 Verbosity levels (NONE to DEBUG)
- File logging
- Message statistics
- Configuration options
- Best practices

### [EVM_VIRTUAL_INTERFACE_GUIDE.md](EVM_VIRTUAL_INTERFACE_GUIDE.md)
Virtual interface usage (no config DB needed):
- Direct VIF assignment pattern
- Agent/Driver/Monitor setup
- Testbench integration
- Simpler than UVM approach

### [EVM_MONITOR_SCOREBOARD_GUIDE.md](EVM_MONITOR_SCOREBOARD_GUIDE.md)
TLM communication and checking:
- Monitor → Scoreboard pattern
- Analysis ports (TLM 1.0)
- Automatic scoreboard checking
- 3 checking modes (FIFO, Associative, Unordered)

### [UVM_FEATURES_NOT_IMPLEMENTED.md](UVM_FEATURES_NOT_IMPLEMENTED.md)
Explicit list of UVM features NOT in EVM (and why):
- 20 major UVM features intentionally excluded
- Rationale for each decision
- EVM alternatives for each
- When to use UVM vs EVM

---

## 🎯 Recommended Reading Order

1. **[QUICK_START.md](QUICK_START.md)** - Basic concepts
2. **[EVM_PHASING_GUIDE.md](EVM_PHASING_GUIDE.md)** - Phase system
3. **[EVM_VIRTUAL_INTERFACE_GUIDE.md](EVM_VIRTUAL_INTERFACE_GUIDE.md)** - VIF setup
4. **[EVM_MONITOR_SCOREBOARD_GUIDE.md](EVM_MONITOR_SCOREBOARD_GUIDE.md)** - Checking
5. **[EVM_LOGGING_COMPLETE_GUIDE.md](EVM_LOGGING_COMPLETE_GUIDE.md)** - Reporting

---

## 💡 Examples

Live code examples are in `examples/`:

| Example | Focus |
|---------|-------|
| **minimal_test/** | Simplest possible test |
| **qc_test/** | Automatic test completion with Quiescence Counter |
| **complete_test/** | Monitor → Scoreboard flow |
| **full_phases_test/** | Complete agent with all 12 phases |

---

## 🔍 Archive

Historical analysis and planning documents are in `archive/`:
- UVM comparison studies
- Gap analysis
- Feature planning documents
- Implementation notes

These are kept for reference but not needed for daily use.

---

## 📞 Quick Help

**Problem:** Not sure where to start?  
**Solution:** Read [QUICK_START.md](QUICK_START.md) and run `examples/minimal_test/`

**Problem:** Test never ends?  
**Solution:** Check [EVM_PHASING_GUIDE.md](EVM_PHASING_GUIDE.md) - did you forget to drop objection?

**Problem:** Components not communicating?  
**Solution:** Check [EVM_MONITOR_SCOREBOARD_GUIDE.md](EVM_MONITOR_SCOREBOARD_GUIDE.md) for TLM connection pattern

**Problem:** Too many/too few log messages?  
**Solution:** Check [EVM_LOGGING_COMPLETE_GUIDE.md](EVM_LOGGING_COMPLETE_GUIDE.md) for verbosity settings

---

## 🎉 Summary

**6 Essential Guides** - Everything you need to build production testbenches  
**4 Working Examples** - Copy and adapt for your projects  
**Clean and Focused** - No clutter, just practical guides  

**Start with QUICK_START.md and you'll be productive in hours!**
