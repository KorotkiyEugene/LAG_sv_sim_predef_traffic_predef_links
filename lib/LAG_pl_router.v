/* -------------------------------------------------------------------------------
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 * -------------------------------------------------------------------------------
 */ 

module LAG_pl_router (i_flit_in, i_flit_out,
		     i_cntrl_in, i_cntrl_out,
		     i_input_full_flag, 
		     clk, rst_n);
   
   parameter network_x = 4;
   parameter network_y = 4;
   
   parameter buf_len = 4;
   parameter NP=5;

   parameter integer links[NP][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };//'0;

   parameter alloc_stages = 1;

   // numbers of physical-channels on entry/exit to network?
   parameter router_num_pls_on_entry = 1;
   parameter router_num_pls_on_exit = 1;

   //
   // PL Allocation
   //
   parameter plalloc_unrestricted=0;

   //
   // PL Selection
   //
   parameter plselect_bydestinationnode = 0;
   parameter plselect_leastfullbuffer = 0;
   parameter plselect_arbstateupdate = 0;   
   parameter plselect_usepacketmask = 0;    
   parameter plselect_onlywhenempty = 0;
   
   //
   // Prioritised Communications
   //

   // prioritise switch allocation by position of flit in packet (head=0, tail=N)
   parameter priority_switch_alloc_byflitid=0;
   
   // prioritise switch allocation based on flit.control.flit_priority
   parameter priority_flit_dynamic_switch_alloc=0;
   // prioritise pl allocation based on flit.control.flit_priority
   parameter priority_flit_dynamic_pl_alloc=0;
   // size of flit.control.flit_priority field (in bits)
   parameter priority_flit_bits=4;
 
   parameter priority_network_traffic=0;
   parameter priority_flit_limit=4;
   parameter global_links_num = 2;
   
   localparam max_local_link_num = find_max_local_link_num(links);

   // synopsys translate_off
   integer blockings[NP][max_local_link_num];
   // synopsys translate_on

//==================================================================

   // FIFO rec. data from tile/core is full?
   output  [router_num_pls_on_entry-1:0] i_input_full_flag;
   // link data and control
   input   flit_t i_flit_in [NP-1:0][global_links_num-1:0];
   output  flit_t i_flit_out [NP-1:0][global_links_num-1:0];
   input   [global_links_num-1:0] i_cntrl_in [NP-1:0];
   output  [global_links_num-1:0] i_cntrl_out [NP-1:0];
   input   clk, rst_n;
       
   logic [NP-1:0][max_local_link_num-1:0] x_pl_status;
   
   logic [NP-1:0][max_local_link_num-1:0] x_push;
   logic [NP-1:0][max_local_link_num-1:0] x_pop;
   
   flit_t x_flit_xbarin [NP-1:0][max_local_link_num-1:0];
   flit_t x_flit_xbarout [NP-1:0][max_local_link_num-1:0];
   
   flit_t x_flit_xbarin_ [NP*max_local_link_num-1:0];
   flit_t x_flit_xbarout_ [NP*max_local_link_num-1:0];
   
   flit_t routed [NP-1:0][max_local_link_num-1:0];
   
   logic [NP-1:0][max_local_link_num-1:0] flits_out_tail; 
   logic [NP-1:0][max_local_link_num-1:0] flits_out_valid;    //for any output channel of each output port

   fifov_flags_t x_flags [NP-1:0][max_local_link_num-1:0];
   logic [NP-1:0][max_local_link_num-1:0][max_local_link_num-1:0] 	  x_allocated_pl;
   logic [NP-1:0][max_local_link_num-1:0] x_allocated_pl_valid;   
   logic [NP-1:0][max_local_link_num-1:0][max_local_link_num-1:0] x_pl_new;
   logic [NP-1:0][max_local_link_num-1:0] 	  x_pl_new_valid;
   output_port_t x_output_port [NP-1:0][max_local_link_num-1:0];
   output_port_t x_output_port_reg [NP-1:0][max_local_link_num-1:0];
  
   logic [NP*max_local_link_num-1:0][NP*max_local_link_num-1:0] xbar_select; 
   logic [NP-1:0][max_local_link_num-1:0] pl_request;             // PL request from each input PL
   
   logic [NP-1:0][max_local_link_num-1:0] allocated_pl_blocked;  
   
   flit_t flit_buffer_out [NP-1:0][max_local_link_num-1:0];
   
   //
   // unrestricted PL free pool/allocation
   //
   logic [NP-1:0][max_local_link_num-1:0] pl_alloc_status, pl_alloc_status_;         // which output PLs are free to be allocated
   logic [NP-1:0][max_local_link_num-1:0] pl_allocated;            // indicates which PLs were allocated on this clock cycle
  
   //
   logic [NP-1:0][max_local_link_num-1:0] 	  pl_empty;        // is downstream FIFO associated with PL empty?
   
   genvar 		  i,j,k,l; 
   integer a,b,c,d;
   
   // *******************************************************************************
   // output ports
   // *******************************************************************************
   generate
   for (i=0; i<NP; i++) begin:output_ports1

      //
      // Flow Control 
      //
      LAG_pl_fc_out #(.num_pls(links[i][OUT]),  //  links[i][OUT] contains number of links per i-th output trunk
		     .init_credits(buf_len))
	fcout (.flits_valid(flits_out_valid[i][links[i][OUT]-1:0]),
	       .channel_cntrl_in(i_cntrl_in[i][links[i][OUT]-1:0]),
	       .pl_status(x_pl_status[i][links[i][OUT]-1:0]),
	       .pl_empty(pl_empty[i][links[i][OUT]-1:0]), 
	       .clk, .rst_n);   
	       
      //      
      // Free PL pools 
      //
      

	 LAG_pl_free_pool #(.num_pls(links[i][OUT]),
			   .fifo_free_pool(!plalloc_unrestricted),
			   .only_allocate_pl_when_empty(plselect_onlywhenempty)) plfreepool
	   (.flits_tail(flits_out_tail[i][links[i][OUT]-1:0]), 
	    .flits_valid(flits_out_valid[i][links[i][OUT]-1:0]),
	    // Unrestricted free pool
	    .pl_alloc_status(pl_alloc_status[i][links[i][OUT]-1:0]),
	    .pl_allocated(pl_allocated[i][links[i][OUT]-1:0]),
	    .pl_empty(pl_empty[i][links[i][OUT]-1:0]),
	    //
	    .clk, .rst_n);
      
      
      for (j=0; j<links[i][OUT]; j++) begin:output_channels2
      
        assign flits_out_tail[i][j] = x_flit_xbarout[i][j].control.tail;
        assign flits_out_valid[i][j] = x_flit_xbarout[i][j].control.valid;//output_used[i][j];
        
      end
     
      always@(posedge clk) begin
	 if (!rst_n) begin
	    //i_cntrl_out[i].credits <= '0;
	 end else begin
	    //
	    // ensure 'credit' is registered before it is sent to the upstream router
	    //

	    // send credit corresponding to flit sent from this input port
	    //i_cntrl_out[i].credits <= x_pop[i];    
	 end
      end
    
    end 
      
   endgenerate
   
      
   // *******************************************************************************
   // input ports (pc buffers and PC registers)
   // *******************************************************************************

   generate
      for (i=0; i<router_num_pls_on_entry; i++) begin:plsx
	       assign i_input_full_flag[i] = x_flags[`TILE][i].full; // TILE input FIFO[i] is full?	       
      end

      
      for (i=0; i<NP; i++) begin:input_ports
	 
	 // input port 'i'
	 LAG_pl_input_port #(.num_pls(links[i][IN]), 
			    .buffer_length(buf_len),
          .max_links_num(max_local_link_num) ) inport
	   (.push(x_push[i][links[i][IN]-1:0]), 
	    .pop(x_pop[i][links[i][IN]-1:0]), 
	    .data_in(i_flit_in[i][links[i][IN]-1:0]), 
	    .data_out(flit_buffer_out[i][links[i][IN]-1:0]),
	    .flags(x_flags[i][links[i][IN]-1:0]), 
	    
	    .allocated_pl(x_allocated_pl[i][links[i][IN]-1:0]), 
	    
      .allocated_pl_valid(x_allocated_pl_valid[i][links[i][IN]-1:0]), 
	    .pl_new(x_pl_new[i][links[i][IN]-1:0]), 
	    .pl_new_valid(x_pl_new_valid[i][links[i][IN]-1:0]),
	    .clk, .rst_n);
      

      for (j=0; j<links[i][IN]; j++) begin:allpls2

	      LAG_route rfn (.flit_in(flit_buffer_out[i][j]), .flit_out(routed[i][j]), .clk, .rst_n);
        
        assign x_push[i][j] = i_flit_in[i][j].control.valid;
	      assign x_output_port[i][j] = flit_buffer_out[i][j].control.head ? flit_buffer_out[i][j].data[router_radix-1:0] : x_output_port_reg[i][j];
	    
	      assign i_cntrl_out[i][j] = x_pop[i][j]; 
      end
      
      for (j=0; j<links[i][IN]; j++) begin:allpls3
        always@(posedge clk) begin
	        if (!rst_n) begin
	          x_output_port_reg[i][j] <= '0;
	        end else if (flit_buffer_out[i][j].control.head) begin

	           x_output_port_reg[i][j] <= flit_buffer_out[i][j].data[router_radix-1:0];  
	         end
        end
      end

      for (j=0; j<links[i][IN]; j++) begin:reqs
	    //
	    // PHYSIC-CHANNEL ALLOCATION REQUESTS
	    //
        assign pl_request[i][j]= (LAG_route_valid_input_pl(i,j)) ? 
				  !x_flags[i][j].empty & !x_allocated_pl_valid[i][j] : 1'b0;
	 
	      assign x_pop[i][j] = !x_flags[i][j].empty & x_allocated_pl_valid[i][j] & ~allocated_pl_blocked[i][j];

      end // block: reqs
      
      
      for (j=0; j<links[i][IN]; j++) begin:flit_to_out_valid
        always_comb begin
          x_flit_xbarin[i][j] = flit_buffer_out[i][j].control.head ? routed[i][j] : flit_buffer_out[i][j];
        
          x_flit_xbarin[i][j].control.valid = x_pop[i][j];
        end
      end
      
   end // block: input_ports
      
   endgenerate
   
      LAG_pl_status #(.np(NP), 
                      .links(links), 
                      .ln_num(max_local_link_num)
                      ) vstat (.output_port(x_output_port), 
                                .allocated_pl(x_allocated_pl),
                                .allocated_pl_valid(x_allocated_pl_valid),
                        	      .pl_status(x_pl_status), 
                                .pl_blocked(allocated_pl_blocked));

   // ----------------------------------------------------------------------
   // physical-channel allocation logic
   // ----------------------------------------------------------------------
   LAG_pl_unrestricted_allocator #(.buf_len(buf_len), .np(NP), .xs(network_x), .ys(network_y), 
         .alloc_stages(alloc_stages),
         .max_links_num(max_local_link_num), 
         .links(links),
		     .dynamic_priority_pl_alloc( priority_flit_dynamic_pl_alloc),
		     .plselect_bydestinationnode(plselect_bydestinationnode), 
		     .plselect_leastfullbuffer(plselect_leastfullbuffer), 
		     .plselect_arbstateupdate(plselect_arbstateupdate), 
		     .plselect_usepacketmask(plselect_usepacketmask))
     plalloc
       (.req(pl_request), 
	.output_port(x_output_port),
	.pl_new(x_pl_new),
	.pl_new_valid(x_pl_new_valid),
	// unrestricted PL pool
	.pl_allocated(pl_allocated),
	.pl_status(pl_alloc_status_), 
	.clk, .rst_n);

  generate
    for (i=0; i<NP; i++) begin: out_ports_xbar_select
      for (j=0; j<links[i][OUT]; j++) begin: out_channels_xbar_select
        for (k=0; k<NP; k++) begin: in_ports_xbar_select
          for (l=0; l<links[k][IN]; l++) begin: in_channels_xbar_select
            assign xbar_select[i*max_local_link_num+j][k*max_local_link_num+l] = x_output_port_reg[k][l][i] & x_allocated_pl[k][l][j] ;//& x_allocated_pl_valid[k][l];        
                                                                                 //может быть узкое место, поскольку работаем с
                                                                                 //x_allocated_pl, который обновляется на след.
                                                                                 //такте после выделения. Соответственно,
                                                                                 //на том такте, когда происходит выделение,
                                                                                 //xbar_select не будет установлен
          end
        end
      end
    end  
  endgenerate
    
  generate
    for (i=0; i<NP; i++) begin: in_ports_xbar
      for (j=0; j<links[i][IN]; j++) begin: in_channels_xbar
        assign x_flit_xbarin_[i*max_local_link_num+j] = x_flit_xbarin[i][j];
      end
    end  
  endgenerate  
  
  generate
    for (i=0; i<NP; i++) begin: out_ports_xbar
      for (j=0; j<links[i][OUT]; j++) begin: out_channels_xbar
        assign x_flit_xbarout[i][j] = x_flit_xbarout_[i*max_local_link_num+j];
      end
    end  
  endgenerate   
   
   // ----------------------------------------------------------------------
   // crossbar
   // ----------------------------------------------------------------------

	 LAG_crossbar_oh_select #(.np(NP), 
                            .max_links_num(max_local_link_num), 
                            .links(links)
                            ) myxbar (x_flit_xbarin_, xbar_select, x_flit_xbarout_); 
   
   
   // ----------------------------------------------------------------------
   // output port logic
   // ----------------------------------------------------------------------
   generate
   for (i=0; i<NP; i++) begin:outports
      for (j=0; j<links[i][OUT]; j++) begin:outchannels
       
        assign i_flit_out[i][j] = x_flit_xbarout[i][j];
	
      end //block: outchannels
   end // block: outports
   
   endgenerate 
   
   always_comb begin
   
   pl_alloc_status_ = '0;
   
   for(a=0; a < NP; a++)
    for(b=0; b < links[a][OUT]; b++)
      pl_alloc_status_[a][b] = pl_alloc_status[a][b];  
   
   end
  
  //
  //calculating the number of blockings per each input link
  // 
  // synopsys translate_off
  always @(posedge clk) begin
    if (!rst_n) begin 
      
      for(c=0; c < NP; c++)
        for(d=0; d < max_local_link_num; d++) 
          blockings[c][d] = '0;
  
    end else begin
      
      for(c=0; c < NP; c++)
        for(d=0; d < links[c][IN]; d++)
          blockings[c][d] = blockings[c][d] + pl_request[c][d] & ~x_pl_new_valid[c][d];  
          
    end
  end
  // synopsys translate_on
   
endmodule // simple_router
