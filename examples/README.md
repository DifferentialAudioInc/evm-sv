# EVM Examples

**Working code examples** - Learn by running and modifying!

---

## 📚 Example Overview

| Example | Level | Focus | Time |
|---------|-------|-------|------|
| **[minimal_test](minimal_test/)** | Beginner | Basic test structure, QC | 10 min |
| **[qc_test](qc_test/)** | Beginner | Quiescence counter patterns | 15 min |
| **[complete_test](complete_test/)** | Intermediate | Monitor → Scoreboard TLM | 20 min |
| **[full_phases_test](full_phases_test/)** | Advanced | All 12 phases, agents | 30 min |

---

## 🎯 Recommended Learning Path

### 1. Start Here: minimal_test
**Purpose:** Understand the basics  
**You'll learn:**
- Test class structure
- Quiescence counter
- Objection management
- Basic phases

**Run it:**
```bash
cd minimal_test
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv minimal_test.sv
vsim -c minimal_test_top -do "run -all; quit"
```

---

### 2. Next: qc_test
**Purpose:** Master automatic test completion  
**You'll learn:**
- Built-in QC in evm_base_test
- Driver-QC integration
- Automatic vs manual objections
- QC configuration

**Run it:**
```bash
cd qc_test
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv qc_test.sv
vsim -c qc_test -do "run -all; quit"
```

---

### 3. Then: complete_test
**Purpose:** Production verification patterns  
**You'll learn:**
- Monitor design
- Analysis ports (TLM)
- Scoreboard checking
- Environment assembly
- Complete testbench structure

**Run it:**
```bash
cd complete_test
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv complete_test.sv
vsim -c tb_top -do "run -all; quit"
```

---

### 4. Finally: full_phases_test
**Purpose:** Complete understanding  
**You'll learn:**
- All 12 phases
- Multiple agents
- Clock/reset agents
- Complex hierarchy
- Phase coordination

**Run it:**
```bash
cd full_phases_test
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv \
     clk_rst_if.sv clk_agent.sv rst_agent.sv base_test.sv simple_dut.sv tb_top.sv
vsim -c tb_top -do "run -all; quit"
```

---

## 📖 What Each Example Teaches

### minimal_test/ - Absolute Basics

```systemverilog
class minimal_test extends evm_base_test;
    evm_qc qc;  // Automatic objection management
    
    virtual function void build_phase();
        super.build_phase();  // ALWAYS first!
        qc = new("qc", this);
        qc.set_threshold(50);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        repeat(10) begin
            qc.tick();  // Signal activity
            #10ns;
        end
        
        drop_objection("test");
    endtask
endclass
```

**Key lessons:**
- ✅ Always call `super.phase()` first
- ✅ Use QC for automatic test completion
- ✅ Raise/drop objections to control phases

---

### qc_test/ - Automatic Objections

```systemverilog
class qc_example_test extends evm_base_test;
    function new(string name = "qc_example_test");
        super.new(name);
        enable_quiescence_counter(200);  // Built-in QC!
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        driver.set_qc(qc);  // Driver can signal activity
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        // NO manual objections!
        seq.start(sequencer);
        // Test ends automatically
    endtask
endclass
```

**Key lessons:**
- ✅ `enable_quiescence_counter()` in constructor
- ✅ Pass QC to drivers/monitors
- ✅ `qc.tick()` on each transaction
- ✅ No manual objection management needed

---

### complete_test/ - TLM & Checking

```systemverilog
class my_env extends evm_component;
    my_monitor monitor;
    my_scoreboard scoreboard;
    
    virtual function void connect_phase();
        super.connect_phase();
        
        // TLM connection
        monitor.analysis_port.connect(
            scoreboard.analysis_imp.get_mailbox()
        );
    endfunction
endclass

// Monitor broadcasts
analysis_port.write(txn);

// Scoreboard receives and checks automatically
mode = EVM_SB_FIFO;
enable_auto_check = 1;
```

**Key lessons:**
- ✅ Analysis ports for broadcasting
- ✅ TLM connections in connect_phase
- ✅ Automatic scoreboard checking
- ✅ Transaction comparison

---

### full_phases_test/ - Complete System

```systemverilog
// Shows ALL 12 phases:
build_phase()                  // Create
connect_phase()                // Connect
end_of_elaboration_phase()     // Verify
start_of_simulation_phase()    // Initialize

reset_phase()                  // Reset DUT
configure_phase()              // Configure
main_phase()                   // Test
shutdown_phase()               // Cleanup

extract_phase()                // Get results
check_phase()                  // Verify results
report_phase()                 // Report
final_phase()                  // Cleanup
```

**Key lessons:**
- ✅ When to use each phase
- ✅ Phase execution order
- ✅ Multiple agent coordination
- ✅ Proper super calls in all phases

---

## 🎨 Example Comparison

| Feature | minimal | qc_test | complete | full_phases |
|---------|---------|---------|----------|-------------|
| **Lines of Code** | 50 | 200 | 300 | 500 |
| **Components** | Test only | Test, Driver, Seq | Monitor, SB, Env | Agents, Env, Test |
| **TLM** | No | No | Yes | Yes |
| **Phases** | 3 | 4 | 6 | 12 |
| **Complexity** | ★☆☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★★☆ |
| **Time to Understand** | 10 min | 15 min | 20 min | 30 min |

---

## 🔧 Common Modifications

### Add File Logging

```systemverilog
virtual function void build_phase();
    super.build_phase();
    evm_report_handler::enable_file_logging("my_test.log");
    evm_report_handler::set_verbosity(EVM_HIGH);
endfunction
```

### Change Verbosity

```systemverilog
evm_report_handler::set_verbosity(EVM_LOW);    // Quiet
evm_report_handler::set_verbosity(EVM_MEDIUM); // Default
evm_report_handler::set_verbosity(EVM_HIGH);   // Detailed
evm_report_handler::set_verbosity(EVM_DEBUG);  // Everything
```

### Add Waveform Dumping

```systemverilog
initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_top);
end
```

---

## 🚀 Next Steps

After running all examples:

1. **Modify** one to match your protocol
2. **Combine** concepts (QC + Monitor + Scoreboard)
3. **Build** your own testbench
4. **Refer** to docs/ for detailed guides

---

## 📞 Quick Help

**Problem:** Example won't compile?  
**Solution:** Check include path: `+incdir+../../vkit/src`

**Problem:** Example hangs?  
**Solution:** Check objections - forgot to drop?

**Problem:** No output?  
**Solution:** Check verbosity - try `EVM_HIGH`

**Problem:** Want to modify?  
**Solution:** Each example has detailed README!

---

## 📚 Related Documentation

- **[docs/QUICK_START.md](../docs/QUICK_START.md)** - Quick reference
- **[docs/EVM_PHASING_GUIDE.md](../docs/EVM_PHASING_GUIDE.md)** - Phase details
- **[docs/EVM_LOGGING_COMPLETE_GUIDE.md](../docs/EVM_LOGGING_COMPLETE_GUIDE.md)** - Logging
- **[docs/EVM_MONITOR_SCOREBOARD_GUIDE.md](../docs/EVM_MONITOR_SCOREBOARD_GUIDE.md)** - TLM

---

## Summary

**4 examples covering:**
- ✅ Basic test structure
- ✅ Automatic objections (QC)
- ✅ TLM communication
- ✅ Complete verification flow
- ✅ All 12 phases

**Start with minimal_test and work your way through!**

Each example builds on the previous, teaching you EVM incrementally.
