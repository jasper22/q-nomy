# Build Angular
FROM docker.local:5000/node:14.2.0 as build_angular
WORKDIR /client
COPY src/client/package.json .
RUN npm install
COPY src/client/ .
ARG configuration=production
RUN npm run build -- --configuration=${configuration} --outputPath=./dist/out --deleteOutputPath=true --extractCss=true --aot=true --buildOptimizer=true

# Build .NET
FROM docker.local:5000/mcr.microsoft.com/dotnet/core/sdk:3.1-alpine as build_dotnet
WORKDIR /app
COPY src/server/QNomy.csproj /app/
RUN dotnet restore
COPY src/server/ .
ARG configuration=Release
RUN dotnet publish                              \
            --configuration ${configuration}    \
            --nologo                            \
            --no-restore                        \
            --output ./dist/out                 \
            ./QNomy.csproj


# Prepare SQL Server 2019
FROM docker.local:5000/mcr.microsoft.com/mssql/server:2019-CU4-ubuntu-16.04

# SQL Settins
ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=Password1
ENV MSSQL_SA_PASSWORD=Password1
ENV MSSQL_PID=Express

USER root

# Install .NET Core SDK + Nginx
RUN apt-get update && apt-get install -y apt-transport-https && apt-get -y install dotnet-sdk-3.1 && apt-get install -y nginx

# Configure Angular + Nginx
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build_angular /client/dist/out/ /usr/share/nginx/html
COPY src/client/ngnix-custom-2.conf /etc/nginx/nginx.conf

# Configure WebAPI project
WORKDIR /app
COPY --from=build_dotnet /app/dist/out/ .
# ENV ASPNETCORE_URLS http://+:5000;https://+:5001
ENV ASPNETCORE_URLS http://+:5000
ENV DATABASE_SERVER localhost

CMD /opt/mssql/bin/sqlservr & service nginx start && dotnet QNomy.dll 

EXPOSE 1433