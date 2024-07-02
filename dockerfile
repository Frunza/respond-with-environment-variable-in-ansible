FROM alpine:3.18.0

RUN apk update

# Setup Python
RUN apk add --no-cache python3=3.11.8-r0 && python3 -m ensurepip && pip3 install --no-cache --upgrade pip setuptools
# Install pexpect, which is needed by ansible 'expect' module
RUN pip3 install pexpect

# Define the environment variable
ARG SSH_PRIVATE_KEY
# Create the .ssh directory if it doesn't exist
RUN mkdir -p /root/.ssh
# Write the private key content to id_rsa file
RUN echo "$SSH_PRIVATE_KEY" | tr -d '\r' > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

# Install ansible
RUN apk --no-cache add ansible=7.5.0-r0
# Install the community.general collection
RUN ansible-galaxy collection install community.general

# Copy scripts to the expected location
COPY ./scripts /app
# Copy ansible to the expected location
COPY ./ansible /app/ansible

CMD ["sh"]