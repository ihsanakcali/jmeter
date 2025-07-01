# Stage 1: Builder Container
FROM redhat/ubi10 as builder

RUN dnf install -y unzip

# Install Java, nginx and tar
RUN mkdir /tmp/packages && \
    dnf install -y java-21-openjdk-headless tar curl nginx unzip -y --installroot=/tmp/packages --releasever=/

# Define JMeter version
ARG JMETER_VERSION=5.6.3

# Create install dir
RUN mkdir -p /usr/local/apache-jmeter-${JMETER_VERSION}

# Download and extract JMeter
RUN curl -L -o /tmp/jmeter.tgz https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar xzf /tmp/jmeter.tgz -C /usr/local --strip-components 1 && \
    rm /tmp/jmeter.tgz

# Download and extract JMeter plugins
WORKDIR /tmp/plugins

# Download plugin ZIPs
RUN curl -LO https://jmeter-plugins.org/files/packages/jpgc-casutg-3.1.1.zip && \
    curl -LO https://jmeter-plugins.org/files/packages/jpgc-jmxmon-0.3.zip && \
    curl -LO https://jmeter-plugins.org/files/packages/jpgc-csvars-0.2.zip

# Extract each plugin and copy jars to appropriate JMeter folders
RUN mkdir -p /usr/local/apache-jmeter-${JMETER_VERSION}/lib/ext /usr/local/apache-jmeter-${JMETER_VERSION}/lib && \
    mkdir -p /tmp/plugins/extracted && cd /tmp/plugins && \
    for zip in *.zip; do \
        dirname=$(basename "$zip" .zip); \
        unzip -q "$zip" -d "extracted/$dirname"; \
    done && \
    find extracted -type f -path '*/lib/*.jar' -exec cp -v {} /usr/local/apache-jmeter-${JMETER_VERSION}/lib/ \; && \
    find extracted -type f -path '*/lib/ext/*.jar' -exec cp -v {} /usr/local/apache-jmeter-${JMETER_VERSION}/lib/ext/ \; && \
    rm -rf /tmp/plugins


# Stage 2: Final Container
FROM redhat/ubi10-micro

# Define the JMeter version in the second stage
ARG JMETER_VERSION=5.6.3

# Copy Java, nginx and tar installation from the builder container to the main container
COPY --from=builder /tmp/packages /
COPY --from=builder /usr/local /usr/local/apache-jmeter-${JMETER_VERSION}

# Update nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Set permissions nginx log directory
RUN chmod -R 770 /var/log/nginx/ /run/

# Set the JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/jre

# Set the JMETER_HOME environment variable
ENV JMETER_HOME=/usr/local/apache-jmeter-${JMETER_VERSION}

# Add JMeter's bin directory to the PATH
ENV PATH=$PATH:$JMETER_HOME/bin

# Set permissions to create userPreferences to fix error
RUN mkdir -p /.java/ /temp/ && chmod -R 777 /.java /temp

ADD test.jmx /tmp/test.jmx

USER 1000
# Continue with your main container configuration and commands
