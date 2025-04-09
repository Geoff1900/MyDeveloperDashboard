# Use the .NET SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Configure ZScaler certs
WORKDIR /usr/local/share/ca-certificates
COPY ["Zscaler Intermediate Root CA (zscloud.net) (t)_.crt", "Zscaler.crt"]
RUN chmod 644 Zscaler.crt

RUN /usr/sbin/update-ca-certificates

# Install root certs so HTTPS works (needed for NuGet restore)
#RUN apt-get update && apt-get install -y ca-certificates
WORKDIR /MyDeveloperDashboard

# Copy solution and project files first to leverage Docker cache
COPY *.sln ./
COPY src/MyDeveloperDashboard.Web/*.csproj ./src/MyDeveloperDashboard.Web/

RUN curl https://api.nuget.org/v3/index.json
# Restore the project dependencies
RUN dotnet restore 

# Copy the rest of the source code
COPY /src/. ./src/

# Set working directory to the project folder and publish the app
WORKDIR /MyDeveloperDashboard/src/MyDeveloperDashboard.Web
RUN dotnet publish -c release -o /app --no-restore

# Final stage: runtime image with minimal dependencies
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

# Copy the published app from the build stage
COPY --from=build /app ./

# Run the app using the correct DLL name (adjust to your actual name)
ENTRYPOINT ["dotnet", "MyDeveloperDashboard.Web.dll"]
