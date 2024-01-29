{{/*
Expand the name of the chart.
*/}}
{{- define "media-servarr-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "media-servarr-base.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "media-servarr-base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "media-servarr-base.labels" -}}
helm.sh/chart: {{ include "media-servarr-base.chart" . }}
{{ include "media-servarr-base.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "media-servarr-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "media-servarr-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "media-servarr-base.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
  {{- if .Values.serviceAccount.create }}
{{- default (include "media-servarr-base.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- else -}}
default
{{- end }}
{{- end }}

{{/*
Main templator function
Use all default templates and logic
*/}}
{{- define "media-servarr-base.template" -}}
{{ include "media-servarr-base.deployment" . }}
{{ include "media-servarr-base.service" . }}
{{ include "media-servarr-base.configmap" . }}
{{ include "media-servarr-base.secret" . }}
{{ include "media-servarr-base.serviceaccount" . }}
{{ include "media-servarr-base.ingress" . }}
{{- end }}
