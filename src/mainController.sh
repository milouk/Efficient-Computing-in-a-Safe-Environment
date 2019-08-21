#!/bin/bash

for i in {1..20}; do
	bash execute_experiment.sh -n pi -a 195.251.251.23 -b sgeorgiou -d 195.251.251.22
done

bash presentResults.sh ../results
ssmtp sgeorgiou@aueb.gr < ../msg.txt
