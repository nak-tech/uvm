// 
// -------------------------------------------------------------
//    Copyright 2004-2008 Synopsys, Inc.
//    Copyright 2010 Mentor Graphics Corp.
//    All Rights Reserved Worldwide
// 
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
// 

//
// TITLE: Memory Access Test Sequence
//

//
// class: uvm_mem_single_access_seq
//
// Verify the accessibility of a memory
// by writing through its default address map
// then reading it via the backdoor, then reversing the process,
// making sure that the resulting value matches the written value.
//
// Memories without an available backdoor
// cannot be tested.
//
// The DUT should be idle and not modify the memory during this test.
//

class uvm_mem_single_access_seq extends uvm_reg_sequence #(uvm_sequence #(uvm_sequence_item));

   // variable: mem
   // The memory to be tested
   uvm_mem mem;

   `uvm_object_utils(uvm_mem_single_access_seq)

   function new(string name="uam_mem_single_access_seq");
     super.new(name);
   endfunction

   virtual task body();
      string mode;
      uvm_reg_mem_map maps[$];
      int n_bits;

      if (mem == null) begin
         `uvm_error("RegMem", "No register specified to run sequence on");
         return;
      end

      // Can only deal with memories with backdoor access
      if (mem.get_backdoor() == null &&
          !mem.has_hdl_path()) begin
         `uvm_error("RegMem", $psprintf("Memory \"%s\" does not have a backdoor mechanism available",
                                     mem.get_full_name()));
         return;
      end

      n_bits = mem.get_n_bits();
      
      `uvm_info("RegMem",$psprintf("***** n_bits =%0d",n_bits),UVM_DEBUG)
      
      // Memories may be accessible from multiple physical interfaces (maps)
      mem.get_maps(maps);

      // Walk the memory via each map
      foreach (maps[j]) begin
         uvm_status_e status;
         uvm_reg_mem_data_t  val, exp, v;
         
         `uvm_info("RegMem", $psprintf("Accessing memory %s in map \"%s\"...",
                                    mem.get_full_name(), maps[j].get_full_name()), UVM_LOW);
         
         mode = mem.get_access(maps[j]);
         
         // The access process is, for address k:
         // - Write random value via front door
         // - Read via backdoor and expect same random value if RW
         // - Write complement of random value via back door
         // - Read via front door and expect inverted random value
         for (int k = 0; k < mem.get_size(); k++) begin
            val = $random & uvm_reg_mem_data_t'((1'b1<<n_bits)-1);
            if (n_bits > 32)
              val = uvm_reg_mem_data_t'(val << 32) | $random;
            if (mode == "RO") begin
               mem.peek(status, k, exp);
               if (status != UVM_IS_OK) begin
                  `uvm_error("RegMem", $psprintf("Status was %s when reading \"%s[%0d]\" through backdoor.",
                                              status.name(), mem.get_full_name(), k));
               end
            end
            else exp = val;
            
            mem.write(status, k, val, UVM_BFM, maps[j], this);
            if (status != UVM_IS_OK) begin
               `uvm_error("RegMem", $psprintf("Status was %s when writing \"%s[%0d]\" through map \"%s\".",
                                           status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
            end
            #1;
            
            val = 'x;
            mem.peek(status, k, val);
            if (status != UVM_IS_OK) begin
               `uvm_error("RegMem", $psprintf("Status was %s when reading \"%s[%0d]\" through backdoor.",
                                           status.name(), mem.get_full_name(), k));
            end
            else begin
               if (val !== exp) begin
                  `uvm_error("RegMem", $psprintf("Backdoor \"%s[%0d]\" read back as 'h%h instead of 'h%h.",
                                              mem.get_full_name(), k, val, exp));
               end
            end
            
            exp = ~exp & ((1'b1<<n_bits)-1);
            mem.poke(status, k, exp);
            if (status != UVM_IS_OK) begin
               `uvm_error("RegMem", $psprintf("Status was %s when writing \"%s[%0d-1]\" through backdoor.",
                                           status.name(), mem.get_full_name(), k));
            end
            
            mem.read(status, k, val, UVM_BFM, maps[j], this);
            if (status != UVM_IS_OK) begin
               `uvm_error("RegMem", $psprintf("Status was %s when reading \"%s[%0d]\" through map \"%s\".",
                                           status.name(), mem.get_full_name(), k, maps[j].get_full_name()));
            end
            else begin
               if (mode == "WO") begin
                  if (val !== '0) begin
                     `uvm_error("RegMem", $psprintf("Front door \"%s[%0d]\" read back as 'h%h instead of 'h%h.",
                                                 mem.get_full_name(), k, val, 0));
                  end
               end
               else begin
                  if (val !== exp) begin
                     `uvm_error("RegMem", $psprintf("Front door \"%s[%0d]\" read back as 'h%h instead of 'h%h.",
                                                 mem.get_full_name(), k, val, exp));
                  end
               end
            end
         end
      end
   endtask: body
endclass: uvm_mem_single_access_seq




//
// class: uvm_mem_access_seq
//
// Verify the accessibility of all memories in a block
// by executing the <uvm_mem_single_access_seq> sequence on
// every memory within it.
//
// Blocks and memories with the NO_REG_TESTS or
// the NO_MEM_ACCESS_TEST attribute are not verified.
//

class uvm_mem_access_seq extends uvm_reg_sequence;

   `uvm_object_utils(uvm_mem_access_seq)

   function new(string name="uvm__mem_access_seq");
     super.new(name);
   endfunction

   // variable: regmem
   // The block to be tested
   
   virtual task body();

      if (regmem == null) begin
         `uvm_error("RegMem", "Not block or system specified to run sequence on");
         return;
      end

      uvm_report_info("STARTING_SEQ",{"\n\nStarting ",get_name()," sequence...\n"},UVM_LOW);
      
      if (regmem.get_attribute("NO_REG_TESTS") == "") begin
        if (regmem.get_attribute("NO_MEM_ACCESS_TEST") == "") begin
           uvm_mem mems[$];
           uvm_mem_single_access_seq mem_seq = new("single_mem_access_seq");
           this.reset_blk(regmem);
           regmem.reset();

           // Iterate over all memories, checking accesses
           regmem.get_memories(mems);
           foreach (mems[i]) begin
              // Registers with some attributes are not to be tested
              if (mems[i].get_attribute("NO_REG_TESTS") != "" ||
	          mems[i].get_attribute("NO_MEM_ACCESS_TEST") != "") continue;

              // Can only deal with memories with backdoor access
              if (mems[i].get_backdoor() == null &&
                  !mems[i].has_hdl_path()) begin
                 `uvm_warning("RegMem", $psprintf("Memory \"%s\" does not have a backdoor mechanism available",
                                               mems[i].get_full_name()));
                 continue;
              end

              mem_seq.mem = mems[i];
              mem_seq.start(null, this);
           end
        end
      end

   endtask: body


   //
   // task: reset_blk
   // Reset the DUT that corresponds to the specified block abstraction class.
   //
   // Currently empty.
   // Will rollback the environment's phase to the ~reset~
   // phase once the new phasing is available.
   //
   // In the meantime, the DUT should be reset before executing this
   // test sequence or this method should be implemented
   // in an extension to reset the DUT.
   //
   virtual task reset_blk(uvm_reg_mem_block blk);
   endtask


endclass: uvm_mem_access_seq


