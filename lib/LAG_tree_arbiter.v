
/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * 
 *(C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"  
 * -------------------------------------------------------------------------------
 *
 * Tree Matrix Arbiter
 * 
 * - 'multistage' parameter - see description in matrix_arbiter.v
 * 
 * The tree arbiter splits the request vector into groups, performing arbitration
 * simultaneously within groups and between groups. Note this has implications 
 * for fairness.
 * 
 * Only builds one level of a tree
 * 
 */                                                   

module LAG_tree_arbiter (request, grant, success, clk, rst_n);

   parameter multistage=0;
   
   parameter max_groupsize=4;

   parameter numgroups = 5;
   
   parameter integer links[numgroups][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };

   parameter priority_support = 0;
  
   input [numgroups*max_groupsize-1:0] request;
  

   output [numgroups*max_groupsize-1:0] grant;
   input 	     success;

   input 	     clk, rst_n;

   logic [numgroups*max_groupsize-1:0] intra_group_grant;
   logic [numgroups-1:0] group_grant, any_group_request;
   logic [numgroups-1:0] current_group_success, last_group_success;
   logic [numgroups-1:0] group_success;

   
   genvar i;

   generate

   for (i=0; i<numgroups; i=i+1) begin:arbiters

      if (multistage==0) begin
	 //
	 // group_arbs need to be multistage=1, as group may not get granted
	 //
	 matrix_arb #(.size(links[i][IN]),
		      .multistage(1)) arb
	   (.request(request[i*max_groupsize+links[i][IN]-1:i*max_groupsize]),
	    .grant(intra_group_grant[i*max_groupsize+links[i][IN]-1:i*max_groupsize]),
	    .success(group_success[i]), 
	    .clk, .rst_n);
	 
      end else begin
      
	 matrix_arb #(.size(links[i][IN]),
		      .multistage(multistage)) arb
	   (.request(request[i*max_groupsize+links[i][IN]-1:i*max_groupsize]),
	    .grant(intra_group_grant[i*max_groupsize+links[i][IN]-1:i*max_groupsize]),
	    .success(group_success[i] & success),
//	    .success('1), 
	    .clk, .rst_n);
      end
			   
      assign any_group_request[i] = |request[i*max_groupsize+links[i][IN]-1:i*max_groupsize];

      assign grant[(i+1)*max_groupsize-1:i*max_groupsize]=
      	     intra_group_grant[(i+1)*max_groupsize-1:i*max_groupsize] & {max_groupsize{group_grant[i]}};

      //.success(any_group_request[i] & group_grant[i] & success), 
      //assign current_group_success[i]=|grant[(i+1)*groupsize-1:i*groupsize];

      assign current_group_success[i]= group_grant[i];
      
   end
   
   if (multistage==2) begin
      always@(posedge clk) begin
	 if (!rst_n) begin
	    last_group_success<='0;
	 end else begin
	    last_group_success<=current_group_success;
	 end
      end

      assign group_success=last_group_success;
   
   end else begin
      assign group_success=current_group_success;
   end
   
   endgenerate
   
   matrix_arb #(.size(numgroups),
		.multistage(multistage)
    ) group_arb 
     (.request(any_group_request),
      .grant(group_grant),
      .success(success),
      .clk, .rst_n);

endmodule // tree_arbiter

