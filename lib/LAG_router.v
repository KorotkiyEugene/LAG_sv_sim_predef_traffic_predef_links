/* -------------------------------------------------------------------------------
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 *--------------------------------------------------------------------------------
 */

module LAG_router (i_flit_in, i_flit_out,
		  i_cntrl_in, i_cntrl_out,
		  i_input_full_flag, 
		  clk, rst_n);

   parameter NP=router_radix;
   parameter NV=router_num_pls;
   parameter global_links_num = 2;
   parameter integer links[router_radix][2] = '{'{2,2}, '{2,2}, '{2,2}, '{2,2}, '{2,2} };
   
   // FIFO rec. data from tile/core is full?
   output  [router_num_pls_on_entry-1:0] i_input_full_flag;
   // link data and control
   input   flit_t i_flit_in [NP-1:0][global_links_num-1:0];
   output  flit_t i_flit_out [NP-1:0][global_links_num-1:0];
   input   [global_links_num-1:0] i_cntrl_in [NP-1:0];
   output  [global_links_num-1:0] i_cntrl_out [NP-1:0];
   input   clk, rst_n;
  

	     LAG_pl_router #(.buf_len(router_buf_len),
	        .global_links_num(global_links_num),
			    .network_x(network_x),
			    .network_y(network_y),
			    .NP(NP), 
			    .links(links),
			    .alloc_stages(router_alloc_stages),
			    .router_num_pls_on_entry(router_num_pls_on_entry),
			    .router_num_pls_on_exit(router_num_pls_on_exit)
			    ) router
	       (i_flit_in, i_flit_out,
		i_cntrl_in, i_cntrl_out,
		i_input_full_flag, 
		clk, rst_n);
   
endmodule
   
