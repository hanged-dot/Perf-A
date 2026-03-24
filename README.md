# Perf-A - Application Performance Analysis with Grafana Assistant

**Project Type:** 3 
**Project Number** 5 
**Year:** 2026  
**Group:** Czw 9:15

## Authors
- Rafał Chrzanowski
- Oktawiusz Doroszuk
- Maria Gajek
- Wojciech Wietrzny

## Contents
- [Perf-A - Application Performance Analysis with Grafana Assistant](#perf-a---application-performance-analysis-with-grafana-assistant)
  - [Authors](#authors)
  - [Contents](#contents)
  - [1. Introduction](#1-introduction)
    - [Architecture Overview](#architecture-overview)
  - [2. Theoretical Background/Technology Stack](#2-theoretical-backgroundtechnology-stack)
    - [Core Technologies](#core-technologies)
      - [Kubernetes (Kind)](#kubernetes-kind)
      - [Prometheus](#prometheus)
      - [Grafana Cloud](#grafana-cloud)
      - [Grafana Assistant](#grafana-assistant)
      - [Grafana Agent](#grafana-agent)
      - [Helm](#helm)
      - [Podman](#podman)
    - [Demo Application](#demo-application)
      - [Google Cloud Microservices Demo](#google-cloud-microservices-demo)
  - [3. Case Study Concept Description](#3-case-study-concept-description)
    - [Application](#application)
    - [Observability](#observability)
    - [Visualization](#visualization)
  - [4. Case Study High Level Architecture](#4-case-study-high-level-architecture)
  - [5. Case Study Detailed Architecture](#5-case-study-detailed-architecture)
    - [Component Interactions](#component-interactions)
    - [Data Flow](#data-flow)
  - [6. Environment Configuration Description](#6-environment-configuration-description)
    - [Prerequisites](#prerequisites)
      - [Required Tools](#required-tools)
      - [System Requirements](#system-requirements)
    - [Configuration Files](#configuration-files)
      - [`.env` File](#env-file)
    - [Grafana Cloud Setup](#grafana-cloud-setup)
      - [Step 1: Create Grafana Cloud Account](#step-1-create-grafana-cloud-account)
      - [Step 2: Create a Stack](#step-2-create-a-stack)
      - [Step 3: Get Prometheus Remote Write Credentials](#step-3-get-prometheus-remote-write-credentials)
      - [Step 4: Create Metrics API Token](#step-4-create-metrics-api-token)
      - [Step 5: Configure `.env` File](#step-5-configure-env-file)
  - [7. Installation Method](#7-installation-method)
    - [Quick Start](#quick-start)
    - [What Gets Installed](#what-gets-installed)
  - [8. Demo Deployment Steps](#8-demo-deployment-steps)
  - [9. Demo Description](#9-demo-description)
  - [10. Summary – Conclusions](#10-summary--conclusions)
  - [11. References](#11-references)
    - [Official Documentation](#official-documentation)
    - [Demo Application](#demo-application-1)
    - [Tutorials and Guides](#tutorials-and-guides)
  - [Quick Reference Commands](#quick-reference-commands)
    - [Cluster Management](#cluster-management)


---

## 1. Introduction

This project demonstrates the use of Grafana Assistant (AI-powered observability tool) to analyze and optimize application performance in a Kubernetes environment. The main objective is to demonstrate the use of Grafana Assistance to manage Grafana configurations and demonstrate application performance as well as the process of identifying application bottlenecks. 

The demo application is a microservices-based platform deployed on a local Kubernetes cluster (Kind), monitored by Prometheus. Metrics are pushed to Grafana Cloud where the Grafana Assistant provides AI-powered analysis and visualization.

### Architecture Overview

This project uses a hybrid cloud-local architecture:
- Local: Kubernetes cluster (KIND) with Prometheus and microservices
- Cloud: Grafana Cloud with AI Assistant for visualization
- Connection: Grafana Agent pushes metrics from local to cloud

---

## 2. Theoretical Background/Technology Stack

### Core Technologies

#### Kubernetes (Kind)
- Purpose: Container orchestration platform
- Why Kind: Lightweight local Kubernetes cluster for development and testing
- Documentation: https://kind.sigs.k8s.io/

#### Prometheus
- Purpose: Metrics collection and time-series database
- Why Prometheus: Easy integration with the microservice architecture
- Documentation: https://prometheus.io/docs/

#### Grafana Cloud
- Purpose: Cloud-based visualization and analytics platform
- Key Features:
  - Dashboard creation and management
  - Alert management
  - Data source integration
  - Grafana Assistant: AI-powered query and dashboard generation
- Why Cloud: Grafana Assistant is a cloud-exclusive feature
- Documentation: https://grafana.com/docs/

#### Grafana Assistant
- Purpose: AI-powered observability assistant
- Availability: Grafana Cloud only (not available in self-hosted Grafana)
- Requirements: 
  - Grafana Cloud account (free tier is enough)
  - Prometheus metrics pushed to cloud
- Documentation: 
  - Get Started: https://grafana.com/docs/grafana-cloud/machine-learning/assistant/get-started/
  - Grafana Cloud: https://grafana.com/docs/grafana-cloud/

#### Grafana Agent
- Purpose: Lightweight metrics collector and forwarder between local and cloud
- Role in Project: Scrapes metrics from local Prometheus and pushes to Grafana Cloud
- Documentation: https://grafana.com/docs/agent/

#### Helm
- Purpose: Kubernetes package manager
- Usage: Deploying Prometheus stack
- Documentation: https://helm.sh/docs/

#### Podman
- Purpose: Container runtime (Docker alternative)
- Why Podman: Rootless containers, better security, no need for Docker Desktop
- Documentation: https://podman.io/

### Demo Application

#### Google Cloud Microservices Demo
- Repository: https://github.com/GoogleCloudPlatform/microservices-demo
- Description: Cloud-native microservices application (Online Boutique)
- Why this demo: Includes load generation and Prometheus metrics

---

## 3. Case Study Concept Description

### Application
Online Boutique is a cloud-first microservices demo application. The application is a web-based e-commerce app where users can browse items, add them to the cart, and purchase them. It generates realistic traffic patterns and metrics suitable for performance analysis.

### Observability
The observability stack consists of:

1. Metrics Collection: Prometheus scrapes metrics from all Kubernetes pods and services locally
2. Data Forwarding: Grafana Agent forwards metrics to Grafana Cloud
3. Data Storage: Time-series data stored in Grafana Cloud Prometheus
4. Visualization: Grafana Cloud dashboards display metrics in real-time
5. AI Analysis: Grafana Assistant provides intelligent insights

Monitored Metrics:
 To be determined

### Visualization

Grafana Cloud provides high range of possibilities for visualization and analysis of metrics. As the main goal is to integrate with the Grafana AI Assistant the visualization is only limited to the Grafana Cloud platform and data available via Prometheus.

---

## 4. Case Study High Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Local Development Machine                  │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Podman Container Runtime                  │ │
│  │                                                        │ │
│  │  ┌────────────────────────────────────────────────────┐│ │
│  │  │         Kind Kubernetes Cluster                    ││ │
│  │  │                                                    ││ │
│  │  │  ┌──────────────────────────────────────────────┐  ││ │
│  │  │  │  Monitoring Namespace                        │  ││ │
│  │  │  │  └─ Prometheus (metrics collection)          │  ││ │
│  │  │  │                                              │  ││ │
│  │  │  └──────────────────────────────────────────────┘  ││ │
│  │  │                                                    ││ │
│  │  │  ┌──────────────────────────────────────────────┐  ││ │
│  │  │  │  Grafana-Agent Namespace                     │  ││ │
│  │  │  │  └─ Grafana Agent (metrics forwarding)       │  ││ │
│  │  │  └──────────────────────────────────────────────┘  ││ │
│  │  │                                                    ││ │
│  │  │  ┌──────────────────────────────────────────────┐  ││ │
│  │  │  │  Perf-A Namespace                            │  ││ │
│  │  │  │  ├─ Frontend Service                         │  ││ │
│  │  │  │  ├─ Product Catalog Service                  │  ││ │
│  │  │  │  ├─ Cart Service                             │  ││ │
│  │  │  │  ├─ Checkout Service                         │  ││ │
│  │  │  │  ├─ Payment Service                          │  ││ │
│  │  │  │  ├─ Email Service                            │  ││ │
│  │  │  │  ├─ Shipping Service                         │  ││ │
│  │  │  │  ├─ Currency Service                         │  ││ │
│  │  │  │  ├─ Recommendation Service                   │  ││ │
│  │  │  │  ├─ Ad Service                               │  ││ │
│  │  │  │  └─ Load Generator                           │  ││ │
│  │  │  └──────────────────────────────────────────────┘  ││ │
│  │  └────────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          ↓ HTTPS (Remote Write)
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                      Grafana Cloud                          │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Prometheus Storage (receives metrics)                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Grafana Interface + AI Assistant                      │ │
│  │  ├─ Dashboards                                         │ │
│  │  ├─ Explore (query interface)                          │ │
│  │  └─ Grafana Assistant (AI-powered)                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                             │
│  Access: https://[yourstack].grafana.net                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Case Study Detailed Architecture

### Component Interactions

```
```


### Data Flow

```
```

---

## 6. Environment Configuration Description

### Prerequisites

#### Required Tools
- Kind (Kubernetes in Docker): v0.20.0+
- kubectl: v1.28.0+
- Helm: v3.12.0+
- Podman: v4.0.0+
- Bash: 4.0+

#### System Requirements
- OS: macOS, Linux, or Windows (WSL2)
- CPU: 4+ cores recommended
- RAM: 8GB minimum, 16GB recommended
- Disk: 20GB free space
- Network: Internet connection required for Grafana Cloud

### Configuration Files

#### `.env` File
Create from `.env.example`:
```bash
cp .env.example .env
```

**Required variables:**

```bash
# Grafana Cloud Prometheus Configuration (Required)
# Get these from: Grafana Cloud → Connections → Hosted Prometheus metrics
# Example: https://prometheus-prod-xx-xxx.grafana.net/api/prom/push
GRAFANA_CLOUD_PROMETHEUS_URL=[REPLACE_PROMETHEUS_REMOTE_WRITE_URL]
GRAFANA_CLOUD_PROMETHEUS_USERNAME=[REPLACE_INSTANCE_ID]
# Create via: Administration → Access Policies → Create access policy with metrics:write scope
GRAFANA_CLOUD_PROMETHEUS_PASSWORD=[REPLACE_METRICS_API_TOKEN]

# Optional: OpenAI API Key (for enhanced AI features)
OPENAI_API_KEY=[REPLACE_OPENAI_API_KEY]
```

> [!CAUTION]
>  Never commit `.env` file to version control!
>  Never change the `.env.example` file!

---

### Grafana Cloud Setup 

Grafana Assistant is a Grafana Cloud exclusive feature. Follow these steps to set up your cloud account:

#### Step 1: Create Grafana Cloud Account

1. Go to: https://grafana.com/auth/sign-up/create-user
2. Sign up for a **free** Grafana Cloud account (or paid if you wish to use this solution more extensively or for a longer period of time)
3. Complete email verification

#### Step 2: Create a Stack

1. After login, you'll be prompted to create a stack
2. Choose a stack name (e.g., "perf-a-monitoring")
3. Select a region closest to you (e.g., EU West, US Central)
4. Select **"Free"** plan (includes Grafana Assistant)
5. Click "Create stack"
6. Wait 1-2 minutes for provisioning

#### Step 3: Get Prometheus Remote Write Credentials

1. In your Grafana Cloud portal, go to: **Connections** → **Add new connection**
2. Search for **"Hosted Prometheus metrics"**
3. Click on it to see your credentials:
   - **Remote Write Endpoint URL**: Copy this (e.g., `https://prometheus-prod-xx-xxx.grafana.net/api/prom/push`)
   - **Username/Instance ID**: Copy this number (e.g., `1234567`)

#### Step 4: Create Metrics API Token

1. Go to: **Administration** → **Access Policies**
2. Click **"Create access policy"**
3. Configure:
   - **Display name**: "metrics-publisher"
   - **Scopes**: Check **"metrics:write"**
4. Click **"Create"**
5. Click **"Add token"**
6. **Copy the token immediately** - you won't see it again!

#### Step 5: Configure `.env` File

Add the credentials to your `.env` file based on the `.env.example`

---

## 7. Installation Method

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/hanged-dot/Perf-A.git
cd Perf-A

# 2. Create environment configuration
cp .env.example .env
# Edit .env and add your Grafana Cloud credentials

# 3. Run setup script
./scripts/setup.sh
```

The setup script will automatically:
- Initialize Podman machine
- Create Kind cluster
- Install Prometheus
- Deploy microservices demo
- Deploy Grafana Agent (if credentials configured)
- Push metrics to Grafana Cloud

### What Gets Installed

**Local Kubernetes Cluster:**
- Prometheus (metrics collection)
- Grafana Agent (metrics forwarding)
- Microservices demo application (11 services)

**Grafana Cloud:**
- Prometheus storage (receives metrics)
- Grafana interface (visualization)
- Grafana Assistant (AI features)

---

## 8. Demo Deployment Steps

## 9. Demo Description

## 10. Summary – Conclusions

## 11. References

### Official Documentation
1. Grafana Assistant: https://grafana.com/docs/grafana-cloud/machine-learning/assistant/
2. Grafana Cloud: https://grafana.com/docs/grafana-cloud/
3. Grafana Agent: https://grafana.com/docs/agent/
4. Prometheus: https://prometheus.io/docs/
5. Grafana: https://grafana.com/docs/grafana/latest/
6. Kubernetes: https://kubernetes.io/docs/
7. Kind: https://kind.sigs.k8s.io/docs/
8. Helm: https://helm.sh/docs/
9. Podman: https://docs.podman.io/

### Demo Application
10. Google Cloud Microservices Demo: https://github.com/GoogleCloudPlatform/microservices-demo

### Tutorials and Guides
11. Prometheus Operator: https://prometheus-operator.dev/
12. Kube-Prometheus-Stack: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
13. PromQL Basics: https://prometheus.io/docs/prometheus/latest/querying/basics/
14. Grafana Cloud Tiers: https://grafana.com/pricing/

---

## Quick Reference Commands

### Cluster Management
```bash
# Start environment (single command!)
./scripts/setup.sh

# Stop environment
./scripts/cleanup.sh

# Check cluster status
kubectl get nodes
kubectl get pods -A

# View logs
kubectl logs -f <pod-name>
kubectl logs -n grafana-agent deployment/grafana-agent -f
```