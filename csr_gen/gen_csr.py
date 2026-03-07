#!/usr/bin/env python3
"""
CSR Generator for DSP-4CH-100M
Generates SystemVerilog RTL and C header files from YAML register definitions

Author: Engineering Team
Date: 2026-03-04
"""

import yaml
import sys
from pathlib import Path
from datetime import datetime

class CSRGenerator:
    def __init__(self, yaml_file):
        """Initialize CSR generator with YAML definition file"""
        self.yaml_file = yaml_file
        with open(yaml_file, 'r') as f:
            self.data = yaml.safe_load(f)
        
        self.modules = self.data['modules']
        self.timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    def generate_all(self, output_dir='.'):
        """Generate all RTL and C header files"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Generate per-module files in separate directories
        for module in self.modules:
            module_name = module['name'].lower()
            
            # Create module-specific directory
            module_dir = output_path / module_name
            module_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate SystemVerilog
            sv_file = module_dir / f"{module_name}_csr_pkg.sv"
            self.generate_sv_package(module, sv_file)
            print(f"Generated: {sv_file}")
            
            sv_rtl_file = module_dir / f"{module_name}_csr.sv"
            self.generate_sv_module(module, sv_rtl_file)
            print(f"Generated: {sv_rtl_file}")
            
            # Generate C header
            h_file = module_dir / f"{module_name}_csr.h"
            self.generate_c_header(module, h_file)
            print(f"Generated: {h_file}")
        
        # Generate master files
        master_h = output_path / "dsp_regs.h"
        self.generate_master_c_header(master_h)
        print(f"Generated: {master_h}")
        
        # Generate path definitions
        sv_paths = output_path / "csr_paths.svh"
        self.generate_sv_paths(sv_paths)
        print(f"Generated: {sv_paths}")
        
        c_paths = output_path / "csr_paths.h"
        self.generate_c_paths(c_paths)
        print(f"Generated: {c_paths}")
        
        # Generate documentation
        doc_file = output_path / "register_map.md"
        self.generate_documentation(doc_file)
        print(f"Generated: {doc_file}")
        
        # Generate file lists
        sv_filelist = output_path / "csr_files.f"
        self.generate_sv_filelist(sv_filelist, output_path)
        print(f"Generated: {sv_filelist}")
        
        tcl_filelist = output_path / "csr_files.tcl"
        self.generate_tcl_filelist(tcl_filelist, output_path)
        print(f"Generated: {tcl_filelist}")
    
    def generate_sv_package(self, module, output_file):
        """Generate SystemVerilog package with register structures"""
        module_name = module['name'].lower()
        MODULE_NAME = module['name'].upper()
        
        lines = []
        lines.append(f"//{'='*78}")
        lines.append(f"// Package: {module_name}_csr_pkg")
        lines.append(f"// Description: CSR definitions for {module['description']}")
        lines.append(f"// Generated: {self.timestamp}")
        lines.append(f"// Source: {self.yaml_file}")
        lines.append(f"//{'='*78}")
        lines.append("")
        lines.append(f"package {module_name}_csr_pkg;")
        lines.append("")
        
        # Base address
        lines.append(f"    // Module base address")
        base_addr = module['base_address'] if isinstance(module['base_address'], str) else f"0x{module['base_address']:08X}"
        lines.append(f"    localparam logic [31:0] {MODULE_NAME}_BASE_ADDR = 32'h{base_addr[2:].upper()};")
        lines.append("")
        
        # Register offsets
        lines.append(f"    // Register offsets")
        for reg in module['registers']:
            reg_name = reg['name']
            offset = reg['offset'] if isinstance(reg['offset'], str) else f"0x{reg['offset']:08X}"
            lines.append(f"    localparam logic [31:0] {MODULE_NAME}_{reg_name}_OFFSET = 32'h{offset[2:].upper()};")
        lines.append("")
        
        # Generate field structures for each register
        for reg in module['registers']:
            reg_name = reg['name']
            
            lines.append(f"    // {reg['description']}")
            lines.append(f"    typedef struct packed {{")
            
            # Sort fields by MSB (descending)
            fields_sorted = sorted(reg['fields'], key=lambda f: (f['bits'][0] if isinstance(f['bits'], list) and len(f['bits']) == 2 else (f['bits'][0] if isinstance(f['bits'], list) else f['bits'])), reverse=True)
            
            for field in fields_sorted:
                field_name = field['name'].lower()
                bits = field['bits']
                
                if isinstance(bits, list):
                    if len(bits) == 2:
                        width = bits[0] - bits[1] + 1
                        msb = bits[0]
                        lsb = bits[1]
                    else:
                        width = 1
                        msb = lsb = bits[0]
                else:
                    width = 1
                    msb = lsb = bits
                
                if width == 1:
                    lines.append(f"        logic        {field_name:20s}; // [{msb}] {field['description']}")
                else:
                    lines.append(f"        logic [{width-1:2d}:0] {field_name:20s}; // [{msb}:{lsb}] {field['description']}")
            
            lines.append(f"    }} {module_name}_{reg_name.lower()}_t;")
            lines.append("")
        
        # Register block structure (union of all registers)
        lines.append(f"    // Register block union")
        lines.append(f"    typedef union packed {{")
        for reg in module['registers']:
            reg_name = reg['name'].lower()
            lines.append(f"        {module_name}_{reg_name}_t {reg_name};")
        lines.append(f"        logic [31:0] raw;")
        lines.append(f"    }} {module_name}_reg_t;")
        lines.append("")
        
        # Register file structure
        lines.append(f"    // Complete register file structure")
        lines.append(f"    typedef struct {{")
        for reg in module['registers']:
            reg_name = reg['name'].lower()
            lines.append(f"        {module_name}_reg_t {reg_name:20s}; // Offset: {reg['offset']}")
        lines.append(f"    }} {module_name}_regs_t;")
        lines.append("")
        
        lines.append(f"endpackage : {module_name}_csr_pkg")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_sv_module(self, module, output_file):
        """Generate SystemVerilog module for CSR implementation"""
        module_name = module['name'].lower()
        MODULE_NAME = module['name'].upper()
        
        lines = []
        lines.append(f"//{'='*78}")
        lines.append(f"// Module: {module_name}_csr")
        lines.append(f"// Description: CSR implementation for {module['description']}")
        lines.append(f"// Generated: {self.timestamp}")
        lines.append(f"// Source: {self.yaml_file}")
        lines.append(f"//{'='*78}")
        lines.append("")
        lines.append(f"import {module_name}_csr_pkg::*;")
        lines.append("")
        lines.append(f"module {module_name}_csr (")
        lines.append(f"    // Clock and Reset")
        lines.append(f"    input  logic        clk,")
        lines.append(f"    input  logic        rst_n,")
        lines.append(f"    ")
        lines.append(f"    // CPU Interface (simple read/write)")
        lines.append(f"    input  logic        csr_wr_en,")
        lines.append(f"    input  logic        csr_rd_en,")
        lines.append(f"    input  logic [31:0] csr_addr,")
        lines.append(f"    input  logic [31:0] csr_wr_data,")
        lines.append(f"    output logic [31:0] csr_rd_data,")
        lines.append(f"    output logic        csr_rd_valid,")
        lines.append(f"    ")
        lines.append(f"    // Register outputs (to logic)")
        
        # Output ports for RW registers
        for reg in module['registers']:
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                lines.append(f"    output {module_name}_reg_t {reg_name}_o,")
        
        lines.append(f"    ")
        lines.append(f"    // Register inputs (from logic)")
        
        # Input ports for RO registers
        ro_regs = [r for r in module['registers'] if r['access'] == 'RO']
        for i, reg in enumerate(ro_regs):
            reg_name = reg['name'].lower()
            comma = '' if i == len(ro_regs) - 1 else ','
            lines.append(f"    input  {module_name}_reg_t {reg_name}_i{comma}")
        
        lines.append(f");")
        lines.append(f"")
        lines.append(f"    // Register storage")
        
        # Declare register storage
        for reg in module['registers']:
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                lines.append(f"    {module_name}_reg_t {reg_name}_q, {reg_name}_d;")
        
        lines.append(f"")
        lines.append(f"    // Address decode")
        lines.append(f"    logic [{len(module['registers'])-1}:0] reg_sel_wr;")
        lines.append(f"    logic [{len(module['registers'])-1}:0] reg_sel_rd;")
        lines.append(f"")
        
        # Address decode logic
        lines.append(f"    always_comb begin")
        lines.append(f"        reg_sel_wr = '0;")
        lines.append(f"        reg_sel_rd = '0;")
        lines.append(f"        ")
        lines.append(f"        case (csr_addr)")
        
        for i, reg in enumerate(module['registers']):
            reg_name = reg['name']
            offset = reg['offset']
            lines.append(f"            {MODULE_NAME}_BASE_ADDR + {MODULE_NAME}_{reg_name}_OFFSET: begin")
            lines.append(f"                reg_sel_wr[{i}] = csr_wr_en;")
            lines.append(f"                reg_sel_rd[{i}] = csr_rd_en;")
            lines.append(f"            end")
        
        lines.append(f"            default: begin")
        lines.append(f"                reg_sel_wr = '0;")
        lines.append(f"                reg_sel_rd = '0;")
        lines.append(f"            end")
        lines.append(f"        endcase")
        lines.append(f"    end")
        lines.append(f"")
        
        # Write logic for RW/WO registers
        lines.append(f"    // Write logic")
        for i, reg in enumerate(module['registers']):
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                lines.append(f"    always_comb begin")
                lines.append(f"        {reg_name}_d = {reg_name}_q;")
                lines.append(f"        if (reg_sel_wr[{i}]) begin")
                lines.append(f"            {reg_name}_d.raw = csr_wr_data;")
                lines.append(f"        end")
                lines.append(f"    end")
                lines.append(f"")
        
        # Sequential logic for RW/WO registers
        lines.append(f"    // Register update")
        lines.append(f"    always_ff @(posedge clk) begin")
        lines.append(f"        if (!rst_n) begin")
        for reg in module['registers']:
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                reset_val = reg['reset'] if isinstance(reg['reset'], str) else f"32'h{reg['reset']:08X}"
                lines.append(f"            {reg_name}_q.raw <= {reset_val};")
        lines.append(f"        end else begin")
        for reg in module['registers']:
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                lines.append(f"            {reg_name}_q <= {reg_name}_d;")
        lines.append(f"        end")
        lines.append(f"    end")
        lines.append(f"")
        
        # Read logic
        lines.append(f"    // Read logic")
        lines.append(f"    always_ff @(posedge clk) begin")
        lines.append(f"        if (!rst_n) begin")
        lines.append(f"            csr_rd_data  <= 32'h0;")
        lines.append(f"            csr_rd_valid <= 1'b0;")
        lines.append(f"        end else begin")
        lines.append(f"            csr_rd_valid <= |reg_sel_rd;")
        lines.append(f"            csr_rd_data  <= 32'h0;")
        lines.append(f"            ")
        lines.append(f"            case (1'b1)")
        
        for i, reg in enumerate(module['registers']):
            reg_name = reg['name'].lower()
            if reg['access'] in ['RW', 'WO']:
                lines.append(f"                reg_sel_rd[{i}]: csr_rd_data <= {reg_name}_q.raw;")
            else:  # RO
                lines.append(f"                reg_sel_rd[{i}]: csr_rd_data <= {reg_name}_i.raw;")
        
        lines.append(f"                default: csr_rd_data <= 32'h0;")
        lines.append(f"            endcase")
        lines.append(f"        end")
        lines.append(f"    end")
        lines.append(f"")
        
        # Output assignments
        lines.append(f"    // Output assignments")
        for reg in module['registers']:
            if reg['access'] in ['RW', 'WO']:
                reg_name = reg['name'].lower()
                lines.append(f"    assign {reg_name}_o = {reg_name}_q;")
        lines.append(f"")
        
        lines.append(f"endmodule : {module_name}_csr")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_c_header(self, module, output_file):
        """Generate C header file with register definitions"""
        module_name = module['name'].lower()
        MODULE_NAME = module['name'].upper()
        guard = f"__{MODULE_NAME}_CSR_H__"
        
        lines = []
        lines.append(f"/*{'='*76}*/")
        lines.append(f"/* File: {output_file.name}")
        lines.append(f" * Description: CSR definitions for {module['description']}")
        lines.append(f" * Generated: {self.timestamp}")
        lines.append(f" * Source: {self.yaml_file}")
        lines.append(f" */")
        lines.append(f"/*{'='*76}*/")
        lines.append("")
        lines.append(f"#ifndef {guard}")
        lines.append(f"#define {guard}")
        lines.append("")
        lines.append(f"#include <stdint.h>")
        lines.append("")
        lines.append(f"/* Module base address */")
        lines.append(f"#define {MODULE_NAME}_BASE_ADDR    {module['base_address']}")
        lines.append("")
        
        # Register offsets
        lines.append(f"/* Register offsets */")
        for reg in module['registers']:
            reg_name = reg['name']
            offset = reg['offset']
            lines.append(f"#define {MODULE_NAME}_{reg_name}_OFFSET    {offset}")
        lines.append("")
        
        # Absolute addresses
        lines.append(f"/* Absolute register addresses */")
        for reg in module['registers']:
            reg_name = reg['name']
            base = module['base_address'] if isinstance(module['base_address'], int) else int(module['base_address'], 16)
            offset = reg['offset'] if isinstance(reg['offset'], int) else int(reg['offset'], 16)
            addr = base + offset
            lines.append(f"#define {MODULE_NAME}_{reg_name}_ADDR      0x{addr:08X}U")
        lines.append("")
        
        # Field definitions for each register
        for reg in module['registers']:
            reg_name = reg['name']
            lines.append(f"/* {reg['description']} */")
            
            # Field structures
            lines.append(f"typedef union {{")
            lines.append(f"    struct {{")
            
            # Need to reverse order for C bit fields (LSB first)
            fields_sorted = sorted(reg['fields'], key=lambda f: (f['bits'][1] if isinstance(f['bits'], list) and len(f['bits']) == 2 else (f['bits'][0] if isinstance(f['bits'], list) else f['bits'])))
            
            for field in fields_sorted:
                field_name = field['name'].lower()
                bits = field['bits']
                
                if isinstance(bits, list):
                    if len(bits) == 2:
                        width = bits[0] - bits[1] + 1
                    else:
                        width = 1
                else:
                    width = 1
                
                lines.append(f"        uint32_t {field_name:20s} : {width:2d};  /* {field['description']} */")
            
            lines.append(f"    }} fields;")
            lines.append(f"    uint32_t raw;")
            lines.append(f"}} {module_name}_{reg_name.lower()}_t;")
            lines.append("")
            
            # Bit position and mask defines
            for field in reg['fields']:
                field_name = field['name']
                bits = field['bits']
                
                if isinstance(bits, list):
                    if len(bits) == 2:
                        width = bits[0] - bits[1] + 1
                        lsb = bits[1]
                    else:
                        width = 1
                        lsb = bits[0]
                    mask = (1 << width) - 1
                else:
                    lsb = bits
                    mask = 1
                
                lines.append(f"#define {MODULE_NAME}_{reg_name}_{field_name}_POS    {lsb}")
                lines.append(f"#define {MODULE_NAME}_{reg_name}_{field_name}_MASK   0x{mask:08X}U")
        
        lines.append("")
        
        # Complete register block structure
        lines.append(f"/* Complete {module_name.upper()} register block */")
        lines.append(f"typedef struct {{")
        for reg in module['registers']:
            reg_name = reg['name'].lower()
            lines.append(f"    {module_name}_{reg_name}_t {reg_name:20s}; /* {reg['description']} */")
        lines.append(f"}} {module_name}_regs_t;")
        lines.append("")
        
        # Pointer to register block
        lines.append(f"/* Pointer to register block in memory */")
        lines.append(f"#define {MODULE_NAME}_REGS    ((volatile {module_name}_regs_t *){MODULE_NAME}_BASE_ADDR)")
        lines.append("")
        
        lines.append(f"#endif /* {guard} */")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_master_c_header(self, output_file):
        """Generate master C header that includes all modules"""
        lines = []
        lines.append(f"/*{'='*76}*/")
        lines.append(f"/* File: {output_file.name}")
        lines.append(f" * Description: Master register map for DSP-4CH-100M")
        lines.append(f" * Generated: {self.timestamp}")
        lines.append(f" * Source: {self.yaml_file}")
        lines.append(f" */")
        lines.append(f"/*{'='*76}*/")
        lines.append("")
        lines.append(f"#ifndef __DSP_REGS_H__")
        lines.append(f"#define __DSP_REGS_H__")
        lines.append("")
        
        # Include all module headers with subdirectory paths
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"#include \"{module_name}/{module_name}_csr.h\"")
        
        lines.append("")
        lines.append(f"/* Product information */")
        lines.append(f"#define DSP_PRODUCT_NAME    \"DSP-4CH-100M\"")
        lines.append(f"#define DSP_VERSION_MAJOR   1")
        lines.append(f"#define DSP_VERSION_MINOR   0")
        lines.append(f"#define DSP_VERSION_PATCH   0")
        lines.append("")
        
        lines.append(f"#endif /* __DSP_REGS_H__ */")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_sv_paths(self, output_file):
        """Generate SystemVerilog include paths file"""
        lines = []
        lines.append(f"//{'='*78}")
        lines.append(f"// File: csr_paths.svh")
        lines.append(f"// Description: SystemVerilog include paths for CSR modules")
        lines.append(f"// Generated: {self.timestamp}")
        lines.append(f"// Source: {self.yaml_file}")
        lines.append(f"//{'='*78}")
        lines.append("")
        lines.append(f"// Include this file to get all CSR package paths")
        lines.append(f"// Usage: `include \"csr_paths.svh\"")
        lines.append("")
        lines.append(f"// CSR module include paths")
        
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"`define CSR_{module_name.upper()}_PKG_PATH \"{module_name}/{module_name}_csr_pkg.sv\"")
            lines.append(f"`define CSR_{module_name.upper()}_RTL_PATH \"{module_name}/{module_name}_csr.sv\"")
        
        lines.append("")
        lines.append(f"// Import all CSR packages")
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"// import {module_name}_csr_pkg::*;")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_c_paths(self, output_file):
        """Generate C include paths file"""
        lines = []
        lines.append(f"/*{'='*76}*/")
        lines.append(f"/* File: csr_paths.h")
        lines.append(f" * Description: C include paths for CSR modules")
        lines.append(f" * Generated: {self.timestamp}")
        lines.append(f" * Source: {self.yaml_file}")
        lines.append(f" */")
        lines.append(f"/*{'='*76}*/")
        lines.append("")
        lines.append(f"#ifndef __CSR_PATHS_H__")
        lines.append(f"#define __CSR_PATHS_H__")
        lines.append("")
        lines.append(f"/* CSR module include paths */")
        lines.append(f"/* Use these in your build system or makefile */")
        lines.append("")
        
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"#define CSR_{module_name.upper()}_HEADER_PATH \"{module_name}/{module_name}_csr.h\"")
        
        lines.append("")
        lines.append(f"/* Include all CSR headers */")
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"/* #include CSR_{module_name.upper()}_HEADER_PATH */")
        
        lines.append("")
        lines.append(f"#endif /* __CSR_PATHS_H__ */")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_sv_filelist(self, output_file, output_path):
        """Generate SystemVerilog filelist for simulation tools"""
        lines = []
        lines.append(f"# CSR SystemVerilog File List")
        lines.append(f"# Generated: {self.timestamp}")
        lines.append(f"# Source: {self.yaml_file}")
        lines.append(f"#")
        lines.append(f"# Usage with VCS: vcs -f csr_files.f")
        lines.append(f"# Usage with Xcelium: xrun -f csr_files.f")
        lines.append(f"")
        
        # Add packages first
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"{module_name}/{module_name}_csr_pkg.sv")
        
        lines.append(f"")
        lines.append(f"# RTL modules")
        
        # Add RTL modules
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"{module_name}/{module_name}_csr.sv")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_tcl_filelist(self, output_file, output_path):
        """Generate TCL source script for Vivado/Quartus"""
        lines = []
        lines.append(f"# CSR SystemVerilog TCL Source Script")
        lines.append(f"# Generated: {self.timestamp}")
        lines.append(f"# Source: {self.yaml_file}")
        lines.append(f"#")
        lines.append(f"# Usage in Vivado: source csr_files.tcl")
        lines.append(f"# Usage in Quartus: source csr_files.tcl")
        lines.append(f"")
        lines.append(f"# Get the directory of this script")
        lines.append(f"set csr_dir [file dirname [info script]]")
        lines.append(f"")
        lines.append(f"# Add CSR package files")
        
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"read_verilog -sv ${{csr_dir}}/{module_name}/{module_name}_csr_pkg.sv")
        
        lines.append(f"")
        lines.append(f"# Add CSR RTL files")
        
        for module in self.modules:
            module_name = module['name'].lower()
            lines.append(f"read_verilog -sv ${{csr_dir}}/{module_name}/{module_name}_csr.sv")
        
        lines.append(f"")
        lines.append(f"puts \"CSR files loaded successfully\"")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))
    
    def generate_documentation(self, output_file):
        """Generate Markdown documentation for register map"""
        lines = []
        lines.append(f"# Register Map Documentation")
        lines.append(f"## DSP-4CH-100M")
        lines.append("")
        lines.append(f"**Generated:** {self.timestamp}  ")
        lines.append(f"**Source:** {self.yaml_file}")
        lines.append("")
        
        # Table of contents
        lines.append(f"## Table of Contents")
        lines.append("")
        for module in self.modules:
            module_name = module['name']
            lines.append(f"- [{module_name}](#{module_name.lower()})")
        lines.append("")
        
        # Module details
        for module in self.modules:
            module_name = module['name']
            MODULE_NAME = module_name.upper()
            
            lines.append(f"## {module_name}")
            lines.append("")
            lines.append(f"**Description:** {module['description']}  ")
            lines.append(f"**Base Address:** `{module['base_address']}`")
            lines.append("")
            
            # Register table
            lines.append(f"| Offset | Register | Access | Reset | Description |")
            lines.append(f"|--------|----------|--------|-------|-------------|")
            
            for reg in module['registers']:
                lines.append(f"| {reg['offset']} | {reg['name']} | {reg['access']} | {reg['reset']} | {reg['description']} |")
            
            lines.append("")
            
            # Register details
            for reg in module['registers']:
                lines.append(f"### {reg['name']}")
                lines.append("")
                lines.append(f"**Offset:** {reg['offset']}  ")
                lines.append(f"**Access:** {reg['access']}  ")
                lines.append(f"**Reset Value:** {reg['reset']}  ")
                lines.append(f"**Description:** {reg['description']}")
                lines.append("")
                
                # Field table
                lines.append(f"| Bits | Field | Description |")
                lines.append(f"|------|-------|-------------|")
                
                for field in reg['fields']:
                    bits = field['bits']
                    if isinstance(bits, list):
                        if len(bits) == 2:
                            bit_str = f"[{bits[0]}:{bits[1]}]"
                        else:
                            bit_str = f"[{bits[0]}]"
                    else:
                        bit_str = f"[{bits}]"
                    
                    lines.append(f"| {bit_str} | {field['name']} | {field['description']} |")
                
                lines.append("")
        
        with open(output_file, 'w') as f:
            f.write('\n'.join(lines))


def main():
    """Main entry point"""
    if len(sys.argv) < 3:
        print(f"CSR Generator")
        print(f"="*60)
        print(f"Usage: python gen_csr.py <yaml_file> <output_directory>")
        print(f"")
        print(f"Arguments:")
        print(f"  yaml_file        - Path to YAML CSR definition file")
        print(f"  output_directory - Directory where generated files will be created")
        print(f"")
        print(f"Example:")
        print(f"  python gen_csr.py my_project/csr_defs.yaml my_project/csr_gen")
        print(f"")
        print(f"See evm/csr_gen/example/ for an example YAML file")
        return 1
    
    yaml_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    print(f"CSR Generator")
    print(f"="*60)
    print(f"Input: {yaml_file}")
    print(f"Output Directory: {output_dir}")
    print("")
    
    try:
        gen = CSRGenerator(yaml_file)
        gen.generate_all(output_dir)
        print("")
        print(f"Successfully generated all files!")
        return 0
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
