#Changed from https://github.com/nanoserver/IIS-PHP-MYSQL/blob/master/Dockerfile/Dockerfile

FROM microsoft/windowsservercore:latest

ENV MYSQL_ROOT_PASSWORD="root" \
  MYSQL_ROOT_HOST="%" \
  MYSQL_DATABASE="" \
  MYSQL_USER="" \
  MYSQL_PASSWORD="" \
  MYSQL_ALLOW_EMPTY_PASSWORD="no" \
  MYSQL_RANDOM_ROOT_PASSWORD="no" \
  MYSQL_ONETIME_PASSWORD="no" \
  DOCKER_NEW_RUN="no"

RUN mkdir docker-entrypoint-initdb.d

# Download Links:
ARG mysql_download_url="https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.21-winx64.zip"
# To fetch the direct download link for vcredist:
# First go to https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads
# Follow the desired links until the download starts (you may cancel it). The current page will be something like this:
# "https://www.microsoft.com/en-us/download/confirmation.aspx?id=26999&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1"
# Reload that page and a prompt to re-select the vcredist version will be shown, along with a "click here to download manually" link
# (Also the download will restart. Again, you may cancel it) Copy that link and put it here:
ARG vcredist_x86_download_url="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"

RUN powershell -Command \
  $ErrorActionPreference = 'Stop' ; \
  $ProgressPreference = 'SilentlyContinue' ; \
  Invoke-WebRequest -Uri $env:vcredist_x86_download_url -OutFile c:\vcredist_x86.exe ; \
  Start-Process -FilePath c:\vcredist_x86.exe -ArgumentList '/quiet' -Wait ; \
  Remove-Item c:\vcredist_x86.exe -Force

RUN powershell -Command \
  $ErrorActionPreference = 'Stop' ; \
  $ProgressPreference = 'SilentlyContinue' ; \
  Invoke-WebRequest -Uri $env:mysql_download_url -OutFile c:\mysql.zip ; \
  Expand-Archive -Path 'c:\mysql.zip' -DestinationPath 'c:\' ; \
  Rename-Item -Path 'c:\mysql-5.7.21-winx64' -NewName 'c:\mysql' ; \
  Remove-Item -Path 'c:\mysql.zip' -Force

RUN Setx PATH /M %PATH%;c:\\mysql\\bin & \
  c:\mysql\bin\mysqld.exe --install-manual MySQL

VOLUME c:\\mysql\\data

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY InitializeDatabase.ps1 .
ENTRYPOINT .\\InitializeDatabase.ps1 -Verbose \
  -MYSQL_ROOT_PASSWORD $env:MYSQL_ROOT_PASSWORD \
  -MYSQL_ROOT_HOST $env:MYSQL_ROOT_HOST \
  -MYSQL_DATABASE $env:MYSQL_DATABASE \
  -MYSQL_USER $env:MYSQL_USER \
  -MYSQL_PASSWORD $env:MYSQL_PASSWORD \
  -MYSQL_ALLOW_EMPTY_PASSWORD $env:MYSQL_ALLOW_EMPTY_PASSWORD \
  -MYSQL_RANDOM_ROOT_PASSWORD $env:MYSQL_RANDOM_ROOT_PASSWORD \
  -MYSQL_ONETIME_PASSWORD $env:MYSQL_ONETIME_PASSWORD \
  -DOCKER_NEW_RUN $env:DOCKER_NEW_RUN;

EXPOSE 3306
CMD ["MySQL", "--user=root", "-p"]