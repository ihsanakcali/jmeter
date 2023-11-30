# Stage 1: Builder Container
FROM redhat/ubi9 as builder

# Install Java, nginx and tar in the builder container using the correct package name
RUN mkdir /tmp/packages && \
    dnf install -y java-17-openjdk-headless tar nginx -y --installroot=/tmp/packages --releasever=/

# Define the JMeter version
ARG JMETER_VERSION=5.6.2

# Create a directory for JMeter installation
RUN mkdir -p /usr/local/apache-jmeter-${JMETER_VERSION}

# Download Apache JMeter from the specified URL and extract it
RUN curl -L -o /tmp/jmeter.tgz https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar xzf /tmp/jmeter.tgz -C /usr/local --strip-components 1 && \
    rm /tmp/jmeter.tgz

# Stage 2: Main Container
FROM redhat/ubi9-micro

# Define the JMeter version in the second stage
ARG JMETER_VERSION

# Copy Java, nginx and tar installation from the builder container to the main container
COPY --from=builder /tmp/packages /

# Update nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Set permissions nginx log directory
RUN chmod -R 770 /var/log/nginx/ /run/

# Copy Apache JMeter from the builder container to the main container
COPY --from=builder /usr/local /usr/local/apache-jmeter-${JMETER_VERSION}

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
