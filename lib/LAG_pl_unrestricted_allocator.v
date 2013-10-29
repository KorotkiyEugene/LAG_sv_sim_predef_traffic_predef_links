/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * 
 *   
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 * -------------------------------------------------------------------------------
 *
 *
 *  Physical cgannel (PC) allocator 
 * Allocates new physical-channels in the destination trunk 
 * for newly arrived packets.
 * 
 * "unrestricted" allocation (Peh/Dally style)
 * 
 * Takes place in two stages:
 * 
 *           stage 1. ** Physical channel selection **
 *                    Each waiting packet determines which PC it will request.
 *                    (v:1 arbitration). 
 *                    
 * 
 *           stage 2. ** PC Allocation **
 *                    Access to each output PC is arbitrated (PV x PV:1 arbiters)
 * 
 */

module LAG_pl_unrestricted_allocator (req,              // PC request
				     output_port,      // for which trunk?
				     pl_status,        // which PCs are free
				     pl_new,           // newly allocated PC id.
				     pl_new_valid,     // has new PC been allocated?
				     pl_allocated,     // change PC status from free to allocated?
				     clk, rst_n);
   
   parameter buf_len = 4;
		
   parameter xs=4;
   parameter ys=4;
	
   parameter np=5;
   parameter max_links_num = 2;
   parameter integer links[np][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };

   // some packets can make higher priority requests for PLs
   // ** NOT YET IMPLEMENTED **
   parameter dynamic_priority_pl_alloc = 0;

   //
   // selection policies
   //
   parameter plselect_bydestinationnode = 0;
   parameter plselect_leastfullbuffer = 0;
   parameter plselect_arbstateupdate = 0;    // always/never update state of PL select matrix arbiter
   parameter plselect_usepacketmask = 0;     // packet determines which PLs may be requested (not with bydestinationnode!)
   
   parameter alloc_stages = 1;
   
//-----   
   input [np-1:0][max_links_num-1:0] req;
   input output_port_t output_port [np-1:0][max_links_num-1:0];
   input [np-1:0][max_links_num-1:0] pl_status;
   output logic [np-1:0][max_links_num-1:0][max_links_num-1:0] pl_new;
   output [np-1:0][max_links_num-1:0] pl_new_valid;   
   output logic [np-1:0][max_links_num-1:0] pl_allocated;  
   input clk, rst_n;

   integer i,j,k,l; 
   
   genvar a, b, c, d;

   logic [np-1:0][max_links_num-1:0][max_links_num-1:0] stage1_request, stage1_grant, stage1_grant_reg;
   logic [np-1:0][max_links_num-1:0][max_links_num-1:0] selected_status;
   logic [np-1:0][max_links_num-1:0][np-1:0][max_links_num-1:0] stage2_requests, stage2_requests_, stage2_grants;
   logic [np-1:0][max_links_num-1:0][max_links_num-1:0][np-1:0] pl_new_;
   
   output_port_t output_port_reg [np-1:0][max_links_num-1:0];
   
   generate
      for (a=0; a<np; a++) begin:foriports
	 for (b=0; b<links[a][IN]; b++) begin:forpls
       
      //
	    // first-stage of arbitration
	    //
	    // Arbiter state doesn't mean much here as requests on different clock cycles may be associated
	    // with different output ports. plselect_arbstateupdate determines if state is always or never
	    // updated.
	    //
	    //This stage determines one of free physical channel in te destination trunk
      //for each input physical channel that form request
      
	    matrix_arb #(.size(max_links_num), .multistage(1))
			 stage1arb
			 (.request(stage1_request[a][b]),
			  .grant(stage1_grant[a][b]),
			  .success(1'b1), 
			  .clk, .rst_n);
               
	    
      assign pl_new_valid[a][b]=|pl_new[a][b];
	   
   end
      end
      
   for (c=0; c<np; c++) begin: for_out_ports
	   for (d=0; d<links[c][OUT]; d++) begin: for_out_pls

      
      //Second stage of arbitration. Eaxh output PC has one np*nv:1 arbiter 
      // 
	    // np*nv np*nv:1 tree arbiters
	    //
	    
	    	    matrix_arb #(.size(max_links_num*np), .multistage(1))
			 stage2arb
			 (.request(stage2_requests[c][d]),
			  .grant(stage2_grants[c][d]),
			  .success(1'b1), 
			  .clk, .rst_n);
			  
      /*LAG_tree_arbiter #(.multistage(0),
                              .links(links),
                              .numgroups(np),
                              .max_groupsize(max_links_num),
                              .priority_support(dynamic_priority_pl_alloc)) plarb
              (.request(stage2_requests[c][d]),
               .grant(stage2_grants[c][d]),
               .clk, .rst_n);*/
     
     end
   end
      
   endgenerate 
   
   
   always_comb begin
   
   pl_new_ = '0;
   pl_new = '0;
   pl_allocated = '0;  
   selected_status = '0;
   stage1_request = '0; 
   stage2_requests = '0;
   
   if (alloc_stages == 2)
     stage2_requests_ = '0;
   
   for (i=0; i<np; i++) begin
	   for (j=0; j<links[i][IN]; j++) begin  
	   
	     if (alloc_stages == 2) begin
	     //	    
	     // Select PL status bits at output port of interest (determine which PLs are free to be allocated)
	     //
	     
       selected_status[i][j] = pl_status[oh2bin(output_port[i][j])];

	    //
	    // Requests for PL selection arbiter
	    //
	    // Narrows requests from all possible PLs that could be requested to 1
	    //
	    for (k=0; k<max_links_num; k++) begin
	       // Request is made if 
	       // (1) Packet requires PL
	       // (2) PL Mask bit is set
	       // (3) PL is currently free, so it can be allocated
	       //
	       stage1_request[i][j][k] = req[i][j] && selected_status[i][j][k] && ~(|stage1_grant_reg[i][j]);

	    end 
	    
	    //
	    // second-stage of arbitration, determines who gets PL
	    //
	    for (k=0; k<np; k++) begin
	       for (l=0; l<links[k][OUT]; l++) begin
		        stage2_requests[k][l][i][j] = stage1_grant_reg[i][j][l] && output_port_reg[i][j][k];
		        stage2_requests_[k][l][i][j] = stage1_grant[i][j][l] && output_port[i][j][k];
	       end
	    end
    

      end else if (alloc_stages == 1) begin
      
         selected_status[i][j] = pl_status[oh2bin(output_port[i][j])];
         
         for (k=0; k<max_links_num; k++) begin

	         stage1_request[i][j][k] = req[i][j] && selected_status[i][j][k];

	       end
	       
	       for (k=0; k<np; k++) begin
	         for (l=0; l<links[k][OUT]; l++) begin
		          
		         stage2_requests[k][l][i][j] = stage1_grant[i][j][l] && output_port[i][j][k];
              
	         end
	       end
      
      end else begin
         //$display("Error: parameter <alloc_stages> can obtain only (1) or (2) values!");
         //$finish;
      end
      
       for (k=0; k<np; k++) begin
	       for (l=0; l<links[k][OUT]; l++) begin
		       // could get pl x from any one of the output ports
		       pl_new_[i][j][l][k] = stage2_grants[k][l][i][j];
		       pl_new[i][j][l]=|pl_new_[i][j][l];
		       
		       if (alloc_stages == 1) begin
     
             pl_allocated[k][l] = |(stage2_requests[k][l]); 
         
           end else if (alloc_stages == 2) begin
      
             pl_allocated[k][l] = |(stage2_requests_[k][l]); 
        
           end
      
	       end
	    end
     end 
   end
   
   end  
   
endmodule // LAG_pl_unrestricted_allocator
