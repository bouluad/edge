# JFrog Edge Deployment and Configuration

## Overview

JFrog Edge is a lightweight, caching-focused distribution node designed to reduce latency and improve performance for artifact delivery in distributed environments. It acts as a proxy for JFrog Artifactory instances, caching frequently accessed artifacts locally while maintaining synchronization with the central Artifactory.

This guide provides instructions for installing and configuring JFrog Edge using an Ansible role and explains its core functionality, architecture, and use cases.

---

## Key Features

- **Artifact Caching**: Locally stores frequently accessed artifacts to minimize latency.
- **Replication**: Syncs artifacts from the central Artifactory instance to ensure availability.
- **High Availability**: Works seamlessly in multi-datacenter setups for distributed teams.
- **Optimized Bandwidth Usage**: Reduces redundant data transfers by caching artifacts near end-users.
- **Secure Communication**: Supports secure connections using access tokens and SSL.

---

## System Requirements

### 1. Hardware

- **CPU**: Minimum 2 cores  
- **Memory**: Minimum 4GB RAM  
- **Storage**: Adequate space to store cached artifacts (recommended 100GB+)  
- **Network**: Reliable network connectivity to the central Artifactory instance  

### 2. Software

- **Operating System**: Linux (RHEL, CentOS, Ubuntu, or Debian recommended)  
- **Dependencies**: Systemd for service management, Python 3 for Ansible execution  

---

## Deployment with Ansible

### 1. Directory Structure

The repository includes an Ansible role for deploying JFrog Edge. Below is the structure:


### 2. Role Variables

| Variable                     | Description                                | Default Value                   |
|------------------------------|--------------------------------------------|---------------------------------|
| `jfrog_edge_version`         | JFrog Edge version to install             | `7.63.3`                       |
| `jfrog_edge_install_dir`     | Directory for Edge installation           | `/opt/jfrog`                   |
| `jfrog_edge_data_dir`        | Directory for Edge data                   | `/var/opt/jfrog/artifactory`   |
| `jfrog_edge_user`            | System user for running JFrog Edge        | `artifactory`                  |
| `jfrog_edge_group`           | System group for running JFrog Edge       | `artifactory`                  |
| `jfrog_base_url`             | URL of the central Artifactory instance   | `http://your-artifactory-url`  |
| `jfrog_access_token`         | Access token for secure communication     | `your-access-token`            |

---

### 3. Installation Steps

#### Step 1: Install Prerequisites

Install Ansible:
```bash
sudo apt update && sudo apt install -y ansible

Step 2: Clone the Repository
Clone the repository containing the Ansible role:

bash
Copy code
git clone <your-repo-url>
cd <your-repo-folder>
Step 3: Create an Inventory File
Define the servers where JFrog Edge will be installed:

ini
Copy code
[edge_nodes]
edge-node-1 ansible_host=192.168.1.10
edge-node-2 ansible_host=192.168.1.11
Step 4: Run the Ansible Playbook
Execute the playbook to install and configure JFrog Edge:

bash
Copy code
ansible-playbook -i inventory install_jfrog_edge.yml
Post-Deployment Verification
Step 1: Service Status
Ensure the JFrog Edge service is running:

bash
Copy code
systemctl status artifactory
Step 2: Access Logs
Check logs for any errors or status updates:

bash
Copy code
tail -f /var/opt/jfrog/artifactory/logs/artifactory.log
Step 3: Web UI
Access JFrog Edge through the browser:

arduino
Copy code
http://<edge-node-ip>:8082
Architecture
1. Key Components
Central Artifactory
The main instance where artifacts are stored and managed.

Edge Nodes
Nodes deployed in regional datacenters to cache and serve artifacts.

Replication
Mechanism to synchronize selected repositories between the central instance and Edge nodes.

2. Workflow
A user requests an artifact from a JFrog Edge node.
The Edge node checks its local cache:
If the artifact exists, it serves it immediately.
If not, it fetches the artifact from the central Artifactory instance, caches it locally, and serves it to the user.
Subsequent requests for the same artifact are served from the cache.
Use Cases
1. Multi-Datacenter Environments
Reduce latency for geographically distributed teams by deploying Edge nodes closer to them.

2. Bandwidth Optimization
Avoid redundant transfers by caching frequently accessed artifacts.

3. Disaster Recovery
Maintain availability of artifacts even if the central Artifactory instance experiences downtime.

Testing Performance
1. Baseline (Without Edge)
Measure artifact download times directly from the central Artifactory instance.

2. With Edge
Measure artifact download times through Edge nodes.

3. Tools
Use curl, wget, or the provided Python script to test and compare latency, download times, and cache performance.

Troubleshooting
Issue	Possible Cause	Solution
Service not starting	Incorrect configuration or missing files	Check logs in /var/opt/jfrog/artifactory/logs/
Artifacts not syncing to Edge	Misconfigured replication settings	Verify Artifactory replication settings
Slow performance	Insufficient hardware resources	Increase RAM/CPU for Edge nodes
Access denied errors	Invalid access token or permissions	Update the jfrog_access_token variable
Resources
JFrog Artifactory Documentation
JFrog Artifactory Edge Overview
Ansible Documentation
