# escape=`
FROM openjdk:8-jdk-nanoserver
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Elasticsearch
ENV ES_VERSION="5.2.0" `
    ES_SHA1="243cce802055a06e810fc1939d9f8b22ee68d227" `
    ES_HOME="c:\elasticsearch"

RUN Invoke-WebRequest -outfile elasticsearch.zip "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$($env:ES_VERSION).zip" -UseBasicParsing; `
    if ((Get-FileHash elasticsearch.zip -Algorithm sha1).Hash -ne $env:ES_SHA1) {exit 1} ; `
    Expand-Archive elasticsearch.zip -DestinationPath C:\ ; `
    Move-Item c:/elasticsearch-$($env:ES_VERSION) 'c:\elasticsearch'; `
    Remove-Item elasticsearch.zip

VOLUME c:/data

# REMARKS - DNS and mount tweaks needed for Windows
RUN Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord; `
    Set-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices' -Name 'G:' -Value '\??\C:\data' -Type String    

EXPOSE 9200 9300
WORKDIR c:/elasticsearch
COPY config ./config

SHELL ["cmd", "/S", "/C"]
CMD ".\bin\elasticsearch.bat"