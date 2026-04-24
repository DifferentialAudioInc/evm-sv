//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_driver
// Description: Parameterized base driver class for EVM.
//              Uses virtual interface for driving signals.
//              No config database — direct virtual interface assignment.
//              run_phase() monitors reset events; main_phase() drives stimulus.
//
//   ── ARCHITECTURAL RULE (enforced by design) ──────────────────────────────
//   evm_driver has NO analysis_port. This is intentional and mandatory.
//
//   Drivers ONLY drive the bus. They receive sequence items from the sequencer
//   via seq_item_port, drive them on the VIF, and call item_done(). That is all.
//
//   Drivers NEVER:
//     - Publish to scoreboards
//     - Call analysis_port.write()
//     - Have knowledge of scoreboards or predictors
//
//   Observed transactions to scoreboards come EXCLUSIVELY from evm_monitor
//   via agent.analysis_port (monitor.analysis_port is aliased to agent's port).
//   The monitor shares the same VIF and observes everything the driver drives.
//
//   Expected scoreboard values come from the test/sequence level via
//   scoreboard.insert_expected() — the test knows what it intends to send.
//   ─────────────────────────────────────────────────────────────────────────
//
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-04-09 - Added run_phase reset monitoring, on_reset_* hooks
// Updated: 2026-04-24 - Documented NO-analysis_port architectural rule
//
// API — Public Interface:
//   [evm_driver#(VIF, REQ, RSP)] — virtual base class; NO analysis_port
//   new(name, parent)       — constructor; creates seq_item_port
//   set_vif(vif_handle)     — sets virtual interface handle
//   run_phase()             — monitors reset events in background
//   main_phase()            — override: drive stimulus from seq_item_port
//   on_reset_assert()       — override: idle bus on reset
//   on_reset_deassert()     — override: prepare bus after reset
//   seq_item_port           — pull items from sequencer (get_next_item/item_done)
//   vif                     — virtual interface handle (shared with monitor)
//==============================================================================

virtual class evm_driver #(type VIF, type REQ = int, type RSP = REQ) extends evm_component;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    VIF vif;
    
    //==========================================================================
    // Sequence Item Port - Pull items from sequencer
    // Source: UVM pattern - all drivers have seq_item_port
    // Rationale: Drivers MUST get stimulus from sequencer:
    //            - Enables sequence-based testbenches
    //            - Decouples stimulus generation from driving
    //            - Allows layered/virtual sequences
    //            - Standard protocol: get_next_item() -> drive() -> item_done()
    // Usage: In main_phase():
    //        forever begin
    //          seq_item_port.get_next_item(req);
    //          drive_transaction(req);
    //          seq_item_port.item_done();
    //        end
    // UVM Equivalent: uvm_seq_item_pull_port#(REQ,RSP) seq_item_port
    //==========================================================================
    evm_seq_item_pull_port#(REQ, RSP) seq_item_port;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_driver", evm_component parent = null);
        super.new(name, parent);
        // Create sequence item port
        seq_item_port = new({name, ".seq_item_port"}, this);
    endfunction
    
    //==========================================================================
    // Set Virtual Interface - Called by agent or test
    //==========================================================================
    function void set_vif(VIF vif_handle);
        if (vif_handle == null) begin
            log_error("Attempting to set null virtual interface");
        end else begin
            this.vif = vif_handle;
            log_info("Virtual interface set", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Run Phase - Reset Event Monitor (runs parallel to sequential phases)
    // Source: EVM mid-simulation reset support
    // Rationale: Driver must respond to mid-simulation reset events:
    //            - Stop ongoing transactions when reset asserts
    //            - Resume driving when reset deasserts
    //            - Prevents protocol violations during reset
    // Note: Driver stimulus remains in main_phase() driven by sequences.
    //       This run_phase() only handles reset events in the background.
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        
        if (vif == null) begin
            log_warning("Driver run_phase: virtual interface not set, skipping reset monitor");
            return;
        end
        
        log_info("Driver run_phase: reset event monitor active", EVM_HIGH);
        
        fork
            begin
                // Background thread: monitor reset events indefinitely
                forever begin
                    @(reset_asserted);
                    on_reset_assert();
                    @(reset_deasserted);
                    on_reset_deassert();
                end
            end
        join_none
    endtask
    
    //==========================================================================
    // Driver Main Phase - Override in derived drivers
    // Rationale: Stimulus generation happens here, driven by sequences
    //            Check in_reset flag before driving to avoid protocol violations
    //==========================================================================
    virtual task main_phase();
        if (vif == null) begin
            log_error("Virtual interface not set - cannot drive");
            return;
        end
        log_info("Driver main_phase started", EVM_LOW);
        // Override in derived class to drive interface
        // Pattern:
        //   forever begin
        //     if (!in_reset) begin
        //       seq_item_port.get_next_item(req);
        //       drive_transaction(req);
        //       seq_item_port.item_done();
        //     end else begin
        //       @(reset_deasserted);
        //     end
        //   end
    endtask
    
    //==========================================================================
    // Reset Event Handlers - Override in derived drivers
    // Called from run_phase() background thread when reset events occur
    //==========================================================================
    
    // Handle reset assertion - stop driving, idle the bus
    // Typical actions:
    //   - Deassert all output signals (idle state)
    //   - Abandon any in-progress transaction
    //   - Clear any local state/queues
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("Driver: reset asserted, idling bus", EVM_MEDIUM);
        // Derived class: deassert outputs here
    endtask
    
    // Handle reset deassertion - ready to drive again
    // Typical actions:
    //   - Initialize bus to idle state
    //   - Prepare for first transaction
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("Driver: reset deasserted, ready to drive", EVM_MEDIUM);
        // Derived class: prepare bus for operation here
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_driver";
    endfunction
    
endclass : evm_driver
