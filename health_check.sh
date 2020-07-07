#!/bin/bash

curl http://127.0.0.1:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/healthStatus 2>/dev/null | jq -r '.value'