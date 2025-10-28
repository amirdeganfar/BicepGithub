# BicepGithub - Azure Service Bus API with Infrastructure as Code

A .NET 8 minimal API that demonstrates Azure Service Bus messaging with automated infrastructure deployment using Azure Bicep and GitHub Actions CI/CD.

## 🚀 Project Overview

This project showcases a complete cloud-native application featuring:

- **ASP.NET Core 8** minimal API for message queue operations
- **Azure Service Bus** for reliable message queuing
- **Azure Bicep** for Infrastructure as Code (IaC)
- **GitHub Actions** for automated CI/CD pipelines
- **Azure App Service** for hosting the API

### What Does This API Do?

The API provides two simple endpoints to interact with an Azure Service Bus queue:

1. **POST /messages** - Send a message to the queue
2. **GET /messages** - Receive and process a message from the queue

## 📋 Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Subscription](https://azure.microsoft.com/free/)
- [Git](https://git-scm.com/downloads)

## 🏗️ Architecture

```
┌─────────────────┐
│  GitHub Actions │
│    CI/CD        │
└────────┬────────┘
         │
         ├─► Infrastructure Deployment (Bicep)
         │   └─► Azure Service Bus Namespace
         │   └─► Azure App Service Plan
         │   └─► Azure Web App
         │
         └─► API Deployment (.NET 8)
             └─► ASP.NET Core Minimal API
```

### Azure Resources Created

- **Service Bus Namespace** (Standard tier)
- **Service Bus Queue** (`work-items`)
- **App Service Plan** (Free tier - F1)
- **Web App** (Linux, .NET 8)

## 🛠️ Local Development & Testing

### 1. Clone the Repository

```bash
git clone <repository-url>
cd BicepGithub
```

### 2. Set Up Azure Service Bus (Local Testing)

Create a Service Bus namespace and queue in Azure for local development:

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-sb-api-dev --location australiaeast

# Create Service Bus namespace
az servicebus namespace create --name <your-unique-namespace> --resource-group rg-sb-api-dev --location australiaeast --sku Standard

# Create queue
az servicebus queue create --name work-items --namespace-name <your-unique-namespace> --resource-group rg-sb-api-dev

# Get connection string
az servicebus namespace authorization-rule keys list --resource-group rg-sb-api-dev --namespace-name <your-unique-namespace> --name RootManageSharedAccessKey --query primaryConnectionString -o tsv
```

### 3. Configure Application Settings

Create or update `BicepGithub/appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ServiceBus": {
    "ConnectionString": "Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=...",
    "QueueName": "work-items"
  }
}
```

### 4. Run the API Locally

```bash
cd BicepGithub
dotnet restore
dotnet run
```

The API will start at `http://localhost:5000` (or the port shown in console).

### 5. Test the API

#### Using Swagger UI

Navigate to `http://localhost:5000/swagger` in your browser to use the interactive API documentation.

#### Using cURL

**Send a message:**
```bash
curl -X POST http://localhost:5000/messages \
  -H "Content-Type: application/json" \
  -d "{\"body\":\"Hello from the queue!\"}"
```

**Receive a message:**
```bash
curl http://localhost:5000/messages
```

#### Using PowerShell

**Send a message:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/messages" -Method Post -ContentType "application/json" -Body '{"body":"Hello from the queue!"}'
```

**Receive a message:**
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/messages" -Method Get
```

#### Using the HTTP file

The project includes `BicepGithub.http` file for testing with JetBrains Rider or VS Code REST Client extension.

## ☁️ Azure Deployment

### Prerequisites for Deployment

1. **Azure Service Principal** with contributor access to your subscription
2. **GitHub Secrets** configured:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

### Deploy Infrastructure

The infrastructure deployment is automated via GitHub Actions:

1. Push changes to the `infra/` directory, or
2. Manually trigger the workflow from GitHub Actions tab

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

Or manually trigger via GitHub UI:
- Go to **Actions** → **Deploy Infra (Bicep)** → **Run workflow**

### Deploy API

The API deployment is automated and triggers when:

1. Code in `BicepGithub/` directory changes
2. Manually triggered from GitHub Actions

```bash
git add .
git commit -m "Update API"
git push origin main
```

## 🧪 Testing the Deployed API

Once deployed, get your API URL from the Azure Portal or GitHub Actions output:

```bash
# Set your API URL
$API_URL = "https://demo1-api.azurewebsites.net"

# Send a message
Invoke-RestMethod -Uri "$API_URL/messages" -Method Post -ContentType "application/json" -Body '{"body":"Hello from Azure!"}'

# Receive a message
Invoke-RestMethod -Uri "$API_URL/messages" -Method Get
```

## 📁 Project Structure

```
BicepGithub/
├── .github/
│   └── workflows/
│       ├── api-cicd.yml          # API CI/CD pipeline
│       └── infra.yml              # Infrastructure deployment
├── BicepGithub/                   # .NET API project
│   ├── Program.cs                 # API endpoints & configuration
│   ├── BicepGithub.csproj        # Project file
│   └── appsettings.json          # Configuration
├── infra/
│   └── main.bicep                # Azure infrastructure definition
├── scripts/                       # Helper scripts (if any)
└── README.md                      # This file
```

## 🔧 Configuration

### Application Settings

The API uses the following configuration:

```json
{
  "ServiceBus": {
    "ConnectionString": "Endpoint=sb://...",
    "QueueName": "work-items"
  }
}
```

Configuration can be provided via:
- `appsettings.json`
- `appsettings.Development.json`
- Environment variables (using `ServiceBus__ConnectionString` format)
- Azure App Service Application Settings (automatically configured by Bicep)

### Bicep Parameters

You can customize the infrastructure deployment by modifying parameters in `.github/workflows/infra.yml`:

```yaml
parameters: >
  location=australiaeast
  namePrefix=demo1
  queueName=work-items
  sku=F1
  sbSku=Standard
```

## 🔍 API Endpoints

### POST /messages

Send a message to the Service Bus queue.

**Request:**
```json
{
  "body": "Your message text"
}
```

**Response:** `202 Accepted`

### GET /messages

Receive and complete a message from the Service Bus queue.

**Response:**
- `200 OK` with message body if a message is available
- `204 No Content` if queue is empty

```json
{
  "body": "Your message text"
}
```

## 🐛 Troubleshooting

### Local Development Issues

**Connection String Error:**
```
Azure.Messaging.ServiceBus.ServiceBusException: The connection string is invalid.
```
- Verify your connection string in `appsettings.Development.json`
- Ensure the Service Bus namespace exists in Azure

**Queue Not Found:**
```
The messaging entity 'work-items' could not be found.
```
- Verify the queue name matches in both Azure and configuration
- Create the queue using Azure CLI or Portal

### Deployment Issues

**Web App Name Already Exists:**
- Modify `namePrefix` parameter in the infrastructure workflow
- Azure Web App names must be globally unique

**Authentication Failed:**
- Verify GitHub secrets are correctly set
- Check that the Service Principal has proper permissions

## 📚 Learn More

- [Azure Service Bus Documentation](https://docs.microsoft.com/azure/service-bus-messaging/)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [ASP.NET Core Minimal APIs](https://docs.microsoft.com/aspnet/core/fundamentals/minimal-apis)
- [GitHub Actions](https://docs.github.com/actions)

## 📝 License

This project is for demonstration and learning purposes.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Happy Coding!** 🎉

