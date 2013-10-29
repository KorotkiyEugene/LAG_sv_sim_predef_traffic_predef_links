/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK. 
 *
 *  (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 * -------------------------------------------------------------------------------
 *
 * pl_input_port
 * 
 * - Buffers incoming flits and updates PL ID field with PL allocated for 
 *   packet at current router.
 * 
 * - Determine which port is needed at next router (route packet)
 * 
 * pipelined_pl_switch_alloc = 0 | 1
 * =================================
 * 
 *   Do we need to consider PLs allocated on this cycle when returning
 *   currently allocated PL id.?
 *   If PL/switch allocation is pipelined, current PL will always be 
 *   read from the 'pl_reg' register.
 * 
 */

module LAG_pl_input_port(push, pop, data_in, data_out, flags, 
			// currently allocated PLs and valid bits
			allocated_pl, allocated_pl_valid,
			// incoming newly granted/allocated PLs and valid bits
			pl_new, pl_new_valid, 
			clk, rst_n);

   // number of physical channels
   parameter num_pls = 4;
   parameter max_links_num = 2;
   
   // length of each physical channel buffer
   parameter buffer_length = 8;

   input  clk, rst_n;
   input  [num_pls-1:0] push;
   input  [num_pls-1:0] pop;
   input  flit_t data_in [num_pls-1:0];
   output flit_t data_out [num_pls-1:0];
   output fifov_flags_t flags [num_pls-1:0];
   output [num_pls-1:0][max_links_num-1:0] allocated_pl;
   output [num_pls-1:0] allocated_pl_valid;
	 
   input [num_pls-1:0][max_links_num-1:0] pl_new;
   input [num_pls-1:0] 	pl_new_valid;

   logic [num_pls-1:0][max_links_num-1:0] pl_reg;
   logic [num_pls-1:0] allocated_pl_valid;

   flit_t buffer_data_out [num_pls-1:0];
   flit_t routed [num_pls-1:0];

   logic sel_allocated_pl_valid;
   logic [num_pls-1:0] sel_pl_reg, sel_pl_new;
   
   integer i;
   genvar pl;

   
   //
   // physical-channel buffers
   //

   LAG_pl_buffers #(.size(buffer_length),
		   .n(num_pls)) pl_bufsi
     (.push(push), .pop(pop), .data_in(data_in),
      .data_out(buffer_data_out), 
      .flags(flags), .clk, .rst_n);

   generate
   for (pl=0; pl<num_pls; pl++) begin:eachpl
    
	   //
	   // if PL and switch allocation are pipelined, 
	   // current PL is always read from register.
	   //
	   assign allocated_pl[pl] = pl_reg[pl];
	   assign data_out[pl] = buffer_data_out[pl];
	  
   end
   endgenerate

   always@(posedge clk) begin
      if (!rst_n) begin
	 for (i=0; i<num_pls; i++) begin
	    // No allocated PLs on reset
	    allocated_pl_valid[i]<=1'b0;
	    pl_reg[i]<='0;
	 end
      end else begin
	 
   //
	 // if we have sent the last flit (tail) we don't hold a PL anymore
	 //
	 
	 for (i=0; i<num_pls; i++) begin

	    if (buffer_data_out[i].control.tail && pop[i]) begin
	       //
	       // tail has gone, no longer hold a valid PL
	       //
	       allocated_pl_valid[i]<=1'b0;
	       pl_reg[i]<='0;
	    end else begin

	       // [may obtain, use and release PL in one cycle (single flit packets), if so
	       // allocated_pl_valid[] is never set
	       
	       if (pl_new_valid[i]) begin
		  //
		  // receive new PL
		  //
//		  $display ("%m: new PL (%b) written to reg. at input PL buffer %1d", pl_new[i], i);
		  allocated_pl_valid[i]<=1'b1;
		  
      if(pl_new[i] === 'x) $finish;
      
      pl_reg[i]<=pl_new[i];

		  assert (pl_new[i]!='0) else begin
		     $display ("New PL id. is blank?"); $fatal;
		  end
	       end
	    end
	 end
      end // else: !if(!rst_n)
   end // always@ (posedge clk)

endmodule // pl_input_port
