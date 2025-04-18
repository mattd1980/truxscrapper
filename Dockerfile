# Base image with .NET SDK
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore
COPY *.csproj ./
RUN dotnet restore

# Copy everything and publish
COPY . ./
RUN dotnet publish -c Release -o out

# 🟢 Install Playwright CLI and browser binaries
RUN dotnet tool install --global Microsoft.Playwright.CLI && \
    export PATH="$PATH:/root/.dotnet/tools" && \
    playwright install

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

# Chromium dependencies for Playwright
RUN apt-get update && apt-get install -y \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libxcomposite1 libxrandr2 libxdamage1 libxkbcommon0 libgbm1 \
    libasound2 libxshmfence1 libxfixes3 libxrender1 libxext6 \
    libx11-6 libglib2.0-0 libpango-1.0-0 libharfbuzz0b libfontconfig1 \
    fonts-liberation wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy build output and browser binaries
COPY --from=build /app/out ./
COPY --from=build /root/.cache/ms-playwright /root/.cache/ms-playwright

# Runtime config
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

ENTRYPOINT ["dotnet", "TruxScrapper.dll"]
