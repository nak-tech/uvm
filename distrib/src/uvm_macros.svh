//
//----------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2010-2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
// 
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

`ifndef UVM_MACROS_SVH
`define UVM_MACROS_SVH


// Default settings
//`define UVM_USE_FILE_LINE
`define UVM_DA_TO_QUEUE(Q,DA) Q=DA;
`define uvm_delay(TIME) #(TIME);
`define uvm_typename(X) $typename(X)
//
// Any vendor specific defines go here.
//
`ifdef VCS
`endif


`ifdef MODEL_TECH
`ifndef QUESTA
`define QUESTA
`endif
`endif

`ifdef QUESTA
`define uvm_typename(X) $typename(X,39)
`endif

`ifdef INCA
  `define UVM_USE_PROCESS_CONTAINER
  `undef  UVM_DA_TO_QUEUE
  `define UVM_DA_TO_QUEUE(Q,DA)  foreach (DA[idx]) Q.push_back(DA[idx]);
`endif

//
// Deprecation Control Macros
//
`ifdef UVM_NO_DEPRECATED
  `define UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
`endif


`include "macros/uvm_version_defines.svh"
`include "macros/uvm_message_defines.svh"
`include "macros/uvm_phase_defines.svh"
`include "macros/uvm_object_defines.svh"
`include "macros/uvm_printer_defines.svh"
`include "macros/uvm_tlm_defines.svh"
`include "macros/uvm_sequence_defines.svh"
`include "macros/uvm_callback_defines.svh"
`include "macros/uvm_reg_defines.svh"
`include "macros/uvm_deprecated_defines.svh"

`endif
