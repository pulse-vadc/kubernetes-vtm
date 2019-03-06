{{- /*
# Copyright 2019 Pulse Secure, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
*/ -}}
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "vtm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vtm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vtm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get protocol for virtual server type
*/}}
{{- define "vtm.vs.protocol" -}}
{{- $p := lower . | trim -}}
{{- if eq $p "http" -}}TCP
{{- else if eq $p "ftp" -}}TCP
{{- else if eq $p "imapv2" -}}TCP
{{- else if eq $p "imapv3" -}}TCP
{{- else if eq $p "imapv4" -}}TCP
{{- else if eq $p "pop3" -}}TCP
{{- else if eq $p "smtp" -}}TCP
{{- else if eq $p "ldap" -}}TCP
{{- else if eq $p "telnet" -}}TCP
{{- else if eq $p "ssl" -}}TCP
{{- else if eq $p "https" -}}TCP
{{- else if eq $p "imaps" -}}TCP
{{- else if eq $p "pop3s" -}}TCP
{{- else if eq $p "ldaps" -}}TCP
{{- else if eq $p "udpstreaming" -}}UDP
{{- else if eq $p "udp" -}}UDP
{{- else if eq $p "dns" -}}UDP
{{- else if eq $p "dns_tcp" -}}TCP
{{- else if eq $p "sipudp" -}}UDP
{{- else if eq $p "siptcp" -}}TCP
{{- else if eq $p "rtsp" -}}TCP
{{- else if eq $p "server_first" -}}TCP
{{- else if eq $p "client_first" -}}TCP
{{- else if eq $p "stream" -}}TCP
{{- else -}}TCP
{{- end -}}
{{- end -}}
