//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_agent.sv
// Description: Parameterized base agent class for EVM.
//              Enforces the EVM Active/Passive agent architecture:
//
//   ── ARCHITECTURAL RULE (enforced at runtime) ─────────────────────────────
//   Every agent has ONE shared virtual interface (VIF) connected to the DUT.
//   Both driver and monitor receive the same VIF handle via set_vif().
//
//   ACTIVE mode (EVM_ACTIVE):
//     - Monitor ALWAYS created — observes bus, publishes via analysis_port
//     - Driver ALWAYS created — drives bus from sequencer items
//     - Sequencer ALWAYS created — dispatches sequence items to driver
//
//   PASSIVE mode (EVM_PASSIVE):
//     - Monitor ONLY — observes bus, publishes via analysis_port
//     - No driver. No sequencer.
//
//   CRITICAL: Only monitors publish observed transactions to scoreboards.
//             Drivers NEVER have analysis_port. Drivers NEVER call write().
//             Expected scoreboard values come from test/sequence via
//             scoreboard.insert_expected() — not from the driver.
//   ─────────────────────────────────────────────────────────────────────────
//
//   ── ANALYSIS PORT OWNERSHIP ──────────────────────────────────────────────
//   The AGENT owns the primary analysis_port. The monitor's analysis_port
//   is redirected to the agent's port in build_phase (port aliasing).
//   This means:
//     - Monitor calls analysis_port.write(txn) as always (no monitor changes)
//     - External code connects to agent.analysis_port — NOT monitor.analysis_port
//     - Only the agent controls what subscribers receive transactions
//   Protocol-specific extra ports (ap_write, ap_read, ap_err, etc.) remain
//   on the typed monitor and are accessed via get_monitor().
//   ─────────────────────────────────────────────────────────────────────────
//
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-04-24 - Strengthened Active/Passive enforcement; fatal if monitor null
// Updated: 2026-04-24 - Agent now owns analysis_port; monitor.analysis_port aliased to it
//
// API — Public Interface:
//   [evm_agent#(VIF, T)] — virtual base class
//   new(name, parent)          — constructor; default mode=EVM_ACTIVE
//   analysis_port              — PRIMARY observable port (connect scoreboards here)
//   set_vif(vif_handle)        — propagates VIF to driver and monitor
//   set_mode(mode)             — set EVM_ACTIVE or EVM_PASSIVE (before build_phase)
//   get_mode()                 — return current mode
//   is_active()                — return 1 if EVM_ACTIVE
//   build_phase()              — creates monitor always; driver+sequencer if ACTIVE;
//                                redirects monitor.analysis_port → this.analysis_port
//   connect_phase()            — connects driver.seq_item_port → sequencer.seq_item_export
//   create_monitor(name) [pv]  — override: return your typed monitor
//   create_driver(name)  [pv]  — override: return your typed driver (ACTIVE only)
//   create_sequencer(name)     — override optional: default evm_sequencer
//==============================================================================

virtual class evm_agent #(type VIF, type T = int) extends evm_component;
    
    //==========================================================================
    // Agent Mode
    //==========================================================================
    typedef enum {
        EVM_PASSIVE,  // Monitor ONLY — no driver, no sequencer
        EVM_ACTIVE    // Monitor + Driver + Sequencer
    } evm_agent_mode_e;
    
    //==========================================================================
    // Properties
    // Monitor is ALWAYS present (both modes).
    // Driver and Sequencer are ONLY present in EVM_ACTIVE mode.
    //
    // analysis_port: THE canonical observable port — owned by the agent.
    //   build_phase() redirects monitor.analysis_port to this object so that
    //   monitor.write() calls route through the agent's port. External code
    //   (env connect_phase) connects to agent.analysis_port, not monitor.analysis_port.
    //==========================================================================
    evm_agent_mode_e           mode;
    evm_analysis_port#(T)      analysis_port; // AGENT-OWNED — primary observable port
    evm_monitor#(VIF, T)       monitor;       // ALWAYS created — writes via analysis_port
    evm_driver#(VIF, T, T)     driver;        // ACTIVE only — drives bus; NO analysis_port
    evm_sequencer#(T, T)       sequencer;     // ACTIVE only — dispatches to driver
    VIF                        vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_agent", evm_component parent = null);
        super.new(name, parent);
        mode          = EVM_ACTIVE;  // Default to active mode
        analysis_port = new("analysis_port", this);
    endfunction
    
    //==========================================================================
    // set_vif() — propagates VIF to driver and monitor
    // Both driver and monitor share the SAME physical interface.
    //==========================================================================
    function void set_vif(VIF vif_handle);
        if (vif_handle == null) begin
            log_warning("[AGENT] set_vif(): null handle — will be applied later via connect_phase");
        end else begin
            this.vif = vif_handle;
            if (monitor != null) monitor.set_vif(vif_handle);
            if (driver  != null) driver.set_vif(vif_handle);
            log_info($sformatf("[AGENT %s] VIF set — propagated to monitor%s",
                               get_full_name(),
                               (driver != null) ? " and driver" : " (passive: no driver)"), EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // build_phase — enforces Active/Passive architecture
    //
    // Enforcement rules (fatal if violated):
    //   1. Monitor MUST always be created (both ACTIVE and PASSIVE)
    //   2. Driver MUST be created if ACTIVE
    //   3. Sequencer MUST be created if ACTIVE
    //   4. Driver and Sequencer MUST NOT exist in PASSIVE mode
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // ── Rule 1: Monitor is MANDATORY in both modes ───────────────────────
        monitor = create_monitor("monitor");
        if (monitor == null) begin
            log_fatal($sformatf(
                "[AGENT %s] create_monitor() returned null. " +
                "Monitor is MANDATORY — override create_monitor() in your derived agent.",
                get_full_name()));
            return;
        end
        // ── Port aliasing: redirect monitor's analysis_port to agent's ────────
        // The monitor calls analysis_port.write(txn) as normal, but that port
        // is now the agent's port. External code connects to agent.analysis_port.
        // The monitor's own newly-created port object is discarded (GC'd).
        monitor.analysis_port = this.analysis_port;
        if (vif != null) monitor.set_vif(vif);
        log_info($sformatf("[AGENT %s] Monitor created (mode=%s); analysis_port owned by agent",
                           get_full_name(),
                           mode == EVM_ACTIVE ? "ACTIVE" : "PASSIVE"), EVM_MED);
        
        // ── Rules 2+3: Driver and Sequencer only in ACTIVE mode ──────────────
        if (mode == EVM_ACTIVE) begin
            driver = create_driver("driver");
            if (driver == null) begin
                log_fatal($sformatf(
                    "[AGENT %s] create_driver() returned null in ACTIVE mode. " +
                    "Override create_driver() in your derived agent. " +
                    "Alternatively, set mode = EVM_PASSIVE before build_phase.",
                    get_full_name()));
                return;
            end
            if (vif != null) driver.set_vif(vif);
            
            sequencer = create_sequencer("sequencer");
            if (sequencer == null) begin
                log_fatal($sformatf(
                    "[AGENT %s] create_sequencer() returned null in ACTIVE mode.",
                    get_full_name()));
                return;
            end
            log_info($sformatf("[AGENT %s] Driver + Sequencer created (ACTIVE)", get_full_name()), EVM_MED);
            
        end else begin
            // ── Rule 4: Passive agents have NO driver or sequencer ────────────
            driver    = null;
            sequencer = null;
            log_info($sformatf("[AGENT %s] No driver/sequencer (PASSIVE mode)", get_full_name()), EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // run_phase — validates VIF was set and mode consistency
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_error($sformatf("[AGENT %s] VIF is null at run_phase — was set_vif() called in connect_phase?",
                                get_full_name()));
        end
        // Sanity check: passive agents should never have a driver
        if (mode == EVM_PASSIVE && driver != null) begin
            log_fatal($sformatf("[AGENT %s] PASSIVE agent has a driver — architectural violation!",
                                get_full_name()));
        end
    endtask
    
    //==========================================================================
    // connect_phase — connects driver.seq_item_port → sequencer.seq_item_export
    // Only in ACTIVE mode. No connections needed in PASSIVE mode.
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        if (mode == EVM_ACTIVE && driver != null && sequencer != null) begin
            if (driver.seq_item_port != null && sequencer.seq_item_export != null) begin
                driver.seq_item_port.connect(
                    sequencer.seq_item_export.get_req_fifo(),
                    sequencer.seq_item_export.get_rsp_fifo()
                );
                log_info($sformatf("[AGENT %s] driver.seq_item_port → sequencer.seq_item_export connected",
                                   get_full_name()), EVM_MEDIUM);
            end
        end
    endfunction
    
    //==========================================================================
    // Factory Methods — MUST override in derived agents
    //==========================================================================
    
    // create_monitor() — MUST override; called for both ACTIVE and PASSIVE agents
    // Returns an evm_monitor that has analysis_port for publishing observed txns
    virtual function evm_monitor#(VIF, T) create_monitor(string name);
        log_error($sformatf("[AGENT %s] create_monitor() not overridden — return your typed monitor",
                            get_full_name()));
        return null;
    endfunction
    
    // create_driver() — MUST override for ACTIVE agents (not called in PASSIVE mode)
    // Returns an evm_driver that has seq_item_port but NO analysis_port
    virtual function evm_driver#(VIF, T, T) create_driver(string name);
        log_error($sformatf("[AGENT %s] create_driver() not overridden — return your typed driver",
                            get_full_name()));
        return null;
    endfunction
    
    // create_sequencer() — default implementation; override for custom sequencers
    virtual function evm_sequencer#(T, T) create_sequencer(string name);
        evm_sequencer#(T, T) sqr;
        sqr = new(name, this);
        return sqr;
    endfunction
    
    //==========================================================================
    // Utility
    //==========================================================================
    function void set_mode(evm_agent_mode_e new_mode);
        mode = new_mode;
        log_info($sformatf("[AGENT %s] Mode set to %s",
                 get_full_name(), mode == EVM_ACTIVE ? "ACTIVE" : "PASSIVE"), EVM_MED);
    endfunction
    
    function evm_agent_mode_e get_mode();
        return mode;
    endfunction
    
    function bit is_active();
        return (mode == EVM_ACTIVE);
    endfunction
    
    virtual function string get_type_name();
        return "evm_agent";
    endfunction
    
endclass : evm_agent
