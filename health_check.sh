#!/bin/bash

# Check health status
#HEALTHCHECK="$(curl -H 'Origin:localhost' -u admin:admin -s http://dv00kub.iqn.com:31008/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/healthStatus)"
HEALTHCHECK="$(curl -H 'Origin:localhost' -u admin:admin -s http://localhost:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/healthStatus)"
STATUS="$(jq -r '.value' <<< ${HEALTHCHECK})"


if [ "$STATUS" != "Good" ]; then
   ACTIVEMQ_PID="$(cat {ACTIVEMQ_BASE}/activemq.pid)"
   if [[ "$STATUS" = "Getting Worried"* ]]; then
   	echo "WARN: ActiveMQ with PID=${ACTIVEMQ_PID} is Getting Worried. MESSAGE=${HEALTHCHECK}" >&2
   	  # Not leaving with an ERROR code, because the node is still working.
   else
	  # Killing the process
      # systemd should restart the process as I have the property restart=Always
      # if not make sure to start the process again
      #kill -9 $ACTIVEMQ_PID 
   	echo "ERROR: ActiveMQ with PID=${ACTIVEMQ_PID} failed the health check! MESSAGE=${HEALTHCHECK}" >&2
      exit 1
   fi
else
   echo "INFO: ActiveMQ up and running. MESSAGE=${HEALTHCHECK}" >&1
fi
