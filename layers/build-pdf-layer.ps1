# Install PDF processing libraries
Set-Location "pdf-processing"
python -m pip install -r requirements.txt -t python/
New-Item -ItemType Directory -Path "../build" -Force
Compress-Archive -Path python -DestinationPath "../build/pdf-layer.zip" -Force
Write-Host "PDF layer built: layers/build/pdf-layer.zip"
Set-Location ".."