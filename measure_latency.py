import requests
import time
import json
import argparse

# Disable SSL warnings for self-signed certificates
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def measure_latency_and_download(url, output_file, auth=None):
    """
    Measures latency and download speed for an artifact.

    Parameters:
        url (str): The artifact URL.
        output_file (str): Local file to save the downloaded artifact.
        auth (tuple): Optional (username, password) for authentication.

    Returns:
        dict: Latency and download speed metrics.
    """
    # Measure latency
    start_time = time.time()
    try:
        response = requests.head(url, auth=auth, verify=False)
        latency = time.time() - start_time
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Error measuring latency: {e}")
        return {"error": str(e)}

    # Measure download time
    start_time = time.time()
    try:
        response = requests.get(url, stream=True, auth=auth, verify=False)
        response.raise_for_status()
        with open(output_file, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        download_time = time.time() - start_time
        file_size = len(response.content) / (1024 * 1024)  # Size in MB
    except requests.RequestException as e:
        print(f"Error downloading artifact: {e}")
        return {"error": str(e)}

    return {
        "latency": latency,
        "download_time": download_time,
        "file_size_MB": file_size,
        "download_speed_MBps": file_size / download_time
    }


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Measure latency and download times for an artifact.")
    parser.add_argument("--artifact_url", required=True, help="URL of the artifact to test.")
    parser.add_argument("--output_file", default="artifact.tmp", help="Temporary file for downloaded artifact.")
    parser.add_argument("--auth", nargs=2, metavar=("USERNAME", "PASSWORD"), help="Optional authentication credentials.")
    parser.add_argument("--results_file", default="results.json", help="JSON file to save results.")
    args = parser.parse_args()

    # Measure latency and download time
    print(f"Testing download for artifact: {args.artifact_url}")
    metrics = measure_latency_and_download(
        args.artifact_url,
        args.output_file,
        auth=tuple(args.auth) if args.auth else None
    )

    # Save results to a JSON file
    results = {"artifact_url": args.artifact_url, "metrics": metrics}
    with open(args.results_file, 'w') as f:
        json.dump(results, f, indent=4)
    print(f"Results saved to {args.results_file}")


if __name__ == "__main__":
    main()
