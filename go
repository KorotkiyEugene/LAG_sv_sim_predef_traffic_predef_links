
if [ "$1" == "clean" ]; then
  rm -f defines.v
  rm -f parameters.v
  rm -f *.results
  rm -f *~ 
else

  bin/makeconfig.pl -f router_config/baseline.config \
	--sim_warmup_packets 100 \
	--sim_measurement_packets 1000 

  bin/vt sim_config/predefined_traffic.f | tee quickstart.results

fi





