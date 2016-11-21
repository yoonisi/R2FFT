
create_clock -name clk -period 10 [ get_ports clk ]

set_input_delay -clock { clk } 0  [ remove_from_collection [ all_inputs] [get_ports clk] ]
set_output_delay -clock { clk } 0 [ all_outputs ]
