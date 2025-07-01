FROM mcr.microsoft.com/windows/nanoserver:10.0.14393.1066 AS builder
LABEL maintainer="Cloud Software Group, Inc."
WORKDIR C:/app
COPY . .

ARG EXCLUDE_GOVERNANCE=true
ARG EXCLUDE_CONFIG_MANAGEMENT=true
ARG EXCLUDE_JDBC=true

RUN powershell.exe -File C:/app/scripts/customize-runtime.ps1

# Final stage
FROM mcr.microsoft.com/windows/nanoserver:10.0.14393.1066 AS final
LABEL maintainer="Cloud Software Group, Inc."
COPY --from=builder C:/app/resources C:/resources
COPY --from=builder C:/app/scripts C:/scripts
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["powershell.exe", "C:/scripts/start.ps1"]
