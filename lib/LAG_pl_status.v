/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * 
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"  
 * -------------------------------------------------------------------------------
 * 
 * Logic to determine if the physical-channel held by a particular packet 
 * (buffered in an input PL FIFO) is blocked or ready?
 * 
 * Looks at currently allocated PL or the next free PL that would be allocated
 * at this port (as PL allocation may be taking place concurrently).
 * 
 */

module LAG_pl_status (output_port, 
		     allocated_pl,
		     allocated_pl_valid,
		     pl_status,
		     pl_blocked);

   parameter np = 5;
   parameter integer links[np][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };
   parameter ln_num = 2; //ln_num = maximum number of links per trunk
   
   input output_port_t output_port [np-1:0][ln_num-1:0]; 
   input [np-1:0][ln_num-1:0][ln_num-1:0] allocated_pl; // allocated PL ID
   input [np-1:0][ln_num-1:0] allocated_pl_valid; // holding allocated PL?
   input [np-1:0][ln_num-1:0] pl_status; // blocked/ready status for each output PL
   output [np-1:0][ln_num-1:0] pl_blocked;
   
   logic [np-1:0][ln_num-1:0] b, current_pl_blocked;

   
   genvar ip,pl,op;
   
   generate
      for (ip=0; ip<np; ip++) begin:il
	 for (pl=0; pl<links[ip][IN]; pl++) begin:vl

	    //assign current_pl[ip][pl] = (allocated_pl_valid[ip][pl]) ? allocated_pl[ip][pl] : pl_requested[ip][pl];
	    	    
	    unary_select_pair #(.input_port(ip), .WA(np), .WB(ln_num), .links(links)) blocked_mux
	      (output_port[ip][pl],
	       allocated_pl[ip][pl],
	       pl_status,
	       current_pl_blocked[ip][pl]);
	    
	    assign b[ip][pl] = current_pl_blocked[ip][pl];

	    assign pl_blocked[ip][pl] = (LAG_route_valid_input_pl (ip,pl)) ? b[ip][pl] : 1'b0;
	 end
      end 
      
   endgenerate
   
   
endmodule // LAG_pl_status
