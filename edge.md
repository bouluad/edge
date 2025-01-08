# JFrog Edge Installation and Configuration Guide

## Table of Contents

1. **Introduction**
2. **Prerequisites**
3. **Installing JFrog Edge**
4. **Adding the Edge License**
5. **Configuring JFrog Edge**
6. **Smart Remote Repositories**
   - Overview
   - Configuration
   - Management

---

## 1. Introduction

JFrog Edge is a lightweight version of Artifactory designed for edge nodes in distributed setups. It supports essential repository functionalities and is optimized for use cases such as caching and mirroring artifacts closer to users.

---

## 2. Prerequisites

Before installing JFrog Edge, ensure the following:

- A supported operating system (Linux, Windows, or macOS).
- At least 4 GB of RAM and 2 CPUs for basic installations.
- Disk space of at least 10 GB (more for repositories).
- Open ports for HTTP/S (default: 8081 and 443).
- Java 11 or higher installed.
- A JFrog Platform license with an Edge license available.

---

## 3. Installing JFrog Edge

1. **Download the Installer**

   - Navigate to the [JFrog Edge Download Page](https://jfrog.com) and download the appropriate installer for your operating system.

2. **Install the Application**

   - **Linux**:
     ```bash
     wget <url-to-installer>
     chmod +x jfrog-edge-installer.run
     sudo ./jfrog-edge-installer.run
     ```
   - **Windows**:
     - Run the `.exe` installer and follow the GUI instructions.
   - **macOS**:
     - Use the `.dmg` file and follow standard macOS installation procedures.

3. **Start the Service**

   - **Linux/MacOS:**
     ```bash
     sudo systemctl start artifactory
     ```
   - **Windows:**
     - Start the service from the Windows Services Manager or use the batch file provided during installation.

4. **Access the Application**

   - Open a web browser and navigate to `http://<your-server-ip>:8081`.

---

## 4. Adding the Edge License

1. **Log in to the JFrog Platform**

   - Default username: `admin`
   - Default password: `password` (change this upon first login).

2. **Navigate to License Management**

   - Go to `Admin > Licenses`.

3. **Upload the License**

   - Click `Add Licenses`.
   - Paste your Edge license key into the text box or upload the license file.
   - Click `Save`.

4. **Verify the License**

   - Check that the license is active and associated with the Edge instance.

---

## 5. Configuring JFrog Edge

1. **Set Up Base URL**

   - Go to `Admin > General Configuration > HTTP Settings`.
   - Set the Base URL to match your server's public URL.

2. **Create Local Repositories**

   - Navigate to `Admin > Repositories > Local`.
   - Click `New Local Repository` and configure repository type (e.g., Maven, Docker).

3. **Security Configuration**

   - Set up users, groups, and permissions under `Admin > Security`.
   - Integrate with LDAP, SAML, or OAuth as needed.

---

## 6. Smart Remote Repositories

### Overview

Smart Remote Repositories allow JFrog Edge to mirror and cache repositories from a central Artifactory instance. These repositories sync metadata and artifacts in real-time, ensuring up-to-date access at the edge.

### Configuration

1. **Create a Smart Remote Repository**

   - Go to `Admin > Repositories > Remote`.
   - Click `New Remote Repository`.
   - Select the repository type (e.g., Maven, Docker).

2. **Configure Repository Details**

   - Set the URL to the central Artifactory instance (e.g., `https://central.artifactory.example.com/artifactory/<repo>`).
   - Enable `Enable Smart Remote Repository`.
   - Configure credentials for accessing the central instance.

3. **Test Connection**

   - Click `Test` to ensure connectivity.
   - Resolve any firewall or network issues if the test fails.

4. **Save the Repository**

   - Click `Save` and verify the repository appears in the Remote Repositories list.

### Management

1. **Monitor Sync Status**

   - Go to `Admin > Repositories > Remote`.
   - Check the sync status, including:
     - Last synchronization time.
     - Errors during synchronization.

2. **Manage Cached Artifacts**

   - Cached artifacts are stored locally to improve access speed and reduce latency. You can:
     - Navigate to `Admin > Artifacts` to view cached artifacts.
     - Configure cache retention policies to manage storage usage.
     - Manually clear cached artifacts if needed.

3. **Audit Logs**

   - Use `Admin > Logs` to monitor access and sync events. Logs provide insights into repository usage, synchronization performance, and error diagnostics.

---

## Conclusion

This guide provides the steps to install, configure, and manage JFrog Edge and Smart Remote Repositories. By setting up these components effectively, you ensure high availability, optimized artifact delivery, and seamless integration with central Artifactory instances.
