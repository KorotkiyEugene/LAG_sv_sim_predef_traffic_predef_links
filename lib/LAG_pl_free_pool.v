/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 *
 * FIFO-based PL Free Pool
 * ============-==========
 * 
 * Serves next free PL id. Tail flits sent on output link replenish free PL pool
 * 
 * One free PL pool per output port
 * 
 */

module LAG_pl_free_pool (flits_tail, flits_valid,
			// Unrestricted free pool
			pl_alloc_status,        // PL allocation status
			pl_allocated,           // which PLs were allocated on this cycle?
			pl_empty,               // is downstream FIFO associated with PL empty?
			clk, rst_n);

   parameter num_pls = 4;
   
   parameter fifo_free_pool = 0; // organise free pool as FIFO (offer at most one PL per output port per cycle)

   // only applicable if fifo_free_pool = 0
   parameter only_allocate_pl_when_empty = 0; // only allow a PL to be allocated when it is empty
   
//-------
   input [num_pls-1:0] flits_tail;
   input [num_pls-1:0] flits_valid;
   input [num_pls-1:0] pl_allocated;
   output [num_pls-1:0] pl_alloc_status;
   input [num_pls-1:0]  pl_empty;
   input  clk, rst_n;

   logic [num_pls-1:0] pl_alloc_status_reg;
   pl_t fifo_out;
   fifov_flags_t fifo_flags;
   logic push;

   integer i;
   
   generate
 
	 // =============================================================
	 // Unrestricted PL allocation
	 // =============================================================
	 always@(posedge clk) begin
	    if (!rst_n) begin
	       for (i=0; i<num_pls; i++) begin:forpls2
		  pl_alloc_status_reg[i] <= 1'b1;
	       end
	    end else begin
	       for (i=0; i<num_pls; i++) begin:forpls
		    //
		    // PL consumed, mark PL as allocated
		    //
		    if (pl_allocated[i]) 
            pl_alloc_status_reg[i]<=1'b0;
	       
	       /*if(flits_valid[i]) 
            $stop;
	       if(flits_tail[i]) 
            $stop;*/
	       
	       if (flits_valid[i] && flits_tail[i]) begin
		  //
		  // Tail flit departs, packets PL is ready to be used again
		  //

		  // what about single flit packets - test
		  assert (!pl_alloc_status_reg[i]);
		  
		  pl_alloc_status_reg[i]<=1'b1;
	       end
	    end //for
      end
	 end // always@ (posedge clk)

	 if (only_allocate_pl_when_empty) begin
	    assign pl_alloc_status = pl_alloc_status_reg & pl_empty;
	 end else begin
	    assign pl_alloc_status = pl_alloc_status_reg;
	 end
    
   endgenerate
   
endmodule // LAG_pl_free_pool

