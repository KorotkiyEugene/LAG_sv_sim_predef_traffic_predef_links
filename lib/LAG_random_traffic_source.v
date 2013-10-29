/* -------------------------------------------------------------------------------
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"
 * -------------------------------------------------------------------------------
 *
 *  *** NOT FOR SYNTHESIS ***
 * 
 */

module LAG_random_traffic_source(flit_out, network_ready, flits_sent_o, clk, rst_n);

   parameter np = 4; // number of physical-channels available on entry to network
   
   parameter xdim = 4; // mesh network size
   parameter ydim = 4;
   
   parameter xpos = 0; // random source is connected to which router in mesh?
   parameter ypos = 0;
   parameter packet_length = 3;

   parameter real destinations[][] = '0;  //'{};                 //1-st dim. - particular destination
                                                           //2-nd dim. - x pos., y pos. and injection rate for dest.
   localparam dest_num = destinations.size();

   output flit_t flit_out;
   output integer flits_sent_o;
   input [np-1:0] network_ready;
   input clk, rst_n;

//==========
   
   integer sys_time, seed, i, inject_count, flit_count;
   
   integer last_dest_num;
   
   integer packets_to_inject[] = new[dest_num];
   
   typedef integer fifo_t [$];
   fifo_t i_time[] = new[dest_num];
   
   real dest_probs[] = new[dest_num];
   real summary_injection_rate;
   
   logic   fifo_ready;
   
   logic   push;
   flit_t data_in, data_out, routed, d;
   fifov_flags_t fifo_flags;
   integer xdest, ydest;

   integer flits_buffered, flits_sent;

`ifndef DEBUG
   !!!! You must set the DEBUG switch if you are going to run a simulation !!!!
`endif
     
   //
   // FIFO connected to network input 
   //
   LAG_fifo_v #(.size(2+packet_length*20))
     source_fifo
       (.push(push),
	// dequeue if network was ready and fifo had a flit
	.pop(!fifo_flags.empty && network_ready[0]),  
	.data_in(data_in), 
	.data_out(data_out),
	.flags(fifo_flags), .clk, .rst_n);
   
   LAG_route rfn (.flit_in(data_out), .flit_out(routed), .clk, .rst_n);
   
   assign fifo_ready = !(fifo_flags.full | fifo_flags.nearly_full);
   
      
   always_comb
     begin
  if (data_out.control.head) begin  
	  flit_out = routed;
	end else begin
    flit_out = data_out;
  end  
	flit_out.control.valid = network_ready[0] && !fifo_flags.empty;
     end

   //
   // Generate and Inject Packets at Random Intervals to Random Destinations
   //
   always@(posedge clk) begin
      if (!rst_n) begin
	 
	 flits_sent_o = 0;
	 
	 flits_buffered=0;
	 flits_sent=0;
	 
	 last_dest_num = 0;
	 
	 for (i=0; i<dest_num; i++)  begin
	   i_time[i] = {}; // assigning empty queue
     packets_to_inject[i] = 0;
   end  
	 
	 sys_time=0;
	
	 inject_count=0;
	 flit_count=0;

	 push=0;
	 
      end else begin

	 if (network_ready[0]===1'bx) begin
	    $write ("Error: network_ready=%b", network_ready[0]);
	    $finish;
	 end

	 if (!fifo_flags.empty && network_ready[0]) begin
      flits_sent++;
      flits_sent_o = flits_sent;
   end   
      
	 if (push) flits_buffered++;

	 /*if (fifo_ready) begin
	    while ((i_time!=sys_time) && !is_injecting_packet(packets_to_inject) ) begin
	       
	       // **********************************************************
	       // Random Injection Process For Each Destination
	       // **********************************************************
	       // (1 and 10000 are possible random values)
	       for (i=0; i<dest_num; i++) begin
	       
	         if ($dist_uniform(seed, 1, 10000) <= dest_probs[i]) begin
		        packets_to_inject[i]++;
	         end
	       
	       end
	       
	       i_time++;

	    end 
	 end*/

   if(fifo_ready) begin
   	  for (i=0; i<dest_num; i++) begin
	       
	     if ($dist_uniform(seed, 1, 10000) < dest_probs[i]) begin
		    packets_to_inject[i]++;
        //i_time[i].push_back(sys_time);
	     end
	       
	    end 
   end //else if (xpos == 2 && ypos == 1) $finish;
	 
	 if (fifo_ready && is_injecting_packet(packets_to_inject)) begin

      /*
	    // random source continues as we buffer flits in FIFO 
	    for (i=0; i<dest_num; i++) begin
	       
	     if ($dist_uniform(seed, 1, 10000) <= dest_probs[i]) begin
		    packets_to_inject[i]++;
	     end
	       
	    end */
	    
	    flit_count++;
	    
	    push <= 1'b1;

	    if (flit_count==1) begin
	     
	       d='0;
	       
	       inject_count++;
	       
         last_dest_num = next_dest_num(packets_to_inject, last_dest_num);
	       
         xdest = destinations[last_dest_num][0];
	       ydest = destinations[last_dest_num][1];
	       
	       d.debug.xdest=xdest;
	       d.debug.ydest=ydest;
	       d.debug.xsrc=xpos;
	       d.debug.ysrc=ypos;
	       
	       d.data[router_radix + `X_ADDR_BITS : router_radix] = x_displ_t'(xdest-xpos);
	       d.data[router_radix + `X_ADDR_BITS + `Y_ADDR_BITS + 1 : router_radix + `X_ADDR_BITS + 1] = y_displ_t'(ydest-ypos);
	       d.control.head = 1'b1;
       
	       d.control.tail = 1'b0;

	       //d.debug.inject_time = i_time[last_dest_num].pop_front();
         d.debug.inject_time = sys_time;
         
	       d.debug.flit_id = flit_count;
	       d.debug.packet_id = inject_count;
	       d.debug.hops = 0;
	    
      end else begin
          
          d.control.head = 1'b0;
          d.debug.flit_id = flit_count;
          
          //
          // Send Tail Flit
          //
	       if (flit_count==packet_length) begin
  	         // inject tail
            d.control.tail = 1'b1;
  	       
            packets_to_inject[last_dest_num]--;	
           	       
            flit_count=0;

	       end
          
      end
      
	 end else begin // if (injecting_packet)
	    push <= 1'b0;
	 end
	 
	 sys_time++;
	 
	 data_in <= d;
	 
      end // else: !if(!rst_n)
   end

   initial begin
      
      packets_to_inject = new[dest_num];
      
      for(i=0; i<dest_num; i++) begin
        summary_injection_rate += destinations[i][2];
        dest_probs[i] = 10000 * destinations[i][2] / packet_length;
      end
      
      if(summary_injection_rate > 1) begin
        $display("%m ERROR!!! Summary injection rate in traffic source shouldn't exceed 1 flit/cycle");
        $finish;
      end
      
      // we don't want any traffic sources to have the same 
      // random number seed!
      seed = xpos*50+ypos;
   
   end
   
endmodule // LAG_random_source

//--------------------------------------------------------------------------

function is_injecting_packet;

input integer packets_to_inject[];

integer size;
integer i;

begin

size = packets_to_inject.size();
is_injecting_packet = 0;

for(i=0; i<size && !is_injecting_packet; i++) begin
  is_injecting_packet = (packets_to_inject[i] > 0);
end

end

endfunction

//--------------------------------------------------------------------------

function integer next_dest_num;

input integer packets_to_inject[];
input integer last_dest_num;

integer size;
integer i;
logic next_ok;

begin

size = packets_to_inject.size();
next_ok = 0;

for(i = last_dest_num + 1; (i < size) && !next_ok; i++)
  if (packets_to_inject[i]) begin
    next_dest_num = i;
    next_ok = 1;  
  end

for(i = 0; i <= last_dest_num && !next_ok; i++)
  if (packets_to_inject[i]) begin
    next_dest_num = i;
    next_ok = 1;  
  end

end

endfunction
