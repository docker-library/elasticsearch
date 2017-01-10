# escape=`
FROM microsoft/nanoserver
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# OpenJDK - this can go when we have an official Windows OpenJDK image - see https://github.com/docker-library/openjdk/pull/88
ENV JAVA_VERSION="1.8.0.111-3" `
    JAVA_ZIP_VERSION="1.8.0-openjdk-1.8.0.111-3.b15" `
    JAVA_SHA256="e080371bf57536668416157660e05d95fe04db15da36234d32bda8e301bb0454" `    
    JAVA_HOME="C:\openjdk"

RUN Invoke-WebRequest $('https://github.com/ojdkbuild/ojdkbuild/releases/download/{0}/java-{1}.ojdkbuild.windows.x86_64.zip' -f $env:JAVA_VERSION, $env:JAVA_ZIP_VERSION) -OutFile 'openjdk.zip' -UseBasicParsing ; `
    if ((Get-FileHash openjdk.zip -Algorithm sha256).Hash -ne $env:JAVA_SHA256) {exit 1} ; `
    Expand-Archive openjdk.zip -DestinationPath C:\ ; `
    mv "C:\java-$($env:JAVA_ZIP_VERSION).ojdkbuild.windows.x86_64" 'c:\openjdk'; `
    Remove-Item -Path openjdk.zip

# Elasticsearch
ENV ES_VERSION="5.1.1" `
    ES_SHA1="d4b966c19c85dd2cb9a5b9750193f82f49e63717" `
    ES_HOME="c:\elasticsearch"

RUN Invoke-WebRequest -outfile elasticsearch.zip "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$($env:ES_VERSION).zip" -UseBasicParsing; `
    if ((Get-FileHash elasticsearch.zip -Algorithm sha1).Hash -ne $env:ES_SHA1) {exit 1} ; `
    Expand-Archive elasticsearch.zip -DestinationPath C:\ ; `
    Move-Item "c:/elasticsearch-$($env:ES_VERSION)" 'c:\elasticsearch'; `
    Remove-Item elasticsearch.zip

VOLUME c:/data

# REMARKS - DNS and mount tweaks needed for Windows
RUN Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord; `
    Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices' -Name 'G:' -Value '\??\C:\data' -Type String    

EXPOSE 9200 9300
WORKDIR c:/elasticsearch
COPY config ./config

CMD ".\bin\elasticsearch.bat"