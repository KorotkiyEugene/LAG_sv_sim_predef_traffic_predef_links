
/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 *
 * FIFO
 * ====
 *
 * Implementation notes:
 *  
 * - Read and write pointers are simple ring counters
 * 
 * - Number of items held in FIFO is recorded in shift register
 *      (Full/empty flags are most and least-significant bits of register)
 * 
 * - Supports input and/or output registers on FIFO
 * 
 * Examples:
 * 
 *   fifo_v #(.fifo_elements_t(int), .size(8)) myfifo (.*);
 * 
 * Instantiates a FIFO that can hold up to 8 integers.
 * 
 *   fifo_v #(.fifo_elements_t(int), .size(8), .output_reg(1)) myfifo (.*);
 * 
 * Instantiates a FIFO that can hold up to 8 integers with output register
 * 
 * Output Register
 * ===============
 * 
 * Instantiate a FIFO of length (size-1) + an output register and bypass logic
 *  
 *   output_reg = 0 (default) - no output register
 *   output_reg = 1 - instantiate a single output register
 * 
 *                      _
 *      ______    |\   | |
 *  _|-[_FIFO_]-->| |__| |__ Out
 *   |----------->| |  |_|
 *      bypass    |/   Reg.
 *
 * 
 * Input Register
 * ==============
 * 
 *   input_reg = 0 (default) - no input register, FIFO receives data directly
 *   input_reg = 1 - assume **external** input register and bypass logic 
 *   input_reg = 2 - instantiate input register and bypass logic 
 * 
 * In case 1. the FIFO is still of length 'size' as it is assumed the external
 * input register is always enabled (used when building VC buffers).
 * 
 *   _      ______    |\
 *  | |  |-[_FIFO_]-->| |___ Out
 *  | |__|___________>| |
 *  |_|               |/
 *  Reg.
 * 
 * Input and Output Registers
 * ==========================
 * 
 * Can set input_reg=2, output_reg=1 to create FIFO with both input and output
 * registers. FIFO behaviour remains identical at the cycle-level with the 
 * addition of input/output registers.
 * 
 * InReg            OutReg
 *   _     ______     _ 
 *  | |---[_FIFO_]---| |
 *  | | |____________| |___|\
 *  |_| |            |_|   | |__ Out
 *      |__________________| |
 *                         |/
 * FIFO Initialisation
 * ===================
 * 
 *   init_fifo_contents = 0    - FIFO is empty on reset
 *   init_fifo_contents = 1    - FIFO is nearly_full on reset (mem[i]=1'b1<<i, mem[size]=0)
 *   init_fifo_contents = 2    - FIFO is nearly empty on reset (mem[0]=1)
 * 
 * 
 * ===============================================================================      
 */ 

// other FIFO types: double buffered, two slower FIFOs + output register
//                   FIFOs with second entry outputs (as required by router)
//                   pending write input register
//
// - second output with output registers [two output registers?]
//

//`ifdef VCS
//import fifo_package::*;
//`endif
 
/************************************************************************************
 *
 * FIFO 
 *
 ************************************************************************************/
  
module LAG_fifo_v (push, pop, data_in, data_out, flags, clk, rst_n);
   
   // max no. of entries
   parameter size = 8;
   
   input     push, pop;
   output    fifov_flags_t flags;
   input     fifo_elements_t data_in;
   output    fifo_elements_t data_out;
   input     clk, rst_n;
   
   logic fifo_push, fifo_pop;
   fifo_elements_t fifo_data_out, data_out_tmp;

   fifo_buffer #(.size(size))
         fifo_buf (push, pop, data_in, data_out_tmp, clk, rst_n);

    assign data_out = flags.empty ? '0 : data_out_tmp; 
      
    fifo_flags #(.size(size)) 
      gen_flags(push, pop, flags, clk, rst_n); 

endmodule // fifo_v


/************************************************************************************
 *
 * Maintain FIFO flags (full, nearly_full, nearly_empty and empty)
 * 
 * This design uses a shift register to ensure flags are available quickly.
 * 
 ************************************************************************************/

module fifo_flags (push, pop, flags, clk, rst_n);
   input push, pop;
   output fifov_flags_t flags;
   input clk, rst_n;
   
   parameter size = 8;

   reg [size:0]   counter;      // counter must hold 1..size + empty state

   logic 	  was_push, was_pop;

   fifov_flags_t flags_reg;
   logic 	  add, sub, same;
   
   /*
    * maintain flags
    *
    *
    * maintain shift register as counter to determine if FIFO is full or empty
    * full=counter[size-1], empty=counter[0], etc..
    * init: counter=1'b1;
    *   (push & !pop): shift left
    *   (pop & !push): shift right
    */

   always@(posedge clk) begin
      if (!rst_n) begin
	     counter<={{size{1'b0}},1'b1};
	     was_push<=1'b0;
	     was_pop<=1'b0;	 
      end else begin
 	 if (add) begin
	    assert (counter!={1'b1,{size{1'b0}}}) else $fatal;
	    counter <= {counter[size-1:0], 1'b0};
	 end else if (sub) begin
	    assert (counter!={{size{1'b0}},1'b1}) else $fatal;
	    counter <= {1'b0, counter[size:1]};
	 end
	 
	 assert (counter!=0) else $fatal;

	 was_push<=push;
	 was_pop<=pop;

	 assert (push!==1'bx) else $fatal;
	 assert (pop!==1'bx) else $fatal;

      end // else: !if(!rst_n)
      
   end

   assign add = was_push && !was_pop;
   assign sub = was_pop && !was_push;
   assign same = !(add || sub);
   
   assign flags.full = (counter[size] && !sub) || (counter[size-1] && add);
   assign flags.empty = (counter[0] && !add) || (counter[1] && sub);

   assign flags.nearly_full = (counter[size-1] && same) || (counter[size] && sub) || (counter[size-2] && add);
   assign flags.nearly_empty = (counter[1] && same) || (counter[0] && add) || (counter[2] && sub);
    

endmodule // fifo_flags

/************************************************************************************
 *
 * Simple core FIFO module
 * 
 ************************************************************************************/

module fifo_buffer (push, pop, data_in, data_out, clk, rst_n);

   // max no. of entries
   parameter int unsigned size = 4;

   input     push, pop;
   input     fifo_elements_t data_in;
   output    fifo_elements_t data_out;
   input     clk, rst_n;

//   reg [size-1:0] rd_ptr, wt_ptr;
   logic unsigned [size-1:0] rd_ptr, wt_ptr;
   
   fifo_elements_t fifo_mem[0:size-1];

   logic select_bypass;       
   
   integer i,j;

   always@(posedge clk) begin

      assert (size>=2) else $fatal();

      if (!rst_n) begin     

        rd_ptr<={{size-1{1'b0}},1'b1};
        wt_ptr<={{size-1{1'b0}},1'b1};
	 
      end else begin

	 if (push) begin
	    // enqueue new data
	    for (i=0; i<size; i++) begin
	       if (wt_ptr[i]==1'b1) begin
		  fifo_mem[i] <= data_in;
	       end
	    end
	 end

	 if (push) begin
	    // rotate write pointer
	    wt_ptr <= {wt_ptr[size-2:0], wt_ptr[size-1]};
	 end
	 
	 if (pop) begin
	    // rotate read pointer
            rd_ptr <= {rd_ptr[size-2:0], rd_ptr[size-1]};	    
	 end
	 
      end // else: !if(!rst_n)
   end // always@ (posedge clk)

   /*
    *
    * FIFO output is item pointed to by read pointer 
    * 
    */
   always_comb begin
      //
      // one bit of read pointer is always set, ensure synthesis tool 
      // doesn't add logic to force a default
      //
      data_out = 'x;  
      
      for (j=0; j<size; j++) begin
	 if (rd_ptr[j]==1'b1) begin

	    // output entry pointed to by read pointer
	    data_out = fifo_mem[j];

	 end
      end 

   end

endmodule // fifo_buffer
