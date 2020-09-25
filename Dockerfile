FROM openjdk:11.0-jre

LABEL MAINTAINER="Architecture"

ENV JDK_VERSION=11.0 \
    ACTIVEMQ_VERSION=5.16.0 \
    ACTIVEMQ_HOME=/opt/activemq    

ENV ACTIVEMQ=apache-activemq-${ACTIVEMQ_VERSION} \
    ACTIVEMQ_TCP=61616 \
    ACTIVEMQ_AMQP=5672 \
    ACTIVEMQ_STOMP=61613 \
    ACTIVEMQ_MQTT=1883 \
    ACTIVEMQ_WS=61614 \
    ACTIVEMQ_UI=8161 \
    ACTIVEMQ_JMX=11099 \
    SHA512_VAL=999928176e57b0805e8a53834e7f4eb648baf271a0c60de31ebd95fa63f2b089aa41c2ef7353790835e2e8cc39c4b778f535b38e6dc0c67a79c3c1da335c4a0a

RUN set -x && \
    apt-get update && apt-get upgrade && \
    apt-get install -y --no-install-recommends curl tar procps jq && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/*


RUN curl -L https://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/${ACTIVEMQ}-bin.tar.gz -o ${ACTIVEMQ}-bin.tar.gz && \
    if [ "$SHA512_VAL" != "$(sha512sum ${ACTIVEMQ}-bin.tar.gz | awk '{print($1)}')" ];\
    then \
        echo "sha512 values doesn't match! exiting." \
        exit 1; \
    fi;

RUN tar xzf $ACTIVEMQ-bin.tar.gz -C /opt && \
    rm $ACTIVEMQ-bin.tar.gz && \
    ln -s /opt/$ACTIVEMQ $ACTIVEMQ_HOME && \
    addgroup --system activemq && \
    adduser --system --group activemq && \
    chown -R activemq:activemq /opt/$ACTIVEMQ && \
    chown -h activemq:activemq $ACTIVEMQ_HOME && \
    usermod --home $ACTIVEMQ_HOME activemq && \
    sed -i 's/127.0.0.1/0.0.0.0/g' /${ACTIVEMQ_HOME}/conf/jetty.xml && \
    chmod 400 /${ACTIVEMQ_HOME}/conf/jmx.password

COPY --chown=activemq:activemq env /${ACTIVEMQ_HOME}/bin/
COPY --chown=activemq:activemq activemq.xml /${ACTIVEMQ_HOME}/conf/
COPY --chown=activemq:activemq log4j.properties /${ACTIVEMQ_HOME}/conf/
COPY --chown=activemq:activemq health_check.sh /${ACTIVEMQ_HOME}/bin/

USER activemq

WORKDIR $ACTIVEMQ_HOME
EXPOSE $ACTIVEMQ_TCP $ACTIVEMQ_AMQP $ACTIVEMQ_STOMP $ACTIVEMQ_MQTT $ACTIVEMQ_WS $ACTIVEMQ_UI $ACTIVEMQ_JMX

HEALTHCHECK --interval=1s \
            --start-period=10s \
            CMD ( \
                    curl \
                        --silent \
                        --show-error \
                        "http://localhost:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/healthStatus" \
                    # copy output to fd3 (grep will consume fd1)
                    | tee /dev/fd/3 \
                    | grep --silent 'Good' \
                # show curl output, from fd3
                ) 3>&1

CMD ["/bin/sh", "-c", "/opt/activemq/bin/activemq console"]
