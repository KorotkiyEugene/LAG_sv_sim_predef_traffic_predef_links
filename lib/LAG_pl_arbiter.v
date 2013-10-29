/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * -------------------------------------------------------------------------------
 * 
 * Physical-channel allocation arbiter
 * 
 * This PL arbiter simply consists of one arbiter per output-port.
 * Each arbiter has np*nv inputs. 
 * 
 */

module LAG_pl_arbiter (request,
		      req_priority, 
		      grant, 
		      pl_allocated, 
		      clk, rst_n);

   parameter np=5;
   parameter nv=4;
   parameter multistage=2;
   parameter dynamic_priority_pl_alloc=0;

   parameter type flit_priority_t = flit_pri_t;
   
   input [np-1:0][nv-1:0][np-1:0] request;
   input flit_priority_t req_priority [np-1:0][nv-1:0]; 
   output [np-1:0][nv-1:0][np-1:0] grant;
   // was PL allocated? previous grant was successful! use new arb. state (make sure things are fair)
   input [np-1:0] 	   pl_allocated;
   input clk, rst_n;

   // inputs and outputs to matrix arbiters
   wire [np*nv-1:0] output_req [np-1:0];
   wire [np*nv-1:0] output_grant [np-1:0];

   genvar ip, pl, op;

   generate
   for (ip=0; ip<np; ip=ip+1) begin:i
      for (pl=0; pl<nv; pl=pl+1) begin:v
	 for (op=0; op<np; op=op+1) begin:o
	    // generate inputs to arbiters
	    assign output_req[op][ip*nv+pl] = (LAG_route_valid_turn(ip, op)) ? request[ip][pl][op] : 1'b0;

	    // put output signals in correct order
	    assign grant[ip][pl][op]=output_grant[op][ip*nv+pl];
	 end
      end
   end
  
   // 
   // np x np*nv-input matrix arbiters
   //
   for (op=0; op<np; op=op+1) begin:o2

      LAG_tree_arbiter #(.multistage(multistage),
			.size(np*nv),
			.groupsize(nv),
			.priority_support(dynamic_priority_pl_alloc),
			.priority_type(flit_priority_t)) plarb
	(.request(output_req[op]),
	 .req_priority(req_priority),
	 .grant(output_grant[op]),
	 .success(pl_allocated[op]),// be careful
	 .clk, .rst_n);

   end

   endgenerate
   
endmodule // precomp_pl_alloc

 
