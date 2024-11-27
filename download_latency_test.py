import os
import time
import requests
import socket
import json

# Artifact URL
ARTIFACT_URL = "https://releases.jfrog.io/artifactory/jfrog-artifactory-oss/7.63.3/jfrog-artifactory-oss-7.63.3.zip"
# JSON output file
OUTPUT_FILE = "latency_results.json"

def measure_download(url):
    """Measure latency and download performance for the given URL."""
    results = {}
    try:
        # Start the timer
        start_time = time.time()

        # DNS Resolution
        dns_start = time.time()
        host = socket.gethostbyname(url.split('/')[2])  # Resolve hostname
        dns_end = time.time()

        # Connection Time
        conn_start = time.time()
        response = requests.get(url, stream=True, timeout=10)
        conn_end = time.time()

        # Download Time
        download_start = time.time()
        total_size = 0
        for chunk in response.iter_content(chunk_size=1024 * 1024):  # 1MB chunks
            total_size += len(chunk)
        download_end = time.time()

        # Calculate metrics
        results["dns_resolution_time"] = dns_end - dns_start
        results["connection_time"] = conn_end - conn_start
        results["download_time"] = download_end - download_start
        results["total_time"] = time.time() - start_time
        results["artifact_size_mb"] = round(total_size / (1024 * 1024), 2)
    except Exception as e:
        results["error"] = str(e)

    return results


def run_tests(regions):
    """Run the download test for each region and return the results."""
    results = {}
    for region, url in regions.items():
        print(f"Testing download from {region}...")
        results[region] = measure_download(url)
    return results


if __name__ == "__main__":
    # Define regions and URLs (assuming Edge nodes or primary datacenter URLs for each region)
    regions = {
        "paris_az1": ARTIFACT_URL,  # Example: Primary datacenter in Paris
        "north_france": ARTIFACT_URL,  # Example: Edge in North France
        "canada": ARTIFACT_URL,  # Example: Edge in Canada
        "india": ARTIFACT_URL,  # Example: Edge in India
    }

    # Run tests
    test_results = run_tests(regions)

    # Save results to JSON
    with open(OUTPUT_FILE, "w") as f:
        json.dump(test_results, f, indent=4)

    print(f"Results saved to {OUTPUT_FILE}")
