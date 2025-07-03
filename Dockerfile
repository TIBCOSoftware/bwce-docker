FROM mcr.microsoft.com/powershell:nanoserver-ltsc2022 AS builder
LABEL maintainer="Cloud Software Group, Inc."
WORKDIR C:/app
COPY . .

ARG EXCLUDE_GOVERNANCE=false
ARG EXCLUDE_CONFIG_MANAGEMENT=false
ARG EXCLUDE_JDBC=false

RUN pwsh.exe -File C:/app/scripts/customize-runtime.ps1

# Final stage
FROM mcr.microsoft.com/powershell:nanoserver-ltsc2022 AS final
LABEL maintainer="Cloud Software Group, Inc."
COPY --from=builder C:/app/resources C:/resources
COPY --from=builder C:/app/scripts C:/scripts
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["pwsh.exe", "C:/scripts/start.ps1"]
