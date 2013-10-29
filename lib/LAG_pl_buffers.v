/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 *
 * Physical-Channel Buffers
 * =======================
 * 
 * Instantiates 'N' FIFOs in parallel, if 'push' is asserted
 * data_in is sent to FIFO[pl_id].
 *
 * The output is determined by an external 'select' input.
 * 
 * if 'pop' is asserted by the end of the clock cycle, the 
 * FIFO that was read (indicated by 'select') recieves a 
 * pop command.
 *
 * - flags[] provides access to all FIFO status flags.
 * - output_port[] provides access to 'output_port' field of flits at head of FIFOs
 */

module LAG_pl_buffers (push, pop, data_in,
		      data_out, flags,
		      clk, rst_n);
      
   // length of PL FIFOs
   parameter size = 3;
   // number of physical channels
   parameter n = 4;
                       

   input     [n-1:0] push;
   input     [n-1:0] pop;
   input     fifo_elements_t data_in [n-1:0];

   output    fifo_elements_t data_out [n-1:0];
   output    fifov_flags_t flags [n-1:0];
   
   input     clk, rst_n;
   
   genvar i;
   
   generate
   for (i=0; i<n; i++) begin:plbufs

	 // **********************************
	 // SINGLE FIFO holds complete flit
	 // **********************************
	 LAG_fifo_v #(.size(size)
		     ) pl_fifo
	   (.push(push[i]), 
	    .pop(pop[i]), 
	    .data_in(data_in[i]), 
	    .data_out(data_out[i]),
	    .flags(flags[i]),
	    .clk, .rst_n);   
   end
   
   endgenerate

endmodule 
