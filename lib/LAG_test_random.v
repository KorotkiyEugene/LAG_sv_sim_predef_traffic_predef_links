/* -------------------------------------------------------------------------------
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 *--------------------------------------------------------------------------------
 */

//`timescale 1ps/1ps

module LAG_test_random ();

   parameter CLOCK_PERIOD = 10_000;
   
   localparam global_links_num = find_max_global_link_num(links);

   flit_t flit_in[network_x-1:0][network_y-1:0];
   flit_t flit_out[network_x-1:0][network_y-1:0][global_links_num-1:0];
   logic [router_num_pls_on_entry-1:0] input_full_flag [network_x-1:0][network_y-1:0];
   logic [global_links_num-1:0] cntrl_in [network_x-1:0][network_y-1:0];
   
   integer rec_count [network_x-1:0][network_y-1:0];
   integer flits_sent [network_x-1:0][network_y-1:0];
   sim_stats_t stats [network_x-1:0][network_y-1:0];

   real    av_lat[network_x-1:0][network_y-1:0];
   integer    link_util [network_x-1:0][network_y-1:0][router_radix-1:0][global_links_num-1:0]; 
   real    link_util_ [network_x-1:0][network_y-1:0][router_radix-1:0][global_links_num-1:0];
   
   genvar  x,y;
   integer i,j,k,l;
   integer sys_time, total_packets, total_hops, min_latency, max_latency, total_latency;
   integer min_hops, max_hops;
   integer total_rec_count;
   integer total_send_count;
   
   integer lat_freq[100:0];
   
   logic clk, rst_n;
   
   integer s;
   
   
   // clock generator
   initial begin
      clk=0;
   end
   
   always #(CLOCK_PERIOD/2) clk = ~clk;

   always@(posedge clk) begin
      
      if (!rst_n) begin
	       sys_time=0;
      end else begin
	       sys_time++;
      end

   end
   
   // ########################
   // Network
   // ########################

   LAG_mesh_network #(.XS(network_x), 
                      .YS(network_y), 
                      .NP(router_radix), 
                      .global_links_num(global_links_num),
                      .links(links)
                    ) network 
                             (flit_in, flit_out,
                      	       input_full_flag,
                      	       cntrl_in, link_util,
                      	       clk, rst_n
                              );
   
   // ########################
   // Traffic Sources
   // ########################
   generate
      for (x=0; x<network_x; x++) begin:xl
	 for (y=0; y<network_y; y++) begin:yl

	    LAG_random_traffic_source #(.np(router_num_pls_on_entry),
               .destinations(destinations[x][y]), 
				       .xdim(network_x), .ydim(network_y), .xpos(x), .ypos(y),
				       .packet_length(sim_packet_length)
				       )
	      traf_src (.flit_out(flit_in[x][y]), 
	                 .flits_sent_o(flits_sent[x][y]),
			             .network_ready(~input_full_flag[x][y]), 
			             .clk, .rst_n
                  );
	 end
      end
   endgenerate

   // ########################
   // Traffic Sinks
   // ########################
   generate
      for (x=0; x<network_x; x++) begin:xl2
	 for (y=0; y<network_y; y++) begin:yl2

	    LAG_traffic_sink #(.xdim(network_x), .ydim(network_y), .xpos(x), .ypos(y), .global_links_num(global_links_num),
			      .local_links_num(links[x][y][`TILE][OUT]), .warmup_packets(sim_warmup_packets), .measurement_packets(sim_measurement_packets)
			      )
	      traf_sink (.flit_in(flit_out[x][y]), 
			 .cntrl_out(cntrl_in[x][y]), 
			 .rec_count(rec_count[x][y]), 
			 .stats(stats[x][y]), 
			 .clk, .rst_n);
	    
	 end
      end
   endgenerate


   //
   // All measurement packets must be received before we end the simulation
   // (this includes a drain phase)
   //
   always@(posedge clk) begin
      
      total_rec_count = 0;
      
      for (i=0; i<network_x; i++) begin
	       for (j=0; j<network_y; j++) begin
	         if(rec_count[i][j] != -1)
	             total_rec_count = total_rec_count+rec_count[i][j];
	       end
      end
      
      if ( rst_n /* if not reset */ && ((total_rec_count - sim_warmup_packets)%(sim_measurement_packets/20)) == 0 ) 
        $display ("%1d: %1.2f%% complete", sys_time, $itor(total_rec_count*100)/$itor(sim_measurement_packets) );
  
   end
   
   initial begin

      $display ("******************************************");
      $display ("* NoC with LAG - Predefined Traffic Test *");
      $display ("******************************************");

      total_hops=0;
      total_latency=0;
      total_send_count=0;
      
	    link_util_[i][j][k][l] = '0;
	            
      //
      // reset
      //
      rst_n=0;
      // reset
      #(CLOCK_PERIOD*20);
      rst_n=1;

      $display ("-- Reset Complete");
      $display ("-- Entering warmup phase (%1d packets per node)", sim_warmup_packets);

`ifdef DUMPTRACE      
      $dumpfile ("/tmp/trace.vcd");
      $dumpvars;
`endif      
      
      // #################################################################
      // wait for all traffic sinks to rec. all measurement packets
      // #################################################################
      wait (total_rec_count > sim_measurement_packets);
      
      $display ("** Simulation End **\n");

      //calculating utilization of links
      for (i=0; i<network_x; i++)
	      for (j=0; j<network_y; j++)
	        for (k=0; k<router_radix; k++)
	          for (l=0; l<global_links_num; l++)
	            link_util_[i][j][k][l] = $itor(link_util[i][j][k][l]) / $itor(sys_time);

      //calculating the blocking rate of each input link of each router

      total_packets = sim_measurement_packets;

      min_latency=stats[0][0].min_latency;
      max_latency=stats[0][0].max_latency;
      min_hops=stats[0][0].min_hops;
      max_hops=stats[0][0].max_hops;

      for (i=0; i<network_x; i++) begin
	 for (j=0; j<network_y; j++) begin
	    av_lat[i][j] = $itor(stats[i][j].total_latency)/$itor(rec_count[i][j]);
	    
	    total_latency = total_latency + stats[i][j].total_latency;
	    
	    total_hops=total_hops+stats[i][j].total_hops;

	    min_latency = min(min_latency, stats[i][j].min_latency);
	    max_latency = max(max_latency, stats[i][j].max_latency);
	    min_hops = min(min_hops, stats[i][j].min_hops);
	    max_hops = max(max_hops, stats[i][j].max_hops);
	 end
      end

      for (i=0; i<network_x; i++) begin
	      for (j=0; j<network_y; j++) begin
          total_send_count += flits_sent[i][j] / sim_packet_length;
        end
      end
      

      for (k=0; k<=100; k++) lat_freq[k]=0;
      
      for (i=0; i<network_x; i++) begin
	       for (j=0; j<network_y; j++) begin
	         for (k=0; k<=100; k++) begin
	             lat_freq[k]=lat_freq[k]+stats[i][j].lat_freq[k];
	         end
	       end
      end

      $display ("***********************************************************************************");
      $display ("-- Channel Latency = %1d", 0);
      $display ("***********************************************************************************");
      $display ("-- Packet Length   = %1d", sim_packet_length);
      $display ("-- Average Latency = %1.2f (cycles)", $itor(total_latency)/$itor(total_packets));
      $display ("-- Min. Latency    = %1d, Max. Latency = %1d", min_latency, max_latency);
      $display ("-- Average no. of hops taken by packet = %1.2f hops (min=%1d, max=%1d)", 
		$itor(total_hops)/$itor(total_packets), min_hops, max_hops);
      $display ("***********************************************************************************");

      $display ("\n");
      $display ("Average Latencies for packets rec'd at nodes [x,y] and (no. of packets received)");
      for (j=0; j<network_y;j++) begin
	     for (i=0; i<network_x; i++)
           if (rec_count[i][j] != -1) 
               $write ("%1.2f (%1d)\t", av_lat[i][j], rec_count[i][j]);
           else
               $write ("0.00 (0)\t");   
	 $display ("");
      end

      $display ("");
      
      $display ("Flits/cycle sent at each node:");
      for (j=0; j<network_y; j++) begin
	  for (i=0; i<network_x; i++) begin
	    $write ("%1.2f\t", $itor(flits_sent[i][j])/$itor(sys_time));
	 end
	 $display ("");
      end
      
      $display ("");
      
      $display ("Flits/cycle received at each node: (should approx. injection rate)");
      for (j=0; j<network_y; j++) begin
	  for (i=0; i<network_x; i++) begin
	    $write ("%1.2f\t", $itor(stats[i][j].flit_count)/$itor(stats[i][j].measure_end-stats[i][j].measure_start));
	 end
	 $display ("");
      end
      
      $display ("");
      
      $display ("Latencies for packet flows (in clock cycles)");
      $display("----------------------------------------------------------");
      for (j=0; j<network_y; j++) // destination y
	     for (i=0; i<network_x; i++) // destination x
	       for (l=0; l<network_y; l++) // source y
	          for (k=0; k<network_x; k++) // source x
              if(stats[i][j].flows_latencies[k][l][0]) begin
                  $display ("(%1d, %1d) -> (%1d, %1d): min = %1d;   av = %1d;   max = %1d;", 
                            k, l, i, j, stats[i][j].flows_latencies[k][l][3], 
                            stats[i][j].flows_latencies[k][l][1] / stats[i][j].flows_latencies[k][l][2], 
                            stats[i][j].flows_latencies[k][l][4]);  
                  $display("----------------------------------------------------------");
              end            
      
      $display ("\n");
      $display ("Distribution of packet latencies: ");
      $display ("Latency : Frequency (as percentage of total)");
      $display ("-------------------");
      for (k=0; k<100; k++) begin
	 $display ("%1d %1.2f", k, $itor(lat_freq[k]*100)/$itor(total_packets));
      end
      $display ("100+ %1.2f", $itor(lat_freq[k]*100)/$itor(total_packets));
      
      $finish;
   end
   
endmodule // LAG_test_random
