import os
import json
import subprocess


def main():
    full_cluster_state = json.loads(json.loads(subprocess.check_output([
        'kubectl', '-n', 'kube-system', 'get', 'configmap', 'full-cluster-state', '-o', 'json'
    ]))['data']['full-cluster-state'])
    service_cluster_ip_range = full_cluster_state['desiredState']['rkeConfig']['services']['kubeApi']['serviceClusterIpRange']
    cluster_cidr = full_cluster_state['desiredState']['rkeConfig']['services']['kubeController']['clusterCidr']
    assert cluster_cidr == '10.42.0.0/16'
    assert service_cluster_ip_range == '10.43.0.0/16'
    subprocess.check_call([
        'kubectl', 'apply', '--server-side', '-f', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'calico-tigera-operator.yaml')
    ])
    subprocess.check_call([
        'kubectl', 'apply', '-f', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'calico-custom-resources.yaml')
    ])


if __name__ == '__main__':
    main()
