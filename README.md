# Respond with environment value in Ansible

## Motivation

when working with `Ansible` there might come a time where you have to respond to some commands with a password. This can easily happen if one of those commands uses a password-protected SSH key.

Assuming that you have a main script that prepares a docker container to do the workload, how do you tell `Ansible` to execute some commands and answer with a secret that is not hardcoded?

Note: ansible needs SSH access to the target machine. You can find out how to configure SSH access in the docker container at [https://github.com/Frunza/configure-docker-container-with-ssh-access](https://github.com/Frunza/configure-docker-container-with-ssh-access)

## Prerequisites

A Linux or MacOS machine for local development. If you are running Windows, you first need to set up the *Windows Subsystem for Linux (WSL)* environment.

You need `docker cli` and `docker-compose` on your machine for testing purposes, and/or on the machines that run your pipeline.
You can check both of these by running the following commands:
```sh
docker --version
docker-compose --version
```

Make sure that you already have a docker container with SSH access.

Prepare an environemt variable to to hold the value of the response:
- RESPONSE

## Implementation

For `Ansible` to be able to respond when some commands are called, a collection has to be installed. A good place to do this is in the *dockerfile*:
```sh
RUN ansible-galaxy collection install community.general
```
This collection also requires an extra `python` module. You can add it to your *dockerfile* with the following command:
```sh
RUN pip3 install pexpect
```

To pass the `RESPONSE` environment variable to the docker container, add:
```sh
environment:
    - RESPONSE=${RESPONSE}
```
to your `docker-compose` file.

For testing purposes, we can just have `Ansible` ask a question, and respond with the value of the `RESPONSE` environment variable. Add the following task to your `Ansible` playbook:
```sh
- name: Ask for password and respond
      expect:
        command: /bin/sh -c 'read -p "What is the password? " password; echo $password'
        responses:
          (?i).*What is the password?.*: "{{ lookup('env', 'RESPONSE') }}"
      register: passwordResponse
```

You can also add a second task to figure out what happened by using:
```sh
    - name: Print command output
      debug:
        msg: "{{ passwordResponse.stdout }}"
```

## Usage

Navigate to the root of the git repository and run the following command:
```sh
sh run.sh 
```

The following happens:
1) the first command builds the docker image, passing the private key value as an argument and tagging it as *respondansible*
2) the docker image sets up the SSH access by copying the value of the `SSH_PRIVATE_KEY` argument to the standard location for SSH keys
3) the second command uses docker-compose to create the container with the `RESPONSE` environment variable set up and run the container. The container runs the `master.yml` ansible playbook, which asks a question, responds to it and prints the output.

Note: if you want to test this, consider changing the `hosts` in the `Ansible` playbook to `local`.
