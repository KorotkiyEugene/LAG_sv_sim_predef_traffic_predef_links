
/* -------------------------------------------------------------------------------
 * (C)2007 Robert Mullins
 * Computer Architecture Group, Computer Laboratory
 * University of Cambridge, UK.
 * 
 * (C)2012 Korotkyi Ievgen
 * National Technical University of Ukraine "Kiev Polytechnic Institute"   
 * -------------------------------------------------------------------------------
 * 
 * Type definitions
 * 
 * 'flit_t' gets defined here
 * 
 */

//
// `defines are read from defines.v (generated from configuration file)
//
// here we use values of parameters from parameters.v

`ifndef __TYPES_V__
`define __TYPES_V__

`timescale 1ps/1ps

   
typedef logic [router_radix-1:0] output_port_t;
typedef logic [router_num_pls-1:0] pl_t;
typedef logic [channel_data_width-1:0] data_t;
typedef enum integer {IN = 0, OUT = 1} in_out_t;

// could save one bit here
typedef logic signed [`X_ADDR_BITS:0] x_displ_t;
typedef logic signed [`Y_ADDR_BITS:0] y_displ_t;

typedef struct packed 
{
	 pl_t credits;
   
} chan_cntrl_t;

typedef struct packed
	{
	 logic measure;        // 1 - include in statistics? (else 0 - warmup or drain phase)
	 integer flit_id;      // sequential flit id.
	 integer packet_id;    // sequential (for a particular source node) packet id.
	 integer inject_time;  // time flit entered source FIFO
	 
	 integer hops;         // no. of routers flit traverses on journey
	 
	 integer xdest, ydest; // final destination
	 integer xsrc, ysrc;   // where was packet sent from
	 
	 } debug_flit_t;

typedef struct packed
	{
	 logic valid;	   
	 logic tail;
   logic head;	 
	 } control_flit_t;
   
typedef struct packed
	{
	 data_t data;
	 control_flit_t control;
`ifdef DEBUG
	 debug_flit_t debug;
`endif
	 } flit_t;

typedef flit_t fifo_elements_t;

// port ids for 5 port router (input or output)
`define port5id_north 5'b00001
`define port5id_east  5'b00010
`define port5id_south 5'b00100
`define port5id_west  5'b01000
`define port5id_tile  5'b10000

`define NORTH 0
`define EAST  1
`define SOUTH 2
`define WEST  3
`define TILE  4

// arrays of struct with real numbers are not supported by SystemVerilog?
   
typedef struct 
  {
    integer total_latency;
    integer total_hops;
    integer min_latency, max_latency;
    integer min_hops, max_hops;
    
    integer flows_latencies[network_x][network_y][5]; // First 2 dimensions pointed flow of packets (source of flow) for current dest.
                                                        // third dimension: 
                                                        //0 el. - true if source indexed by first 2 dimensions sends packets to this dest, false - in another case
                                                        //1 el. - total latency for this flow
                                                        //2 el. - number of rec. packets for this flow 
                                                        //3 el. - min lat. for this flow
                                                        //4 el. - max lat. for this flow

   // start and end of measurement period
    integer measure_start, measure_end, flit_count; 
   
   // record frequency of different packet latencies
    integer lat_freq[100:0];
   
   } sim_stats_t;

parameter MAXINT = 2^32-1;

`endif