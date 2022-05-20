{{/*
MachineSet Header
{{ $params := dict "Values" .Values "Name" .Name "Zone" "{{ . }}"}}
*/}}


{{- define "machineset.header" -}}
{{- $infraid := required "Missing infrastructureID in your values.yaml file" .Values.infrastructureId -}}
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
    helm.sh/hook-weight: "0"
  labels:
    machine.openshift.io/cluster-api-cluster: {{ .Values.infrastructureId }}
    machine.openshift.io/cluster-api-machine-role: {{ include "machineset.clusterrole" . }}
    machine.openshift.io/cluster-api-machine-type: {{ include "machineset.clustertype" . }}
  name: {{ .Values.infrastructureId }}-{{ include "machineset.name" . }}-{{ include "cloud.region" . }}{{ $.Zone }}
  namespace: openshift-machine-api
spec:
  replicas: {{ include "machineset.replicas" . }}
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: {{ .Values.infrastructureId }}
      machine.openshift.io/cluster-api-machineset: {{ .Values.infrastructureId }}-{{ include "machineset.name" . }}-{{ include "cloud.region" . }}{{ $.Zone }}
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: {{ .Values.infrastructureId }}
        machine.openshift.io/cluster-api-machine-role: {{ include "machineset.clusterrole" . }}
        machine.openshift.io/cluster-api-machine-type: {{ include "machineset.clustertype" . }}
        machine.openshift.io/cluster-api-machineset: {{ .Values.infrastructureId }}-{{ include "machineset.name" . }}-{{ include "cloud.region" . }}{{ $.Zone }}
    spec:
      {{- if .Values.machineset.taints }}
      taints:
      {{- toYaml .Values.machineset.taints | nindent 6 -}}
      {{- end -}}
      {{- if .Values.machineset.labels }}
      metadata:
        labels:
        {{- toYaml .Values.machineset.labels | nindent 10 -}}
      {{- end -}}
{{- end -}}

{{/*
MachineSet ProviderSpec
{{ $params := dict "Values" .Values "Name" .Name "Zone" .Zone}}
*/}}

{{- define "machineset.providerspec" -}}
{{- $params := dict "Values" .Values "Name" .Name "Zone" .Zone -}}
{{- if eq .Values.cloud.name "azure" -}}
{{- include "machineset.providerspec.azure" $params -}}
{{- end -}}
{{- if eq .Values.cloud.name "aws" -}}
{{- include "machineset.providerspec.aws" $params -}}
{{- end -}}
{{- if eq .Values.cloud.name "ibmcloud" -}}
{{- include "machineset.providerspec.ibmcloud" $params -}}
{{- end -}}
{{- if eq .Values.cloud.name "vsphere" -}}
{{- include "machineset.providerspec.vsphere" $params -}}
{{- end -}}
{{- end -}}



{{/*
MachineSet ProviderSpecs
{{ $params := dict "Values" .Values "Name" .Name "Zone" .Zone"}}
*/}}

{{- define "machineset.providerspec.azure" -}}
{{- $params := dict "Values" .Values "Name" .Name -}}
providerSpec:
  value:
    apiVersion: azureproviderconfig.openshift.io/v1beta1
    kind: AzureMachineProviderSpec
    credentialsSecret:
      name: azure-cloud-credentials
      namespace: openshift-machine-api
    image:
      offer: ""
      publisher: ""
      resourceID: /resourceGroups/{{ include "machineset.azure.resourceGroup" $params }}/providers/Microsoft.Compute/images/{{ .Values.infrastructureId }}
      sku: ""
      version: ""
    location: {{ include "cloud.region" .}}
    managedIdentity: {{ .Values.infrastructureId }}-identity
    metadata:
      creationTimestamp: null
    networkResourceGroup: {{ include "machineset.azure.networkResourceGroup" $params}}
    osDisk:
      diskSizeGB: {{ include "machineset.volumeSize" $params }}
      managedDisk:
        storageAccountType: {{ include "machineset.volumeType" $params }}
      osType: Linux
    publicIP: false
    publicLoadBalancer: {{ .Values.infrastructureId }}
    resourceGroup: {{ include "machineset.azure.resourceGroup" $params }}
    subnet: {{ include "machineset.azure.workerSubnet" $params }}
    userDataSecret:
      name: worker-user-data
    vmSize: {{ include "machineset.nodesize" $params }}
    vnet: {{ include "machineset.azure.virtualNetwork" $params }}
    zone: {{ .Zone | quote }}
{{- end -}}


{{- define "machineset.providerspec.aws" -}}
{{- $params := dict "Values" .Values "Name" .Name -}}
providerSpec:
  value:
    apiVersion: awsprovider.openshift.io/v1beta1
    credentialsSecret:
      name: aws-cloud-credentials
    kind: AWSMachineProviderSpec
    userDataSecret:
      name: worker-user-data
    placement:
      availabilityZone: {{ include "cloud.region" . }}{{ .Zone }}
      region: {{ include "cloud.region" . }}
    instanceType: {{ include "machineset.nodesize" $params }}
    blockDevices:
    - ebs:
        iops: 0
        volumeSize: {{ include "machineset.volumeSize" $params }}
        volumeType: {{ include "machineset.volumeType" $params }}
    ami:
      id: {{ include "machineset.image" . }}
    subnet:
      filters:
      - name: tag:Name
        values:
        - {{ .Values.infrastructureId }}-private-{{ include "cloud.region" . }}{{ .Zone }}
    iamInstanceProfile:
      id: {{ .Values.infrastructureId }}-worker-profile
    securityGroups:
    - filters:
      - name: tag:Name
        values:
        - {{ .Values.infrastructureId }}-worker-sg
    tags:
    - name: kubernetes.io/cluster/{{ .Values.infrastructureId }}
      value: owned
{{- end -}}

{{- define "machineset.providerspec.vsphere" -}}
{{- $networkName := required "Missing vsphere.networkName in your values.yaml file" .Values.vsphere.networkName -}}
{{- $datacenter := required "Missing vsphere.datacenter in your values.yaml file" .Values.vsphere.datacenter -}}
{{- $datastore := required "Missing vsphere.datastore in your values.yaml file" .Values.vsphere.datastore -}}
{{- $cluster := required "Missing vsphere.cluster in your values.yaml file" .Values.vsphere.cluster -}}
{{- $server := required "Missing vsphere.server in your values.yaml file" .Values.vsphere.server -}}
providerSpec:
  value:
    apiVersion: vsphereprovider.openshift.io/v1beta1
    credentialsSecret:
      name: vsphere-cloud-credentials
    diskGiB: {{ include "machineset.vsphere.defaultNodeDiskSize" . }}
    kind: VSphereMachineProviderSpec
    memoryMiB: {{ include "machineset.vsphere.defaultNodeMemory" . }}
    metadata:
      creationTimestamp: null
    network:
      devices:
      - networkName: {{ $networkName }}
    numCPUs: {{ include "machineset.vsphere.defaultNodeCPU" . }}
    numCoresPerSocket: {{ include "machineset.vsphere.NodeCoresPerSocket" .}}
    snapshot: ""
    template: {{ .Values.infrastructureId }}-rhcos
    userDataSecret:
      name: worker-user-data
    workspace:
      datacenter: {{ $datacenter }}
      datastore: {{ .Values.vsphere.datastore }}
      folder: /{{ .Values.vsphere.datacenter }}/vm/{{ .Values.infrastructureId }}
      resourcePool: /{{ .Values.vsphere.datacenter }}/host/{{ .Values.vsphere.cluster }}/Resources
      server: {{ .Values.vsphere.server }}
{{- end -}}

{{- define "machineset.providerspec.ibmcloud" -}}
{{- $params := dict "Values" .Values "Name" .Name -}}
providerSpec:
  value:
    apiVersion: ibmcloudproviderconfig.openshift.io/v1beta1
    credentialsSecret:
      name: ibmcloud-credentials
    image: {{ .Values.infrastructureId }}-rhcos
    kind: IBMCloudMachineProviderSpec
    metadata:
      creationTimestamp: null
    primaryNetworkInterface:
      securityGroups:
      - {{ .Values.infrastructureId }}-sg-cluster-wide
      - {{ .Values.infrastructureId }}-sg-openshift-net
      subnet: {{ .Values.infrastructureId }}-subnet-compute-{{ include "cloud.region" . }}-{{ .Zone }}
    profile: {{ include "machineset.nodesize" $params }}
    region: {{ include "cloud.region" . }}
    resourceGroup: {{ .Values.infrastructureId }}
    userDataSecret:
      name: worker-user-data
    vpc: {{ .Values.infrastructureId }}-vpc
    zone: {{ include "cloud.region" . }}-{{ .Zone }}
{{- end -}}