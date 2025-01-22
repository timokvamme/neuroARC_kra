#!/bin/bash

echo "Starting 10-minute test job"
for i in {1..10}
do
    echo "Minute $i of 10"
    sleep 60
done
echo "Test job completed successfully"