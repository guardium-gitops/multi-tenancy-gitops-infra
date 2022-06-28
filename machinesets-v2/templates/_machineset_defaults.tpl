{{- define "cloud.zones" -}}
  {{- if eq .Values.cloud.name "aws" -}}
    {{ default (list "a" "b" "c") .Values.cloud.zones }}
  {{- end -}}
  {{- if eq $.Values.cloud.name "azure" -}}
    {{ default (list "1" "2" "3") .Values.cloud.zones }}
  {{- end -}}
  {{- if eq $.Values.cloud.name "ibmcloud" -}}
    {{ default (list "1" "2" "3") .Values.cloud.zones }}
  {{- end -}}
  {{- if eq $.Values.cloud.name "vsphere" -}}
    {{ default (list "1") .Values.cloud.zones }}
  {{- end -}}
{{- end -}}


{{- define "cloud.region" -}}
  {{- if ne $.Values.cloud.name "vsphere" -}}
    {{ $region := required "You need to provide the cloud.region of your cluster in your values.yaml file" .Values.cloud.region }}
    {{- $region -}}
  {{- else -}}
    {{ default "none" .Values.cloud.region }}
  {{- end -}}
{{- end -}}

{{- define "machineset.name" -}}
  {{- default "cloudpak" .Values.machineset.name -}}
{{- end -}}


{{- define "machineset.clusterrole" -}}
  {{- default "worker" .Values.machineset.clusterRole -}}
{{- end -}}


{{- define "machineset.clustertype" -}}
  {{- default "worker" .Values.machineset.clusterType -}}
{{- end -}}


{{- define "machineset.replicas" -}}
  {{- default "1" .Values.machineset.nodesPerZone -}}
{{- end -}}

{{/*
Default Node Sizes
{{ $params := dict "Values" .Values "Name" .Name}}
*/}}

{{- define "machineset.nodesize" -}}
  {{- if eq $.Values.cloud.name "aws" -}}
    {{- default "m5.4xlarge" .Values.machineset.instanceType -}}
  {{- end -}}
  {{- if eq $.Values.cloud.name "azure" -}}
    {{- default "Standard_D4s_v3" .Values.machineset.instanceType -}}
  {{- end -}}
  {{- if eq $.Values.cloud.name "ibmcloud" -}}
    {{- default "bx2d-4x16" .Values.machineset.instanceType -}}
  {{- end -}}
{{- end -}}


{{/*
Default Node Volume Type
{{ $params := dict "Values" .Values "Name" .Name}}
*/}}

{{- define "machineset.volumeType" -}}
  {{- if eq $.Values.cloud.name "aws" -}}
    {{- default "gp2" .Values.machineset.volumeType -}}
  {{- end -}}
  {{- if eq $.Values.cloud.name "azure" -}}
    {{- default "Premium_LRS" .Values.machineset.volumeType -}}
  {{- end -}}
{{- end -}}


{{- define "machineset.volumeSize" -}}
  {{- default "128" .Values.machineset.volumeSize -}}
{{- end -}}

{{- define "machineset.clusterRole" -}}
  {{- default "worker" .Values.machineset.clusterRole -}}
{{- end -}}

{{- define "machineset.image" -}}
  {{- $image := required "You need to provide the cloud.image of your AWS cluster in your values.yaml file" $.Values.cloud.aws.ami -}}
  {{ .Values.cloud.aws.ami }}
{{- end -}}

{{- define "machineset.vsphere.defaultNodeCPU" -}}
  {{- default "4" .Values.machineset.numCPUs }}
{{- end -}}

{{- define "machineset.vsphere.NodeCoresPerSocket" -}}
  {{- default "1" .Values.machineset.numCoresPerSocket }}
{{- end -}}

{{- define "machineset.vsphere.defaultNodeMemory" -}}
  {{- default "16384" $.Values.machineset.memoryMiB }}
{{- end -}}

{{- define "machineset.vsphere.folder" -}}
  {{- default $.Values.infrastructureId $.Values.cloud.vsphere.folder -}}
{{- end -}}

{{- define "machineset.azure.resourceGroup" -}}
{{- $resourceGroup := printf "%s-rg" $.Values.infrastructureId -}}
{{ default $resourceGroup $.Values.cloud.azure.resourceGroup }}
{{- end -}}

{{- define "machineset.azure.networkResourceGroup" -}}
{{- $networkResourceGroup := printf "%s-rg" $.Values.infrastructureId -}}
{{ default $networkResourceGroup $.Values.cloud.azure.networkResourceGroup }}
{{- end -}}

{{- define "machineset.azure.workerSubnet" -}}
{{- $workerSubnet := printf "%s-worker-subnet" $.Values.infrastructureId -}}
{{ default $workerSubnet $.Values.cloud.azure.workerSubnet }}
{{- end -}}

{{- define "machineset.azure.virtualNetwork" -}}
{{- $virtualNetwork := printf "%s-vnet" $.Values.infrastructureId -}}
{{ default $virtualNetwork $.Values.cloud.azure.virtualNetwork }}
{{- end -}}

