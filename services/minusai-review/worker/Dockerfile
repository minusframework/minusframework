FROM mcr.microsoft.com/windows/servercore:ltsc2022
WORKDIR /app
COPY MinusAI_Reviewer.exe .
COPY run.ps1 .
CMD ["powershell", "-File", "run.ps1"]
