/* -------------------------------------------------------------------------------
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 * -------------------------------------------------------------------------------
 *
 *   *** NOT FOR SYNTHESIS ***
 * 
 */

module LAG_traffic_sink (flit_in, cntrl_out, rec_count, stats, clk, rst_n);
   
   parameter xdim = 4;
   parameter ydim = 4; 
   
   parameter xpos = 0;
   parameter ypos = 0;

   parameter warmup_packets = 100;
   parameter measurement_packets = 1000;
   
   parameter global_links_num = 2;
   parameter local_links_num = 2;
   
   input     flit_t flit_in [global_links_num-1:0];
   output    logic [global_links_num-1:0] cntrl_out;
   output    sim_stats_t stats;
   input     clk, rst_n;
   output    integer rec_count;

   integer   expected_flit_id [local_links_num-1:0];
   integer   head_injection_time [local_links_num-1:0];
   integer   latency, sys_time;
   integer   src_x, src_y;
   integer   j, i;
   integer   warmup_rec_count;
   
   genvar ch;
    
   
   for (ch=0; ch<local_links_num; ch++) begin:flow_control
    always@(posedge clk) begin
      if (!rst_n) begin	   
        cntrl_out[ch] <= 0;	 
      end else begin
        if (flit_in[ch].control.valid) begin
          if (ch < local_links_num) begin
            cntrl_out[ch] <= 1;
          end else begin
            $display ("%m: Error: Flit Channel ID is out-of-range for exit from network!");
	          $display ("Channel ID = %1d (router_num_pls_on_exit=%1d)", ch, router_num_pls_on_exit);
	          $finish;
          end
        end else begin
          cntrl_out[ch] <= 0;
        end
      end
    end   
   end

   
   always@(posedge clk) begin
      if (!rst_n) begin
	   
         rec_count=-1;
      	 stats.total_latency=0;
      	 stats.total_hops=0;
      	 stats.max_hops=0;
      	 stats.min_hops=MAXINT;
      	 stats.max_latency=0;
      	 stats.min_latency=MAXINT;
      	 stats.measure_start=-1;
      	 stats.measure_end=0;
      	 stats.flit_count=0;
      	 
      	 warmup_rec_count = 0;
      	 
         src_x = 0;
  	     src_y = 0;
  	 
  	     for(i = 0; i < xdim; i++)
  	       for(j = 0; j < ydim; j++) begin  
              
              stats.flows_latencies[i][j][0] = 0;
              stats.flows_latencies[i][j][1] = 0;
              stats.flows_latencies[i][j][2] = 0;
              stats.flows_latencies[i][j][3] = 32'd1000000;
              stats.flows_latencies[i][j][4] = 0;
           
           end   
  	 
         for (j=0; j<local_links_num; j++) begin
      	    expected_flit_id[j]=1;
      	    head_injection_time[j]=-1;
      	 end
      
      
      	 for (j=0; j<=100; j++) begin
      	    stats.lat_freq[j]=0;
      	 end
	 
	       sys_time = 0;
	 
      end else begin // if (!rst_n)
	 
        sys_time++;
	 
	   for (i=0; i<local_links_num; i++) begin
	 if (flit_in[i].control.valid) begin
            
      //$display ("%m: Packet %d arrived!!!", rec_count);
	    
	    //
	    // check flit was destined for this node!
	    //
	    if ((flit_in[i].debug.xdest!=xpos)||(flit_in[i].debug.ydest!=ypos)) begin
	       $display ("%m: Error: Flit arrived at wrong destination!");
	       $finish;
	    end

	    //
	    // check flit didn't originate at this node
	    //
	    if ((flit_in[i].debug.xdest==flit_in[i].debug.xsrc)&&
		(flit_in[i].debug.ydest==flit_in[i].debug.ysrc)) begin
	       $display ("%m: Error: Received flit originated from this node?");
	       $finish;
	    end
	    
	    //
	    // check flits for each packet are received in order
	    //
	    if (flit_in[i].debug.flit_id != expected_flit_id[i]) begin
	       $display ("%m: Error: Out of sequence flit received? (packet generated at %1d,%1d)",
			 flit_in[i].debug.xsrc, flit_in[i].debug.ysrc);
	       $display ("-- Flit ID = %1d, Expected = %1d", flit_in[i].debug.flit_id, expected_flit_id[i]);
	       $display ("-- Packet ID = %1d", flit_in[i].debug.packet_id);
	       $finish;
	    end else begin

//	       $display ("%m: Rec: Flit ID = %1d, Packet ID = %1d, PL ID=%1d", 
//			 flit_in.debug.flit_id, flit_in.debug.packet_id, flit_in.control.pl_id);
	    end

	    expected_flit_id[i]++;
	    
//	    $display ("rec flit");

	    // #####################################################################
	    // Head of new packet has arrived
	    // #####################################################################
	    if (flit_in[i].debug.flit_id==1) begin
//	       $display ("%m: new head, current_pl=%1d, inject_time=%1d", current_pl, flit_in.debug.inject_time);
	       head_injection_time[i] = flit_in[i].debug.inject_time;
	       if ((warmup_rec_count == warmup_packets) && (stats.measure_start==-1))  stats.measure_start = sys_time;
      end

	    // count all flits received in measurement period
	    if (stats.measure_start!=-1) stats.flit_count++;

	    
	    // #####################################################################
	    // Tail of packet has arrived
	    // Remember, latency = (tail arrival time) - (head injection time)
	    // #####################################################################
	    if (flit_in[i].control.tail) begin
	       
	       expected_flit_id[i]=1;
	       warmup_rec_count++;

	       if (stats.measure_start!=-1) begin

		        rec_count++;

		        // time last measurement packet was received
		        stats.measure_end = sys_time;
		  
		        //
      		  // gather latency stats.
      		  //
      		  
      		  latency = sys_time - head_injection_time[i]; 
      		  stats.total_latency = stats.total_latency + latency;
      
      		  stats.min_latency = min (stats.min_latency, latency);
      		  stats.max_latency = max (stats.max_latency, latency);
      		  
      		  src_x = flit_in[i].debug.xsrc;
      		  src_y = flit_in[i].debug.ysrc;
      		  
      		  stats.flows_latencies[src_x][src_y][0] = 1;
      		  stats.flows_latencies[src_x][src_y][1] += latency;
      		  stats.flows_latencies[src_x][src_y][2]++;
      		  stats.flows_latencies[src_x][src_y][3] = min(stats.flows_latencies[src_x][src_y][3], latency);
      		  stats.flows_latencies[src_x][src_y][4] = max(stats.flows_latencies[src_x][src_y][4], latency);
      		  
      		  //
      		  // sum latencies for different packet distances (and keep total distance travelled by all packets)
      		  //
      //		  $display ("This packet travelled %1d hops", flit_in.debug.hops);
      		  stats.total_hops = stats.total_hops + flit_in[i].debug.hops;
      
      		  stats.min_hops = min (stats.min_hops, flit_in[i].debug.hops);
      		  stats.max_hops = max (stats.max_hops, flit_in[i].debug.hops);
      		  
      		  //
      		  // bin latencies
      		  //	
      		  stats.lat_freq[min(latency, 100)]++;
	       end
	       
	    end // if (flit_in.control.tail)
	    
	 end // if flit valid
	 end //for
      end  //if(!rst_n)
   end //always
   
endmodule
